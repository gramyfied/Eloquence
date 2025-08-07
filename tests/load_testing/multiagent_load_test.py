"""
Tests de charge pour le système multi-agents Eloquence
Valide la scalabilité et la stabilité sous forte charge
"""
import asyncio
import time
import random
from typing import List, Dict, Any
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
import aiohttp
import websockets
import json
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class LoadTestConfig:
    """Configuration pour les tests de charge"""
    base_url: str = "http://localhost:8080"
    ws_url: str = "ws://localhost:7880"
    livekit_url: str = "ws://localhost:7880"
    
    # Paramètres de charge
    concurrent_sessions: int = 20  # Sessions simultanées
    agents_per_session: int = 3     # Agents par session
    session_duration: int = 120     # Durée par session (secondes)
    ramp_up_time: int = 30         # Temps de montée en charge
    
    # Types de simulations à tester
    simulation_types: List[str] = None
    
    def __post_init__(self):
        if self.simulation_types is None:
            self.simulation_types = [
                "tv_debate",
                "journalism",
                "corporate_meeting",
                "hr_interview",
                "sales_pitch"
            ]

@dataclass
class SessionMetrics:
    """Métriques d'une session de test"""
    session_id: str
    simulation_type: str
    start_time: float
    end_time: float = 0
    agents_spawned: int = 0
    messages_sent: int = 0
    messages_received: int = 0
    errors: List[str] = None
    latencies: List[float] = None
    
    def __post_init__(self):
        if self.errors is None:
            self.errors = []
        if self.latencies is None:
            self.latencies = []
    
    @property
    def duration(self) -> float:
        if self.end_time:
            return self.end_time - self.start_time
        return time.time() - self.start_time
    
    @property
    def avg_latency(self) -> float:
        if self.latencies:
            return sum(self.latencies) / len(self.latencies)
        return 0
    
    @property
    def p95_latency(self) -> float:
        if self.latencies:
            sorted_latencies = sorted(self.latencies)
            idx = int(len(sorted_latencies) * 0.95)
            return sorted_latencies[idx]
        return 0

