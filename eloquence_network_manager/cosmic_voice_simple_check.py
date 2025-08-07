#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
DIAGNOSTIC AUTOMATIQUE - EXERCICE COSMIC VOICE (Version Simple)
Gestionnaire Réseau Intelligent Eloquence
"""

import asyncio
import aiohttp
import os
import sys
import json
from datetime import datetime
from dotenv import load_dotenv

# Charger le fichier .env depuis la racine du projet
load_dotenv('../.env')

class CosmicVoiceSimpleChecker:
    def __init__(self):
        self.health_score = 0
        self.max_score = 100
        self.issues = []
        self.recommendations = []
        
    def print_header(self):
        """Affiche l'en-tête du diagnostic"""
        print("=" * 60)
        print("     DIAGNOSTIC COSMIC VOICE")
        print("   Gestionnaire Réseau Eloquence")
        print("=" * 60)
        print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
    async def check_environment_variables(self):
        """Vérifie les variables d'environnement requises (30 points)"""
        print("\n[1/5] VARIABLES D'ENVIRONNEMENT")
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
                print(f"  [OK] {var}: {masked_value}")
            else:
                missing_vars.append(var)
                print(f"  [MANQUE] {var}: NON DÉFINIE")
                self.issues.append(f"Variable d'environnement manquante: {var}")
                
        if not missing_vars:
            self.health_score += 30
            print(f"\nRésultat: PARFAIT (30/30 points)")
        else:
            partial_score = int(30 * len(present_vars) / len(required_vars))
            self.health_score += partial_score
            print(f"\nRésultat: PARTIEL ({partial_score}/30 points)")
            
            self.recommendations.append({
                'priority': 'CRITIQUE',
                'action': 'Configurer les variables d\'environnement manquantes',
                'details': f"Ajouter au fichier .env:\n" + 
                          "\n".join([f"{var}=your_{var.lower()}_value" for var in missing_vars])
            })
            
    async def check_backend_services(self):
        """Vérifie les services backend requis (40 points)"""
        print("\n[2/5] SERVICES BACKEND")
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
                'url': 'http://localhost:8002/health',
                'description': 'Reconnaissance vocale et pitch',
                'points': 10
            },
            {
                'name': 'mistral-conversation',
                'url': 'http://localhost:8001/health',
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
                        print(f"  [OK] {service['name']}: DISPONIBLE")
                    except ImportError:
                        print(f"  [WARN] {service['name']}: Module redis non installé")
                        self.issues.append(f"Module Python 'redis' manquant")
                    except Exception as e:
                        print(f"  [FAIL] {service['name']}: INDISPONIBLE - {str(e)[:50]}")
                        self.issues.append(f"Service {service['name']} indisponible")
                else:
                    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
                        async with session.get(service['url']) as response:
                            if response.status == 200:
                                self.health_score += service['points']
                                print(f"  [OK] {service['name']}: DISPONIBLE (HTTP {response.status})")
                            else:
                                print(f"  [FAIL] {service['name']}: ERREUR HTTP {response.status}")
                                self.issues.append(f"Service {service['name']} erreur HTTP {response.status}")
                                
            except asyncio.TimeoutError:
                print(f"  [TIMEOUT] {service['name']}: TIMEOUT (>5s)")
                self.issues.append(f"Service {service['name']} timeout")
            except Exception as e:
                print(f"  [FAIL] {service['name']}: ÉCHEC - {str(e)[:50]}")
                self.issues.append(f"Service {service['name']} inaccessible: {str(e)[:50]}")
                
        services_score = min(40, max(0, self.health_score - 30))
        print(f"\nRésultat: Services backend ({services_score}/40 points)")
              
        if self.health_score < 70:
            self.recommendations.append({
                'priority': 'CRITIQUE',
                'action': 'Démarrer les services Docker manquants',
                'details': 'Exécuter: docker-compose up -d dans le répertoire du projet'
            })
            
    async def check_network_connectivity(self):
        """Vérifie la connectivité réseau (15 points)"""
        print("\n[3/5] CONNECTIVITÉ RÉSEAU")
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
                            print(f"  [OK] {name}: ACCESSIBLE")
                        else:
                            print(f"  [WARN] {name}: HTTP {response.status}")
            except Exception as e:
                print(f"  [FAIL] {name}: ÉCHEC - {str(e)[:30]}")
                
        self.health_score += connectivity_score
        
        if connectivity_score == max_connectivity:
            print(f"\nRésultat: Connectivité EXCELLENTE ({connectivity_score}/{max_connectivity} points)")
        elif connectivity_score > 0:
            print(f"\nRésultat: Connectivité LIMITÉE ({connectivity_score}/{max_connectivity} points)")
        else:
            print(f"\nRésultat: Connectivité ÉCHEC ({connectivity_score}/{max_connectivity} points)")
            self.issues.append("Pas de connectivité internet")
            self.recommendations.append({
                'priority': 'MAJEUR',
                'action': 'Vérifier la connexion internet',
                'details': 'Vérifier les paramètres réseau et les pare-feu'
            })
            
    async def check_flutter_configuration(self):
        """Vérifie la configuration Flutter (10 points)"""
        print("\n[4/5] CONFIGURATION FLUTTER")
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
                print(f"  [OK] {os.path.basename(file_path)}: PRÉSENT")
                
                # Vérifier le contenu critique
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if 'CosmicVoiceConnectionManager' in content:
                            print(f"    [OK] Gestionnaire de connexion: DÉTECTÉ")
                        if 'cosmic_voice_control' in content:
                            print(f"    [OK] Configuration exercice: DÉTECTÉE")
                except Exception as e:
                    print(f"    [WARN] Erreur lecture fichier: {str(e)[:30]}")
            else:
                print(f"  [FAIL] {os.path.basename(file_path)}: MANQUANT")
                self.issues.append(f"Fichier Flutter manquant: {file_path}")
                
        self.health_score += config_score
        print(f"\nRésultat: Configuration Flutter ({config_score}/{max_config} points)")
              
    async def check_docker_environment(self):
        """Vérifie l'environnement Docker (5 points)"""
        print("\n[5/5] ENVIRONNEMENT DOCKER")
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
                print(f"  [OK] Docker: {docker_version}")
                docker_score += 3
            else:
                print(f"  [FAIL] Docker: NON INSTALLÉ")
                self.issues.append("Docker non installé")
        except Exception as e:
            print(f"  [FAIL] Docker: INACCESSIBLE - {str(e)[:30]}")
            
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
                print(f"  [OK] Docker Compose: {compose_version}")
                docker_score += 2
            else:
                print(f"  [FAIL] Docker Compose: NON INSTALLÉ")
                self.issues.append("Docker Compose non installé")
        except Exception as e:
            print(f"  [FAIL] Docker Compose: INACCESSIBLE")
            
        self.health_score += docker_score
        print(f"\nRésultat: Docker ({docker_score}/{max_docker} points)")
        
        if docker_score < max_docker:
            self.recommendations.append({
                'priority': 'MAJEUR',
                'action': 'Installer Docker et Docker Compose',
                'details': 'Télécharger depuis https://docker.com'
            })
            
    def generate_health_report(self):
        """Génère le rapport final de santé"""
        print("\n" + "=" * 60)
        print("RAPPORT DE SANTÉ FINAL")
        print("=" * 60)
        
        # Score global
        percentage = int((self.health_score / self.max_score) * 100)
        
        if percentage >= 80:
            status_text = "EXCELLENT"
            status_desc = "Exercice prêt pour production"
        elif percentage >= 60:
            status_text = "BON"
            status_desc = "Quelques améliorations nécessaires"
        elif percentage >= 40:
            status_text = "MOYEN"
            status_desc = "Problèmes à corriger"
        else:
            status_text = "CRITIQUE"
            status_desc = "Intervention urgente requise"
            
        print(f"\nSCORE GLOBAL: {self.health_score}/{self.max_score} ({percentage}%)")
        print(f"STATUT: {status_text}")
        print(f"DESCRIPTION: {status_desc}")
        
        # Problèmes identifiés
        if self.issues:
            print(f"\nPROBLÈMES IDENTIFIÉS ({len(self.issues)}):")
            for i, issue in enumerate(self.issues, 1):
                print(f"  {i}. {issue}")
                
        # Recommandations
        if self.recommendations:
            print(f"\nRECOMMANDATIONS ({len(self.recommendations)}):")
            for i, rec in enumerate(self.recommendations, 1):
                print(f"  {i}. [{rec['priority']}] {rec['action']}")
                if rec.get('details'):
                    print(f"     -> {rec['details']}")
                    
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
            
        print(f"\nRapport sauvegardé: {report_file}")
        
        return report

async def main():
    """Point d'entrée principal"""
    try:
        checker = CosmicVoiceSimpleChecker()
        report = await checker.run_complete_diagnosis()
        
        # Code de sortie basé sur la santé
        if report['percentage'] >= 80:
            return 0  # Succès
        elif report['percentage'] >= 40:
            return 1  # Avertissement
        else:
            return 2  # Erreur critique
            
    except KeyboardInterrupt:
        print("\nDiagnostic interrompu par l'utilisateur")
        return 130
    except Exception as e:
        print(f"\nErreur inattendue: {str(e)}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)