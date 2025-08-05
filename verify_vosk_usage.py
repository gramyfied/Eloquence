#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de vérification pour s'assurer que LiveKit utilise bien Vosk STT
"""

import asyncio
import aiohttp
import subprocess
import time
import json
import re
from datetime import datetime
from typing import List, Dict, Optional

class VoskUsageVerifier:
    """Vérificateur d'usage de Vosk dans LiveKit"""
    
    def __init__(self):
        self.vosk_url = "http://localhost:8002"
        self.livekit_agent_container = "livekit-agent"
        
    async def test_vosk_connectivity(self) -> bool:
        """Test la connectivité directe vers Vosk"""
        print("\n[TEST] Connectivité Vosk STT...")
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.vosk_url}/health") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  [+] Vosk accessible: {data}")
                        return True
                    else:
                        print(f"  [X] Vosk non accessible: {response.status}")
                        return False
        except Exception as e:
            print(f"  [X] Erreur connexion Vosk: {e}")
            return False
    
    def check_livekit_logs_for_vosk(self) -> Dict[str, any]:
        """Analyse les logs LiveKit pour détecter l'usage de Vosk"""
        print("\n[ANALYSE] Logs LiveKit Agent...")
        
        try:
            # Récupérer les logs des 5 dernières minutes
            result = subprocess.run([
                "docker", "logs", "--since", "5m", "eloquence-livekit-agent-1"
            ], capture_output=True, text=True)
            
            logs = result.stdout + result.stderr
            
            # Patterns de recherche
            vosk_patterns = [
                r"STT Vosk créé avec succès",
                r"VOSK STT ACTIVÉ AVEC SUCCÈS",
                r"Service Vosk URL",
                r"Vosk en principal"
            ]
            
            openai_patterns = [
                r"OPENAI STT ACTIVÉ",
                r"STT OpenAI créé avec succès",
                r"Basculement vers OpenAI"
            ]
            
            error_patterns = [
                r"ÉCHEC STT Vosk",
                r"Erreur STT",
                r"STT.*failed",
                r"STT.*error"
            ]
            
            # Analyser les logs
            vosk_matches = []
            openai_matches = []
            error_matches = []
            
            for line in logs.split('\n'):
                # Chercher les patterns Vosk
                for pattern in vosk_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        vosk_matches.append(line.strip())
                
                # Chercher les patterns OpenAI
                for pattern in openai_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        openai_matches.append(line.strip())
                
                # Chercher les erreurs
                for pattern in error_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        error_matches.append(line.strip())
            
            return {
                'vosk_usage': vosk_matches,
                'openai_usage': openai_matches,
                'errors': error_matches,
                'total_log_lines': len(logs.split('\n'))
            }
            
        except Exception as e:
            print(f"  [X] Erreur analyse logs: {e}")
            return {'error': str(e)}
    
    def monitor_realtime_usage(self, duration_seconds: int = 60):
        """Surveille l'usage en temps réel"""
        print(f"\n[MONITORING] Surveillance temps réel ({duration_seconds}s)...")
        
        try:
            # Commande pour suivre les logs en temps réel
            cmd = ["docker", "logs", "-f", "eloquence-livekit-agent-1"]
            process = subprocess.Popen(
                cmd, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            start_time = time.time()
            vosk_detections = 0
            openai_detections = 0
            
            print("  [MONITOR] Surveillance active... (Ctrl+C pour arreter)")
            print("  " + "="*50)
            
            while time.time() - start_time < duration_seconds:
                try:
                    line = process.stdout.readline()
                    if line:
                        line = line.strip()
                        
                        # Detecter usage Vosk
                        if any(keyword in line.lower() for keyword in ['vosk', 'stt-trace']):
                            if 'vosk stt active' in line.lower() or 'vosk cree' in line.lower():
                                vosk_detections += 1
                                print(f"  [+] VOSK: {line}")
                        
                        # Detecter usage OpenAI
                        if 'openai stt active' in line.lower() or 'basculement vers openai' in line.lower():
                            openai_detections += 1
                            print(f"  [!] OPENAI: {line}")
                        
                        # Detecter erreurs STT
                        if any(keyword in line.lower() for keyword in ['echec stt', 'erreur stt', 'stt.*failed']):
                            print(f"  [X] ERREUR: {line}")
                
                except KeyboardInterrupt:
                    break
                except:
                    continue
            
            process.terminate()
            
            print("  " + "="*50)
            print(f"  [RESULTATS] Surveillance:")
            print(f"     Detections Vosk: {vosk_detections}")
            print(f"     Detections OpenAI: {openai_detections}")
            
            if vosk_detections > 0:
                print("  [+] Vosk est bien utilise par LiveKit")
            elif openai_detections > 0:
                print("  [!] OpenAI est utilise (fallback active)")
            else:
                print("  [?] Aucune activite STT detectee")
                
        except Exception as e:
            print(f"  [X] Erreur monitoring: {e}")
    
    async def test_livekit_vosk_chain(self) -> bool:
        """Test la chaîne complète LiveKit → Vosk"""
        print("\n[TEST] Chaine complete LiveKit -> Vosk...")
        
        # Vérifier que LiveKit Agent est actif
        try:
            result = subprocess.run([
                "docker", "ps", "--filter", "name=livekit-agent", "--format", "{{.Status}}"
            ], capture_output=True, text=True)
            
            if "Up" not in result.stdout:
                print("  [X] LiveKit Agent n'est pas actif")
                return False
            else:
                print("  [+] LiveKit Agent actif")
        except Exception as e:
            print(f"  ❌ Erreur vérification Agent: {e}")
            return False
        
        # Vérifier la configuration des variables d'environnement
        try:
            result = subprocess.run([
                "docker", "exec", "eloquence-livekit-agent-1", 
                "printenv", "VOSK_SERVICE_URL"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                vosk_url = result.stdout.strip()
                print(f"  [+] Variable VOSK_SERVICE_URL: {vosk_url}")
            else:
                print("  [!] Variable VOSK_SERVICE_URL non definie")
        except Exception as e:
            print(f"  [!] Impossible de verifier les variables: {e}")
        
        return True
    
    def generate_verification_report(self) -> str:
        """Génère un rapport de vérification"""
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        
        report = f"""
=== RAPPORT DE VÉRIFICATION VOSK USAGE ===
Généré le: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

1. CONNECTIVITÉ VOSK
"""
        return report

async def main():
    """Fonction principale de vérification"""
    print("[VERIFICATION] USAGE VOSK DANS LIVEKIT")
    print("=" * 60)
    
    verifier = VoskUsageVerifier()
    
    # Test 1: Connectivité Vosk
    vosk_accessible = await verifier.test_vosk_connectivity()
    
    # Test 2: Chaîne LiveKit → Vosk
    chain_ok = await verifier.test_livekit_vosk_chain()
    
    # Test 3: Analyse des logs historiques
    log_analysis = verifier.check_livekit_logs_for_vosk()
    
    print("\n[RESULTATS] Analyse des logs historiques:")
    if 'error' in log_analysis:
        print(f"  [X] Erreur: {log_analysis['error']}")
    else:
        print(f"  [INFO] Lignes de logs analysees: {log_analysis['total_log_lines']}")
        print(f"  [+] Detections Vosk: {len(log_analysis['vosk_usage'])}")
        print(f"  [!] Detections OpenAI: {len(log_analysis['openai_usage'])}")
        print(f"  [X] Erreurs STT: {len(log_analysis['errors'])}")
        
        if log_analysis['vosk_usage']:
            print("\n  [PREUVES] Usage Vosk:")
            for match in log_analysis['vosk_usage'][:3]:  # Afficher les 3 premiers
                print(f"    {match}")
        
        if log_analysis['openai_usage']:
            print("\n  [FALLBACK] Detections OpenAI:")
            for match in log_analysis['openai_usage'][:3]:
                print(f"    {match}")
        
        if log_analysis['errors']:
            print("\n  [ERREURS] Detectees:")
            for error in log_analysis['errors'][:3]:
                print(f"    {error}")
    
    # Résumé final
    print("\n" + "=" * 60)
    print("[RESUME] VERIFICATION:")
    
    if vosk_accessible and log_analysis.get('vosk_usage'):
        print("[+] Vosk est accessible et utilise par LiveKit")
        status = "OPTIMAL"
    elif vosk_accessible and log_analysis.get('openai_usage'):
        print("[!] Vosk accessible mais OpenAI utilise (verifier config)")
        status = "FALLBACK_ACTIF"
    elif not vosk_accessible:
        print("[X] Vosk non accessible, OpenAI utilise par defaut")
        status = "VOSK_INDISPONIBLE"
    else:
        print("[?] Statut incertain, surveillance recommandee")
        status = "INCERTAIN"
    
    print(f"\nStatut: {status}")
    print("\nPour surveillance temps réel:")
    print("  python verify_vosk_usage.py --monitor")
    
    # Option monitoring temps réel
    import sys
    if "--monitor" in sys.argv:
        verifier.monitor_realtime_usage(120)  # 2 minutes

if __name__ == "__main__":
    asyncio.run(main())