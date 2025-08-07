#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
🌌 DIAGNOSTIC AUTOMATIQUE - EXERCICE COSMIC VOICE
Gestionnaire Réseau Intelligent Eloquence

Vérifie la santé complète de l'exercice Cosmic Voice et fournit
des recommandations de correction automatique.
"""

import asyncio
import aiohttp
import os
import sys
import json
from datetime import datetime
from pathlib import Path

# Configuration des couleurs pour sortie console
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

class CosmicVoiceHealthChecker:
    def __init__(self):
        self.health_score = 0
        self.max_score = 100
        self.issues = []
        self.recommendations = []
        
    def print_header(self):
        """Affiche l'en-tête du diagnostic"""
        print(f"{Colors.CYAN}{Colors.BOLD}")
        print("🌌" * 25)
        print("     DIAGNOSTIC COSMIC VOICE")
        print("   Gestionnaire Réseau Eloquence")
        print("🌌" * 25)
        print(f"{Colors.END}")
        print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
    async def check_environment_variables(self):
        """Vérifie les variables d'environnement requises (30 points)"""
        print(f"\n{Colors.BLUE}🔧 VARIABLES D'ENVIRONNEMENT{Colors.END}")
        print("-" * 40)
        
        required_vars = {
            'LIVEKIT_API_KEY': 'Clé API LiveKit pour streaming audio',
            'LIVEKIT_API_SECRET': 'Secret API LiveKit',
            'LIVEKIT_URL': 'URL du serveur LiveKit',
            'MISTRAL_API_KEY': 'Clé API Mistral pour feedbacks IA',
            'SCALEWAY_MISTRAL_URL': 'URL de l\'API Mistral Scaleway'
        }
        
        missing_vars = []
        present_vars = []
        
        for var, description in required_vars.items():
            value = os.getenv(var)
            if value:
                present_vars.append(var)
                # Masquer les valeurs sensibles
                masked_value = value[:8] + "..." if len(value) > 8 else "***"
                print(f"  ✅ {var}: {masked_value}")
            else:
                missing_vars.append(var)
                print(f"  ❌ {var}: MANQUANTE")
                self.issues.append(f"Variable d'environnement manquante: {var}")
                
        if not missing_vars:
            self.health_score += 30
            print(f"\n{Colors.GREEN}✅ Variables d'environnement: PARFAIT (30/30){Colors.END}")
        else:
            partial_score = int(30 * len(present_vars) / len(required_vars))
            self.health_score += partial_score
            print(f"\n{Colors.YELLOW}⚠️  Variables d'environnement: PARTIEL ({partial_score}/30){Colors.END}")
            
            self.recommendations.append({
                'priority': 'CRITIQUE',
                'action': 'Configurer les variables d\'environnement manquantes',
                'details': f"Ajouter au fichier .env:\n" + 
                          "\n".join([f"{var}=your_{var.lower()}_value" for var in missing_vars])
            })
            
    async def check_backend_services(self):
        """Vérifie les services backend requis (40 points)"""
        print(f"\n{Colors.BLUE}🚀 SERVICES BACKEND{Colors.END}")
        print("-" * 40)
        
        services = [
            {
                'name': 'eloquence-streaming-api',
                'url': 'http://localhost:8002/health',
                'description': 'Service principal WebSocket audio',
                'points': 15
            },
            {
                'name': 'vosk-stt',
                'url': 'http://localhost:2700/health',
                'description': 'Reconnaissance vocale et pitch',
                'points': 10
            },
            {
                'name': 'mistral-conversation',
                'url': 'http://localhost:8004/health',
                'description': 'Feedbacks conversationnels IA',
                'points': 10
            },
            {
                'name': 'redis',
                'url': 'redis://localhost:6379',
                'description': 'Gestion des sessions',
                'points': 5
            }
        ]
        
        for service in services:
            try:
                if service['url'].startswith('redis://'):
                    # Test Redis spécial
                    try:
                        import redis
                        r = redis.Redis.from_url(service['url'])
                        await asyncio.get_event_loop().run_in_executor(None, r.ping)
                        self.health_score += service['points']
                        print(f"  ✅ {service['name']}: DISPONIBLE")
                    except ImportError:
                        print(f"  ⚠️  {service['name']}: Module redis non installé")
                        self.issues.append(f"Module Python 'redis' manquant")
                    except Exception as e:
                        print(f"  ❌ {service['name']}: INDISPONIBLE - {str(e)[:50]}")
                        self.issues.append(f"Service {service['name']} indisponible")
                else:
                    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
                        async with session.get(service['url']) as response:
                            if response.status == 200:
                                self.health_score += service['points']
                                print(f"  ✅ {service['name']}: DISPONIBLE (HTTP {response.status})")
                            else:
                                print(f"  ❌ {service['name']}: ERREUR HTTP {response.status}")
                                self.issues.append(f"Service {service['name']} erreur HTTP {response.status}")
                                
            except asyncio.TimeoutError:
                print(f"  ⏱️  {service['name']}: TIMEOUT (>5s)")
                self.issues.append(f"Service {service['name']} timeout")
            except Exception as e:
                print(f"  ❌ {service['name']}: ÉCHEC - {str(e)[:50]}")
                self.issues.append(f"Service {service['name']} inaccessible: {str(e)[:50]}")
                
        print(f"\n{Colors.GREEN if self.health_score >= 70 else Colors.YELLOW if self.health_score >= 40 else Colors.RED}"
              f"Services backend: {min(40, max(0, self.health_score - 30))}/40{Colors.END}")
              
        if self.health_score < 70:
            self.recommendations.append({
                'priority': 'CRITIQUE',
                'action': 'Démarrer les services Docker manquants',
                'details': 'Exécuter: docker-compose up -d dans le répertoire du projet'
            })
            
    async def check_network_connectivity(self):
        """Vérifie la connectivité réseau (15 points)"""
        print(f"\n{Colors.BLUE}🌐 CONNECTIVITÉ RÉSEAU{Colors.END}")
        print("-" * 40)
        
        test_urls = [
            ('Google DNS', 'https://dns.google/resolve?name=google.com&type=A'),
            ('Internet général', 'https://httpbin.org/status/200'),
        ]
        
        connectivity_score = 0
        max_connectivity = 15
        
        for name, url in test_urls:
            try:
                async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
                    async with session.get(url) as response:
                        if response.status == 200:
                            connectivity_score += max_connectivity // len(test_urls)
                            print(f"  ✅ {name}: OK")
                        else:
                            print(f"  ⚠️  {name}: HTTP {response.status}")
            except Exception as e:
                print(f"  ❌ {name}: ÉCHEC - {str(e)[:30]}")
                
        self.health_score += connectivity_score
        
        if connectivity_score == max_connectivity:
            print(f"\n{Colors.GREEN}✅ Connectivité réseau: EXCELLENTE ({connectivity_score}/{max_connectivity}){Colors.END}")
        elif connectivity_score > 0:
            print(f"\n{Colors.YELLOW}⚠️  Connectivité réseau: LIMITÉE ({connectivity_score}/{max_connectivity}){Colors.END}")
        else:
            print(f"\n{Colors.RED}❌ Connectivité réseau: ÉCHEC ({connectivity_score}/{max_connectivity}){Colors.END}")
            self.issues.append("Pas de connectivité internet")
            self.recommendations.append({
                'priority': 'MAJEUR',
                'action': 'Vérifier la connexion internet',
                'details': 'Vérifier les paramètres réseau et les pare-feu'
            })
            
    async def check_flutter_configuration(self):
        """Vérifie la configuration Flutter (10 points)"""
        print(f"\n{Colors.BLUE}📱 CONFIGURATION FLUTTER{Colors.END}")
        print("-" * 40)
        
        flutter_files = [
            'frontend/flutter_app/lib/features/confidence_boost/presentation/screens/cosmic_voice_screen.dart',
            'frontend/flutter_app/lib/features/confidence_boost/data/services/universal_audio_exercise_service.dart',
        ]
        
        config_score = 0
        max_config = 10
        
        for file_path in flutter_files:
            if os.path.exists(file_path):
                config_score += max_config // len(flutter_files)
                print(f"  ✅ {os.path.basename(file_path)}: PRÉSENT")
                
                # Vérifier le contenu critique
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if 'CosmicVoiceConnectionManager' in content:
                        print(f"    ✅ Gestionnaire de connexion: DÉTECTÉ")
                    if 'cosmic_voice_control' in content:
                        print(f"    ✅ Configuration exercice: DÉTECTÉE")
            else:
                print(f"  ❌ {os.path.basename(file_path)}: MANQUANT")
                self.issues.append(f"Fichier Flutter manquant: {file_path}")
                
        self.health_score += config_score
        print(f"\n{Colors.GREEN if config_score == max_config else Colors.YELLOW}"
              f"Configuration Flutter: {config_score}/{max_config}{Colors.END}")
              
    async def check_docker_environment(self):
        """Vérifie l'environnement Docker (5 points)"""
        print(f"\n{Colors.BLUE}🐳 ENVIRONNEMENT DOCKER{Colors.END}")
        print("-" * 40)
        
        docker_score = 0
        max_docker = 5
        
        # Vérifier si Docker est installé
        try:
            process = await asyncio.create_subprocess_exec(
                'docker', '--version',
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                docker_version = stdout.decode().strip()
                print(f"  ✅ Docker: {docker_version}")
                docker_score += 3
            else:
                print(f"  ❌ Docker: NON INSTALLÉ")
                self.issues.append("Docker non installé")
        except Exception as e:
            print(f"  ❌ Docker: INACCESSIBLE - {str(e)[:30]}")
            
        # Vérifier docker-compose
        try:
            process = await asyncio.create_subprocess_exec(
                'docker-compose', '--version',
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                compose_version = stdout.decode().strip()
                print(f"  ✅ Docker Compose: {compose_version}")
                docker_score += 2
            else:
                print(f"  ❌ Docker Compose: NON INSTALLÉ")
                self.issues.append("Docker Compose non installé")
        except Exception as e:
            print(f"  ❌ Docker Compose: INACCESSIBLE")
            
        self.health_score += docker_score
        
        if docker_score < max_docker:
            self.recommendations.append({
                'priority': 'MAJEUR',
                'action': 'Installer Docker et Docker Compose',
                'details': 'Télécharger depuis https://docker.com et suivre les instructions d\'installation'
            })
            
    def generate_health_report(self):
        """Génère le rapport final de santé"""
        print(f"\n{Colors.BOLD}=" * 60)
        print("📊 RAPPORT DE SANTÉ FINAL")
        print("=" * 60 + f"{Colors.END}")
        
        # Score global
        percentage = int((self.health_score / self.max_score) * 100)
        
        if percentage >= 80:
            status_color = Colors.GREEN
            status_icon = "🟢"
            status_text = "EXCELLENT"
            status_desc = "Exercice prêt pour production"
        elif percentage >= 60:
            status_color = Colors.YELLOW
            status_icon = "🟡"
            status_text = "BON"
            status_desc = "Quelques améliorations nécessaires"
        elif percentage >= 40:
            status_color = Colors.YELLOW
            status_icon = "🟠"
            status_text = "MOYEN"
            status_desc = "Problèmes à corriger"
        else:
            status_color = Colors.RED
            status_icon = "🔴"
            status_text = "CRITIQUE"
            status_desc = "Intervention urgente requise"
            
        print(f"\n{status_color}{Colors.BOLD}")
        print(f"🏆 SCORE GLOBAL: {self.health_score}/{self.max_score} ({percentage}%)")
        print(f"{status_icon} STATUT: {status_text}")
        print(f"📝 {status_desc}")
        print(f"{Colors.END}")
        
        # Problèmes identifiés
        if self.issues:
            print(f"\n{Colors.RED}🚨 PROBLÈMES IDENTIFIÉS ({len(self.issues)}){Colors.END}")
            for i, issue in enumerate(self.issues, 1):
                print(f"  {i}. {issue}")
                
        # Recommandations
        if self.recommendations:
            print(f"\n{Colors.CYAN}💡 RECOMMANDATIONS ({len(self.recommendations)}){Colors.END}")
            for i, rec in enumerate(self.recommendations, 1):
                priority_color = Colors.RED if rec['priority'] == 'CRITIQUE' else Colors.YELLOW
                print(f"  {i}. {priority_color}[{rec['priority']}]{Colors.END} {rec['action']}")
                if rec.get('details'):
                    print(f"     💬 {rec['details']}")
                    
        return {
            'timestamp': datetime.now().isoformat(),
            'health_score': self.health_score,
            'max_score': self.max_score,
            'percentage': percentage,
            'status': status_text,
            'issues': self.issues,
            'recommendations': self.recommendations
        }
        
    async def run_complete_diagnosis(self):
        """Lance le diagnostic complet"""
        self.print_header()
        
        # Exécuter tous les checks
        await self.check_environment_variables()
        await self.check_backend_services()
        await self.check_network_connectivity()
        await self.check_flutter_configuration()
        await self.check_docker_environment()
        
        # Générer le rapport final
        report = self.generate_health_report()
        
        # Sauvegarder le rapport
        report_file = f"cosmic_voice_health_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
            
        print(f"\n{Colors.CYAN}📁 Rapport sauvegardé: {report_file}{Colors.END}")
        
        return report

async def main():
    """Point d'entrée principal"""
    try:
        checker = CosmicVoiceHealthChecker()
        report = await checker.run_complete_diagnosis()
        
        # Code de sortie basé sur la santé
        if report['percentage'] >= 80:
            return 0  # Succès
        elif report['percentage'] >= 40:
            return 1  # Avertissement
        else:
            return 2  # Erreur critique
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}⚠️  Diagnostic interrompu par l'utilisateur{Colors.END}")
        return 130
    except Exception as e:
        print(f"\n{Colors.RED}❌ Erreur inattendue: {str(e)}{Colors.END}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)