class MultiAgentLoadTester:
    """Testeur de charge pour le système multi-agents"""
    
    def __init__(self, config: LoadTestConfig):
        self.config = config
        self.sessions: Dict[str, SessionMetrics] = {}
        self.global_start_time = 0
        self.global_end_time = 0
        
    async def create_session(self, session_id: str, simulation_type: str) -> SessionMetrics:
        """Crée une nouvelle session de test"""
        metrics = SessionMetrics(
            session_id=session_id,
            simulation_type=simulation_type,
            start_time=time.time()
        )
        self.sessions[session_id] = metrics
        
        try:
            # 1. Créer la room LiveKit
            async with aiohttp.ClientSession() as session:
                response = await session.post(
                    f"{self.config.base_url}/api/multiagent/create-room",
                    json={
                        "simulation_type": simulation_type,
                        "room_name": f"test_{session_id}",
                        "agent_count": self.config.agents_per_session
                    }
                )
                
                if response.status != 200:
                    metrics.errors.append(f"Failed to create room: {response.status}")
                    return metrics
                    
                room_data = await response.json()
                logger.info(f"Created room {room_data['room_name']} for session {session_id}")
                
            # 2. Connecter via WebSocket
            async with websockets.connect(f"{self.config.ws_url}/multiagent/{session_id}") as ws:
                # 3. Spawner les agents
                await ws.send(json.dumps({
                    "type": "spawn_agents",
                    "simulation_type": simulation_type,
                    "count": self.config.agents_per_session
                }))
                
                metrics.agents_spawned = self.config.agents_per_session
                
                # 4. Simuler l'interaction
                start_interaction = time.time()
                interaction_duration = min(self.config.session_duration, 60)
                
                while time.time() - start_interaction < interaction_duration:
                    # Envoyer un message
                    message_start = time.time()
                    await ws.send(json.dumps({
                        "type": "user_message",
                        "content": f"Test message {metrics.messages_sent}",
                        "timestamp": datetime.now().isoformat()
                    }))
                    metrics.messages_sent += 1
                    
                    # Attendre la réponse
                    try:
                        response = await asyncio.wait_for(ws.recv(), timeout=5.0)
                        metrics.messages_received += 1
                        metrics.latencies.append(time.time() - message_start)
                    except asyncio.TimeoutError:
                        metrics.errors.append("Response timeout")
                        
                    # Pause aléatoire entre messages
                    await asyncio.sleep(random.uniform(1, 3))
                    
                # 5. Terminer la session
                await ws.send(json.dumps({
                    "type": "end_session"
                }))
                
        except Exception as e:
            metrics.errors.append(str(e))
            logger.error(f"Session {session_id} error: {e}")
            
        metrics.end_time = time.time()
        return metrics
        
    async def run_concurrent_sessions(self):
        """Lance plusieurs sessions simultanées"""
        self.global_start_time = time.time()
        
        # Créer les tâches de session avec montée en charge progressive
        tasks = []
        for i in range(self.config.concurrent_sessions):
            session_id = f"session_{i}_{int(time.time())}"
            simulation_type = random.choice(self.config.simulation_types)
            
            # Délai de montée en charge
            delay = (i / self.config.concurrent_sessions) * self.config.ramp_up_time
            
            task = self._delayed_session(session_id, simulation_type, delay)
            tasks.append(task)
            
        # Attendre que toutes les sessions se terminent
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        self.global_end_time = time.time()
        
        # Analyser les résultats
        successful_sessions = [r for r in results if isinstance(r, SessionMetrics) and not r.errors]
        failed_sessions = [r for r in results if isinstance(r, SessionMetrics) and r.errors]
        exceptions = [r for r in results if isinstance(r, Exception)]
        
        return {
            "successful": len(successful_sessions),
            "failed": len(failed_sessions),
            "exceptions": len(exceptions),
            "total_duration": self.global_end_time - self.global_start_time
        }
        
    async def _delayed_session(self, session_id: str, simulation_type: str, delay: float):
        """Lance une session après un délai"""
        await asyncio.sleep(delay)
        return await self.create_session(session_id, simulation_type)
        
    def generate_report(self) -> Dict[str, Any]:
        """Génère un rapport de test"""
        if not self.sessions:
            return {"error": "No sessions to report"}
            
        # Calculer les statistiques globales
        all_latencies = []
        total_messages_sent = 0
        total_messages_received = 0
        total_errors = 0
        
        for session in self.sessions.values():
            all_latencies.extend(session.latencies)
            total_messages_sent += session.messages_sent
            total_messages_received += session.messages_received
            total_errors += len(session.errors)
            
        # Calculer les percentiles
        if all_latencies:
            sorted_latencies = sorted(all_latencies)
            p50_idx = int(len(sorted_latencies) * 0.5)
            p95_idx = int(len(sorted_latencies) * 0.95)
            p99_idx = int(len(sorted_latencies) * 0.99)
            
            percentiles = {
                "p50": sorted_latencies[p50_idx],
                "p95": sorted_latencies[p95_idx],
                "p99": sorted_latencies[p99_idx]
            }
        else:
            percentiles = {"p50": 0, "p95": 0, "p99": 0}
            
        # Rapport par type de simulation
        by_simulation = {}
        for session in self.sessions.values():
            if session.simulation_type not in by_simulation:
                by_simulation[session.simulation_type] = {
                    "count": 0,
                    "avg_duration": 0,
                    "avg_latency": 0,
                    "errors": 0
                }
            
            stats = by_simulation[session.simulation_type]
            stats["count"] += 1
            stats["avg_duration"] += session.duration
            stats["avg_latency"] += session.avg_latency
            stats["errors"] += len(session.errors)
            
        # Normaliser les moyennes
        for stats in by_simulation.values():
            if stats["count"] > 0:
                stats["avg_duration"] /= stats["count"]
                stats["avg_latency"] /= stats["count"]
                
        return {
            "summary": {
                "total_sessions": len(self.sessions),
                "total_duration": self.global_end_time - self.global_start_time,
                "total_messages_sent": total_messages_sent,
                "total_messages_received": total_messages_received,
                "total_errors": total_errors,
                "success_rate": (len(self.sessions) - total_errors) / len(self.sessions) * 100
            },
            "latencies": {
                "min": min(all_latencies) if all_latencies else 0,
                "max": max(all_latencies) if all_latencies else 0,
                "avg": sum(all_latencies) / len(all_latencies) if all_latencies else 0,
                **percentiles
            },
            "by_simulation_type": by_simulation,
            "throughput": {
                "messages_per_second": total_messages_sent / (self.global_end_time - self.global_start_time),
                "sessions_per_minute": len(self.sessions) / ((self.global_end_time - self.global_start_time) / 60)
            }
        }

async def run_load_test():
    """Execute le test de charge complet"""
    print("🚀 Démarrage des tests de charge du système multi-agents")
    print("=" * 60)
    
    # Configuration des tests
    config = LoadTestConfig(
        concurrent_sessions=20,
        agents_per_session=3,
        session_duration=120,
        ramp_up_time=30
    )
    
    print(f"Configuration:")
    print(f"  - Sessions simultanées: {config.concurrent_sessions}")
    print(f"  - Agents par session: {config.agents_per_session}")
    print(f"  - Durée par session: {config.session_duration}s")
    print(f"  - Temps de montée en charge: {config.ramp_up_time}s")
    print(f"  - Total d'agents max: {config.concurrent_sessions * config.agents_per_session}")
    print("=" * 60)
    
    # Lancer le test
    tester = MultiAgentLoadTester(config)
    
    print("\n⏳ Exécution des tests en cours...")
    results = await tester.run_concurrent_sessions()
    
    print(f"\n✅ Tests terminés!")
    print(f"  - Sessions réussies: {results['successful']}")
    print(f"  - Sessions échouées: {results['failed']}")
    print(f"  - Exceptions: {results['exceptions']}")
    print(f"  - Durée totale: {results['total_duration']:.2f}s")
    
    # Générer le rapport
    report = tester.generate_report()
    
    print("\n📊 Rapport de performance:")
    print("=" * 60)
    print(f"Résumé:")
    print(f"  - Taux de succès: {report['summary']['success_rate']:.2f}%")
    print(f"  - Messages envoyés: {report['summary']['total_messages_sent']}")
    print(f"  - Messages reçus: {report['summary']['total_messages_received']}")
    print(f"  - Erreurs totales: {report['summary']['total_errors']}")
    
    print(f"\nLatences (secondes):")
    print(f"  - Min: {report['latencies']['min']:.3f}s")
    print(f"  - Moyenne: {report['latencies']['avg']:.3f}s")
    print(f"  - P50: {report['latencies']['p50']:.3f}s")
    print(f"  - P95: {report['latencies']['p95']:.3f}s")
    print(f"  - P99: {report['latencies']['p99']:.3f}s")
    print(f"  - Max: {report['latencies']['max']:.3f}s")
    
    print(f"\nDébit:")
    print(f"  - Messages/seconde: {report['throughput']['messages_per_second']:.2f}")
    print(f"  - Sessions/minute: {report['throughput']['sessions_per_minute']:.2f}")
    
    print(f"\nPar type de simulation:")
    for sim_type, stats in report['by_simulation_type'].items():
        print(f"  {sim_type}:")
        print(f"    - Sessions: {stats['count']}")
        print(f"    - Durée moyenne: {stats['avg_duration']:.2f}s")
        print(f"    - Latence moyenne: {stats['avg_latency']:.3f}s")
        print(f"    - Erreurs: {stats['errors']}")
    
    # Sauvegarder le rapport
    with open(f"load_test_report_{int(time.time())}.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print("\n💾 Rapport sauvegardé dans load_test_report_*.json")
    
    # Validation des critères de performance
    print("\n🎯 Validation des critères de performance:")
    criteria_met = True
    
    if report['latencies']['p95'] > 2.0:
        print("  ❌ P95 latence > 2s (échec)")
        criteria_met = False
    else:
        print("  ✅ P95 latence < 2s")
        
    if report['summary']['success_rate'] < 95:
        print("  ❌ Taux de succès < 95% (échec)")
        criteria_met = False
    else:
        print("  ✅ Taux de succès >= 95%")
        
    if report['throughput']['messages_per_second'] < 10:
        print("  ❌ Débit < 10 msg/s (échec)")
        criteria_met = False
    else:
        print("  ✅ Débit >= 10 msg/s")
        
    if criteria_met:
        print("\n🎉 TOUS LES CRITÈRES DE PERFORMANCE SONT SATISFAITS!")
    else:
        print("\n⚠️ Certains critères de performance ne sont pas satisfaits.")
        
    return criteria_met

if __name__ == "__main__":
    asyncio.run(run_load_test())