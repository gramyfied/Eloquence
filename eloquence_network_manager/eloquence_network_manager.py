#!/usr/bin/env python3
"""
Gestionnaire Réseau Intelligent Eloquence
==========================================

Centralise la gestion de toutes les routes, endpoints, URLs et clés API 
avec détection automatique d'erreurs et validation des nouveaux exercices.

Auteur: Eloquence Team
Version: 1.0.0
"""

import asyncio
import aiohttp
import yaml
import redis
import websockets
import time
import json
import os
import sys
import argparse
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, NamedTuple
from dataclasses import dataclass, asdict
from pathlib import Path
from colorama import Fore, Back, Style, init
import psutil
import docker
import traceback
from dotenv import load_dotenv

# Initialiser colorama pour Windows
init(autoreset=True)

@dataclass
class HealthCheckResult:
    """Résultat d'une vérification de santé de service"""
    service_name: str
    status: str  # 'healthy', 'unhealthy', 'timeout', 'unreachable'
    response_time: float  # en millisecondes
    error_message: Optional[str] = None
    details: Optional[Dict] = None
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

@dataclass
class ServiceConfig:
    """Configuration d'un service"""
    name: str
    type: str  # 'http', 'websocket', 'redis'
    url: str
    timeout: int
    critical: bool
    health_endpoint: Optional[str] = None
    auth_required: bool = False
    dependencies: List[str] = None
    docker_service: Optional[str] = None
    credentials: Optional[Dict] = None
    description: str = ""
    
    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = []

class EloquenceNetworkManager:
    """Gestionnaire réseau intelligent pour l'application Eloquence"""
    
    def __init__(self, config_path: str = None):
        self.config_path = config_path or "eloquence_network_config.yaml"
        self.services: Dict[str, ServiceConfig] = {}
        self.session: Optional[aiohttp.ClientSession] = None
        self.redis_client: Optional[redis.Redis] = None
        self.docker_client: Optional[docker.DockerClient] = None
        self.health_history: Dict[str, List[HealthCheckResult]] = {}
        self.circuit_breakers: Dict[str, Dict] = {}
        self.logger = self._setup_logger()
        
        # Configuration de monitoring
        self.monitoring_config = {
            'health_check_interval': 30,
            'retry_attempts': 3,
            'backoff_factor': 2.0,
            'circuit_breaker_threshold': 5,
            'circuit_breaker_timeout': 60
        }
        
    def _setup_logger(self) -> logging.Logger:
        """Configure le système de logging"""
        logger = logging.getLogger('eloquence_network_manager')
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
        
    async def initialize(self) -> bool:
        """
        Initialise le gestionnaire réseau
        
        Returns:
            bool: True si l'initialisation réussit
        """
        try:
            self.logger.info("🚀 Initialisation du Gestionnaire Réseau Eloquence")
            
            # 1. Charger la configuration YAML
            if not await self._load_configuration():
                return False
                
            # 2. Initialiser la session HTTP avec pool de connexions
            self._init_http_session()
            
            # 3. Tenter la connexion Redis (optionnelle)
            await self._init_redis_connection()
            
            # 4. Initialiser le client Docker
            self._init_docker_client()

            # 5. Charger les variables d'environnement depuis .env
            self._load_environment_variables()
            
            # 6. Valider les variables d'environnement critiques
            if not self._validate_environment_variables():
                return False
                
            # 7. Test de connectivité initial
            initial_health = await self.check_all_services()
            healthy_services = sum(1 for result in initial_health['services'].values() 
                                 if result.status == 'healthy')
            total_services = len(initial_health['services'])
            
            self.logger.info(
                f"✅ Initialisation terminée - {healthy_services}/{total_services} services actifs"
            )
            
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erreur lors de l'initialisation: {str(e)}")
            return False

    def _load_environment_variables(self):
        """Charge les variables d'environnement depuis le fichier .env à la racine"""
        try:
            project_root = Path(__file__).resolve().parent.parent
            dotenv_path = project_root / '.env'
            if dotenv_path.exists():
                load_dotenv(dotenv_path=dotenv_path)
                self.logger.info(f"🌍 Variables d'environnement chargées depuis {dotenv_path}")
            else:
                self.logger.warning(f"⚠️ Fichier .env non trouvé à {dotenv_path}, utilisation des variables système.")
        except Exception as e:
            self.logger.error(f"❌ Erreur lors du chargement du fichier .env: {e}")

    async def _load_configuration(self) -> bool:
        """Charge la configuration depuis le fichier YAML"""
        try:
            config_file = Path(self.config_path)
            if not config_file.exists():
                self.logger.error(f"❌ Fichier de configuration introuvable: {self.config_path}")
                return False
                
            with open(config_file, 'r', encoding='utf-8') as f:
                config_data = yaml.safe_load(f)
                
            # Parser les services
            for service_data in config_data.get('services', []):
                service_config = ServiceConfig(**service_data)
                self.services[service_config.name] = service_config
                
            # Charger la configuration de monitoring
            if 'monitoring' in config_data:
                self.monitoring_config.update(config_data['monitoring'])
                
            self.logger.info(f"📋 Configuration chargée - {len(self.services)} services détectés")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erreur lors du chargement de la configuration: {str(e)}")
            return False
            
    def _init_http_session(self):
        """Initialise la session HTTP avec pool de connexions optimisé"""
        connector = aiohttp.TCPConnector(
            limit=100,  # Limite globale de connexions
            limit_per_host=30,  # Limite par host
            ttl_dns_cache=300,  # Cache DNS
            use_dns_cache=True,
            keepalive_timeout=30,
            enable_cleanup_closed=True
        )
        
        timeout = aiohttp.ClientTimeout(total=30, connect=10)
        
        self.session = aiohttp.ClientSession(
            connector=connector,
            timeout=timeout,
            headers={'User-Agent': 'EloquenceNetworkManager/1.0.0'}
        )
        
        self.logger.info("🌐 Session HTTP initialisée avec pool de connexions")
        
    async def _init_redis_connection(self):
        """Initialise la connexion Redis (optionnelle)"""
        try:
            redis_service = self.services.get('redis')
            if redis_service:
                # Extraire host et port de l'URL Redis
                redis_url = redis_service.url
                if redis_url.startswith('redis://'):
                    redis_url = redis_url[8:]  # Enlever le préfixe
                    
                if ':' in redis_url:
                    host, port = redis_url.split(':')
                    port = int(port.split('/')[0])  # Enlever la DB si présente
                else:
                    host, port = redis_url, 6379
                    
                self.redis_client = redis.Redis(
                    host=host, 
                    port=port, 
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5
                )
                
                # Test de connexion
                await asyncio.get_event_loop().run_in_executor(
                    None, self.redis_client.ping
                )
                
                self.logger.info("🔴 Connexion Redis établie")
                
        except Exception as e:
            self.logger.warning(f"⚠️ Connexion Redis échouée (optionnelle): {str(e)}")
            self.redis_client = None
            
    def _init_docker_client(self):
        """Initialise le client Docker pour l'auto-réparation"""
        try:
            self.docker_client = docker.from_env()
            # Test de connexion
            self.docker_client.ping()
            self.logger.info("🐳 Client Docker initialisé")
            
        except Exception as e:
            self.logger.warning(f"⚠️ Client Docker non disponible: {str(e)}")
            self.docker_client = None
            
    def _validate_environment_variables(self) -> bool:
        """Valide la présence des variables d'environnement critiques"""
        required_vars = [
            'LIVEKIT_API_KEY',
            'LIVEKIT_API_SECRET', 
            'LIVEKIT_URL',
            'MISTRAL_API_KEY',
            'SCALEWAY_MISTRAL_URL'
        ]
        
        missing_vars = []
        for var in required_vars:
            if not os.getenv(var):
                missing_vars.append(var)
                
        if missing_vars:
            self.logger.error(
                f"❌ Variables d'environnement manquantes: {', '.join(missing_vars)}"
            )
            return False
            
        self.logger.info("✅ Variables d'environnement validées")
        return True
        
    async def check_service_health(self, service_name: str) -> HealthCheckResult:
        """
        Vérification spécialisée de santé d'un service
        
        Args:
            service_name: Nom du service à vérifier
            
        Returns:
            HealthCheckResult: Résultat de la vérification
        """
        start_time = time.time()
        
        if service_name not in self.services:
            return HealthCheckResult(
                service_name=service_name,
                status='unreachable',
                response_time=0,
                error_message=f"Service '{service_name}' non configuré"
            )
            
        service = self.services[service_name]
        
        try:
            # Vérifier le circuit breaker
            if self._is_circuit_breaker_open(service_name):
                return HealthCheckResult(
                    service_name=service_name,
                    status='circuit_breaker_open',
                    response_time=0,
                    error_message="Circuit breaker ouvert"
                )
            
            # Déléguer selon le type de service
            if service.type == 'http':
                result = await self._check_http_health(service)
            elif service.type == 'websocket':
                result = await self._check_websocket_health(service)
            elif service.type == 'redis':
                result = await self._check_redis_health(service)
            else:
                result = HealthCheckResult(
                    service_name=service_name,
                    status='unsupported',
                    response_time=0,
                    error_message=f"Type de service non supporté: {service.type}"
                )
                
            # Calculer le temps de réponse
            result.response_time = (time.time() - start_time) * 1000
            
            # Mettre à jour l'historique et le circuit breaker
            self._update_health_history(service_name, result)
            self._update_circuit_breaker(service_name, result)
            
            return result
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            result = HealthCheckResult(
                service_name=service_name,
                status='error',
                response_time=response_time,
                error_message=str(e)
            )
            
            self._update_health_history(service_name, result)
            self._update_circuit_breaker(service_name, result)
            
            return result
            
    async def _check_http_health(self, service: ServiceConfig) -> HealthCheckResult:
        """Vérification de santé HTTP"""
        url = service.url
        if service.health_endpoint:
            url = f"{service.url.rstrip('/')}{service.health_endpoint}"
            
        headers = {}
        if service.auth_required and service.credentials:
            # Ajouter l'authentification si nécessaire
            if 'api_key' in service.credentials:
                headers['Authorization'] = f"Bearer {service.credentials['api_key']}"
                
        async with self.session.get(
            url, 
            headers=headers,
            timeout=aiohttp.ClientTimeout(total=service.timeout)
        ) as response:
            
            if response.status == 200:
                # Tenter de parser la réponse JSON pour plus de détails
                try:
                    data = await response.json()
                    return HealthCheckResult(
                        service_name=service.name,
                        status='healthy',
                        response_time=0,  # Sera calculé plus tard
                        details=data
                    )
                except:
                    return HealthCheckResult(
                        service_name=service.name,
                        status='healthy',
                        response_time=0
                    )
            else:
                return HealthCheckResult(
                    service_name=service.name,
                    status='unhealthy',
                    response_time=0,
                    error_message=f"HTTP {response.status}: {response.reason}"
                )
                
    async def _check_websocket_health(self, service: ServiceConfig) -> HealthCheckResult:
        """Vérification de santé WebSocket (LiveKit)"""
        try:
            # Pour LiveKit, on fait un test de connexion simple
            async with websockets.connect(
                service.url,
                timeout=service.timeout,
                ping_interval=None  # Désactiver les pings auto
            ) as websocket:
                # Connexion réussie
                return HealthCheckResult(
                    service_name=service.name,
                    status='healthy',
                    response_time=0,
                    details={'connection': 'established'}
                )
                
        except websockets.exceptions.ConnectionClosed:
            return HealthCheckResult(
                service_name=service.name,
                status='unhealthy',
                response_time=0,
                error_message="Connexion WebSocket fermée"
            )
        except asyncio.TimeoutError:
            return HealthCheckResult(
                service_name=service.name,
                status='timeout',
                response_time=0,
                error_message="Timeout de connexion WebSocket"
            )
            
    async def _check_redis_health(self, service: ServiceConfig) -> HealthCheckResult:
        """Vérification de santé Redis"""
        if not self.redis_client:
            return HealthCheckResult(
                service_name=service.name,
                status='unhealthy',
                response_time=0,
                error_message="Client Redis non initialisé"
            )
            
        try:
            # Test ping Redis
            result = await asyncio.get_event_loop().run_in_executor(
                None, self.redis_client.ping
            )
            
            if result:
                # Obtenir des infos supplémentaires
                info = await asyncio.get_event_loop().run_in_executor(
                    None, self.redis_client.info
                )
                
                return HealthCheckResult(
                    service_name=service.name,
                    status='healthy',
                    response_time=0,
                    details={
                        'connected_clients': info.get('connected_clients', 0),
                        'used_memory_human': info.get('used_memory_human', 'Unknown'),
                        'uptime_in_seconds': info.get('uptime_in_seconds', 0)
                    }
                )
            else:
                return HealthCheckResult(
                    service_name=service.name,
                    status='unhealthy',
                    response_time=0,
                    error_message="Redis ping échoué"
                )
                
        except redis.ConnectionError as e:
            return HealthCheckResult(
                service_name=service.name,
                status='unreachable',
                response_time=0,
                error_message=f"Connexion Redis échouée: {str(e)}"
            )
            
    def _is_circuit_breaker_open(self, service_name: str) -> bool:
        """Vérifie si le circuit breaker est ouvert pour un service"""
        if service_name not in self.circuit_breakers:
            return False
            
        breaker = self.circuit_breakers[service_name]
        if breaker['state'] != 'open':
            return False
            
        # Vérifier si le timeout est écoulé
        if datetime.now() > breaker['opened_at'] + timedelta(
            seconds=self.monitoring_config['circuit_breaker_timeout']
        ):
            breaker['state'] = 'half_open'
            return False
            
        return True
        
    def _update_health_history(self, service_name: str, result: HealthCheckResult):
        """Met à jour l'historique de santé d'un service"""
        if service_name not in self.health_history:
            self.health_history[service_name] = []
            
        self.health_history[service_name].append(result)
        
        # Garder seulement les 100 derniers résultats
        if len(self.health_history[service_name]) > 100:
            self.health_history[service_name] = self.health_history[service_name][-100:]
            
    def _update_circuit_breaker(self, service_name: str, result: HealthCheckResult):
        """Met à jour l'état du circuit breaker"""
        if service_name not in self.circuit_breakers:
            self.circuit_breakers[service_name] = {
                'state': 'closed',
                'failure_count': 0,
                'opened_at': None
            }
            
        breaker = self.circuit_breakers[service_name]
        
        if result.status in ['healthy']:
            # Réinitialiser le compteur d'échecs
            breaker['failure_count'] = 0
            if breaker['state'] == 'half_open':
                breaker['state'] = 'closed'
        else:
            # Incrémenter le compteur d'échecs
            breaker['failure_count'] += 1
            
            # Ouvrir le circuit breaker si le seuil est atteint
            if (breaker['failure_count'] >= self.monitoring_config['circuit_breaker_threshold'] 
                and breaker['state'] == 'closed'):
                breaker['state'] = 'open'
                breaker['opened_at'] = datetime.now()
                self.logger.warning(
                    f"🔴 Circuit breaker ouvert pour {service_name} "
                    f"après {breaker['failure_count']} échecs"
                )
                
    async def check_all_services(self) -> Dict:
        """
        Vérification parallèle de tous les services
        
        Returns:
            Dict: Rapport complet avec score de santé global
        """
        self.logger.info("🔍 Vérification de tous les services...")
        
        # Lancer toutes les vérifications en parallèle
        tasks = [
            self.check_service_health(service_name) 
            for service_name in self.services.keys()
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Organiser les résultats
        service_results = {}
        for i, result in enumerate(results):
            service_name = list(self.services.keys())[i]
            
            if isinstance(result, Exception):
                service_results[service_name] = HealthCheckResult(
                    service_name=service_name,
                    status='error',
                    response_time=0,
                    error_message=str(result)
                )
            else:
                service_results[service_name] = result
                
        # Calculer le score de santé global
        total_services = len(service_results)
        healthy_services = sum(
            1 for result in service_results.values() 
            if result.status == 'healthy'
        )
        critical_services = sum(
            1 for name, result in service_results.items()
            if self.services[name].critical and result.status == 'healthy'
        )
        total_critical = sum(
            1 for service in self.services.values()
            if service.critical
        )
        
        # Score pondéré (services critiques comptent double)
        if total_critical > 0:
            global_health_score = (
                (critical_services / total_critical) * 70 +  # 70% pour les services critiques
                ((healthy_services - critical_services) / max(1, total_services - total_critical)) * 30  # 30% pour les autres
            )
        else:
            global_health_score = (healthy_services / total_services) * 100 if total_services > 0 else 0
            
        # Détecter les dépendances en cascade
        dependency_issues = self._detect_cascade_dependencies(service_results)
        
        return {
            'timestamp': datetime.now(),
            'global_health_score': round(global_health_score, 1),
            'services': service_results,
            'summary': {
                'total_services': total_services,
                'healthy_services': healthy_services,
                'critical_services_healthy': critical_services,
                'total_critical_services': total_critical
            },
            'dependency_issues': dependency_issues
        }
        
    def _detect_cascade_dependencies(self, service_results: Dict[str, HealthCheckResult]) -> List[str]:
        """Détecte les problèmes de dépendances en cascade"""
        issues = []
        
        for service_name, result in service_results.items():
            if result.status != 'healthy':
                service = self.services[service_name]
                
                # Trouver les services qui dépendent de celui-ci
                dependent_services = [
                    name for name, svc in self.services.items()
                    if service_name in svc.dependencies
                ]
                
                if dependent_services:
                    issues.append(
                        f"Service '{service_name}' en panne affecte: {', '.join(dependent_services)}"
                    )
                    
        return issues
        
    async def auto_fix_issues(self) -> List[str]:
        """
        Tentative de correction automatique des problèmes détectés
        
        Returns:
            List[str]: Liste des actions entreprises
        """
        actions = []
        
        try:
            self.logger.info("🔧 Démarrage des corrections automatiques...")
            
            # 1. Redémarrage des services Docker défaillants
            if self.docker_client:
                docker_actions = await self._restart_unhealthy_docker_services()
                actions.extend(docker_actions)
                
            # 2. Nettoyage du cache Redis si disponible
            if self.redis_client:
                redis_actions = await self._cleanup_redis_cache()
                actions.extend(redis_actions)
                
            # 3. Ajustement automatique des timeouts
            timeout_actions = self._adjust_service_timeouts()
            actions.extend(timeout_actions)
            
            # 4. Régénération des tokens expirés (si détecté)
            token_actions = await self._regenerate_expired_tokens()
            actions.extend(token_actions)
            
            if actions:
                self.logger.info(f"✅ {len(actions)} actions correctives effectuées")
            else:
                self.logger.info("ℹ️ Aucune correction automatique nécessaire")
                
            return actions
            
        except Exception as e:
            error_msg = f"Erreur lors de l'auto-réparation: {str(e)}"
            self.logger.error(f"❌ {error_msg}")
            return [error_msg]
            
    async def _restart_unhealthy_docker_services(self) -> List[str]:
        """Redémarre les services Docker défaillants"""
        actions = []
        
        try:
            # Obtenir l'état actuel des services
            health_report = await self.check_all_services()
            
            for service_name, result in health_report['services'].items():
                if result.status in ['unhealthy', 'unreachable', 'timeout']:
                    service = self.services[service_name]
                    
                    if service.docker_service:
                        try:
                            # Trouver le conteneur Docker
                            containers = self.docker_client.containers.list(
                                filters={'name': service.docker_service}
                            )
                            
                            if containers:
                                container = containers[0]
                                self.logger.info(f"🔄 Redémarrage du conteneur {service.docker_service}")
                                
                                container.restart()
                                actions.append(f"Redémarré le service Docker: {service.docker_service}")
                                
                                # Attendre un peu avant de vérifier
                                await asyncio.sleep(5)
                                
                        except docker.errors.DockerException as e:
                            actions.append(f"Échec redémarrage Docker {service.docker_service}: {str(e)}")
                            
        except Exception as e:
            actions.append(f"Erreur lors du redémarrage Docker: {str(e)}")
            
        return actions
        
    async def _cleanup_redis_cache(self) -> List[str]:
        """Nettoie le cache Redis si nécessaire"""
        actions = []
        
        try:
            if self.redis_client:
                # Obtenir des infos sur l'utilisation mémoire
                info = await asyncio.get_event_loop().run_in_executor(
                    None, self.redis_client.info
                )
                
                used_memory = info.get('used_memory', 0)
                max_memory = info.get('maxmemory', 0)
                
                # Si l'utilisation mémoire est élevée, nettoyer les clés expirées
                if max_memory > 0 and used_memory / max_memory > 0.8:
                    # Exécuter un nettoyage des clés expirées
                    await asyncio.get_event_loop().run_in_executor(
                        None, self.redis_client.flushdb
                    )
                    actions.append("Nettoyage du cache Redis effectué")
                    
        except Exception as e:
            actions.append(f"Erreur lors du nettoyage Redis: {str(e)}")
            
        return actions
        
    def _adjust_service_timeouts(self) -> List[str]:
        """Ajuste automatiquement les timeouts des services"""
        actions = []
        
        try:
            for service_name in self.services:
                if service_name in self.health_history:
                    recent_results = self.health_history[service_name][-10:]  # 10 derniers résultats
                    
                    if len(recent_results) >= 5:
                        avg_response_time = sum(r.response_time for r in recent_results) / len(recent_results)
                        
                        service = self.services[service_name]
                        current_timeout = service.timeout
                        
                        # Si le temps de réponse moyen est proche du timeout, l'augmenter
                        if avg_response_time > current_timeout * 0.8:
                            new_timeout = min(current_timeout * 1.5, 300)  # Max 5 minutes
                            service.timeout = int(new_timeout)
                            actions.append(
                                f"Timeout ajusté pour {service_name}: {current_timeout}s → {new_timeout}s"
                            )
                            
        except Exception as e:
            actions.append(f"Erreur lors de l'ajustement des timeouts: {str(e)}")
            
        return actions
        
    async def _regenerate_expired_tokens(self) -> List[str]:
        """Régénère les tokens expirés si nécessaire"""
        actions = []
        
        try:
            # Vérifier les services nécessitant des tokens
            token_services = [
                service for service in self.services.values()
                if service.auth_required and service.credentials
            ]
            
            for service in token_services:
                # Pour l'instant, juste loguer la nécessité de régénération
                # Dans une implémentation complète, cela ferait appel aux APIs de génération de tokens
                if service.name == 'livekit_token_service':
                    actions.append(f"Vérification du token LiveKit pour {service.name}")
                    
        except Exception as e:
            actions.append(f"Erreur lors de la régénération des tokens: {str(e)}")
            
        return actions
        
    async def generate_report(self) -> Dict:
        """
        Génère un rapport complet du système
        
        Returns:
            Dict: Rapport JSON structuré
        """
        self.logger.info("📊 Génération du rapport complet...")
        
        # Obtenir l'état actuel
        current_health = await self.check_all_services()
        
        # Statistiques système
        system_stats = {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent if os.name != 'nt' else psutil.disk_usage('C:\\').percent,
            'network_connections': len(psutil.net_connections())
        }
        
        # Analyse de performance
        performance_analysis = self._analyze_performance()
        
        # Recommandations d'optimisation
        recommendations = self._generate_recommendations(current_health)
        
        # Historique des incidents
        incident_history = self._analyze_incident_history()
        
        report = {
            'metadata': {
                'generated_at': datetime.now().isoformat(),
                'manager_version': '1.0.0',
                'config_file': self.config_path
            },
            'current_status': current_health,
            'system_metrics': system_stats,
            'performance_analysis': performance_analysis,
            'recommendations': recommendations,
            'incident_history': incident_history,
            'circuit_breakers': self.circuit_breakers
        }
        
        return report
        
    def _analyze_performance(self) -> Dict:
        """Analyse les métriques de performance"""
        analysis = {
            'avg_response_times': {},
            'reliability_scores': {},
            'trending': {}
        }
        
        for service_name, history in self.health_history.items():
            if len(history) >= 5:
                # Temps de réponse moyen
                response_times = [r.response_time for r in history if r.response_time > 0]
                if response_times:
                    analysis['avg_response_times'][service_name] = {
                        'avg': round(sum(response_times) / len(response_times), 2),
                        'min': round(min(response_times), 2),
                        'max': round(max(response_times), 2)
                    }
                
                # Score de fiabilité (% de succès)
                healthy_checks = sum(1 for r in history if r.status == 'healthy')
                reliability = (healthy_checks / len(history)) * 100
                analysis['reliability_scores'][service_name] = round(reliability, 1)
                
                # Tendance (comparaison récente vs ancienne)
                if len(history) >= 10:
                    recent = history[-5:]
                    older = history[-10:-5]
                    
                    recent_avg = sum(r.response_time for r in recent if r.response_time > 0) / max(1, len([r for r in recent if r.response_time > 0]))
                    older_avg = sum(r.response_time for r in older if r.response_time > 0) / max(1, len([r for r in older if r.response_time > 0]))
                    
                    if older_avg > 0:
                        trend = ((recent_avg - older_avg) / older_avg) * 100
                        analysis['trending'][service_name] = {
                            'direction': 'improving' if trend < -5 else 'degrading' if trend > 5 else 'stable',
                            'change_percent': round(trend, 1)
                        }
                        
        return analysis
        
    def _generate_recommendations(self, health_report: Dict) -> List[str]:
        """Génère des recommandations d'optimisation"""
        recommendations = []
        
        # Analyser les services en panne
        for service_name, result in health_report['services'].items():
            service = self.services[service_name]
            
            if result.status != 'healthy' and service.critical:
                recommendations.append(
                    f"🔴 CRITIQUE: Service {service_name} défaillant - {result.error_message}"
                )
                
            elif result.status == 'timeout':
                recommendations.append(
                    f"⏱️ Augmenter le timeout pour {service_name} (actuel: {service.timeout}s)"
                )
                
            elif result.response_time > 5000:  # Plus de 5 secondes
                recommendations.append(
                    f"🐌 Performance dégradée pour {service_name} ({result.response_time:.0f}ms)"
                )
                
        # Analyser le score global
        global_score = health_report['global_health_score']
        if global_score < 70:
            recommendations.append(
                f"🚨 Score de santé global faible ({global_score}%) - Investigation requise"
            )
        elif global_score < 90:
            recommendations.append(
                f"⚠️ Score de santé global moyen ({global_score}%) - Optimisation recommandée"
            )
            
        # Analyser les dépendances
        if health_report['dependency_issues']:
            recommendations.extend([
                f"🔗 Problème de dépendance: {issue}"
                for issue in health_report['dependency_issues']
            ])
            
        if not recommendations:
            recommendations.append("✅ Système en bonne santé - Aucune action requise")
            
        return recommendations
        
    def _analyze_incident_history(self) -> Dict:
        """Analyse l'historique des incidents"""
        incidents = {
            'total_incidents': 0,
            'incidents_by_service': {},
            'recent_incidents': []
        }
        
        cutoff_time = datetime.now() - timedelta(hours=24)
        
        for service_name, history in self.health_history.items():
            service_incidents = [
                r for r in history 
                if r.status != 'healthy' and r.timestamp > cutoff_time
            ]
            
            if service_incidents:
                incidents['incidents_by_service'][service_name] = len(service_incidents)
                incidents['total_incidents'] += len(service_incidents)
                
                # Ajouter les incidents récents
                for incident in service_incidents[-3:]:  # 3 derniers incidents
                    incidents['recent_incidents'].append({
                        'service': service_name,
                        'status': incident.status,
                        'error': incident.error_message,
                        'timestamp': incident.timestamp.isoformat()
                    })
                    
        return incidents
        
    async def monitor_continuously(self, interval: int = 60):
        """
        Monitoring continu avec intervalle configurable
        
        Args:
            interval: Intervalle en secondes entre les vérifications
        """
        self.logger.info(f"🔄 Démarrage du monitoring continu (intervalle: {interval}s)")
        
        try:
            while True:
                start_time = time.time()
                
                # Vérification de santé
                health_report = await self.check_all_services()
                
                # Affichage du statut condensé
                self._display_monitoring_status(health_report)
                
                # Auto-réparation si nécessaire
                if health_report['global_health_score'] < 80:
                    self.logger.warning("⚠️ Score de santé faible - Tentative d'auto-réparation")
                    await self.auto_fix_issues()
                    
                # Calculer le temps de traitement
                processing_time = time.time() - start_time
                
                # Attendre l'intervalle en tenant compte du temps de traitement
                sleep_time = max(0, interval - processing_time)
                await asyncio.sleep(sleep_time)
                
        except KeyboardInterrupt:
            self.logger.info("🛑 Arrêt du monitoring demandé")
        except Exception as e:
            self.logger.error(f"❌ Erreur dans le monitoring continu: {str(e)}")
            
    def _display_monitoring_status(self, health_report: Dict):
        """Affiche un statut de monitoring condensé"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        score = health_report['global_health_score']
        
        # Choisir la couleur selon le score
        if score >= 90:
            color = Fore.GREEN
            icon = "✅"
        elif score >= 70:
            color = Fore.YELLOW
            icon = "⚠️"
        else:
            color = Fore.RED
            icon = "❌"
            
        # Compter les services sains
        healthy = health_report['summary']['healthy_services']
        total = health_report['summary']['total_services']
        
        print(f"{color}[{timestamp}] {icon} Score: {score}% | Services: {healthy}/{total}{Style.RESET_ALL}")
        
        # Afficher les services en panne s'il y en a
        for name, result in health_report['services'].items():
            if result.status != 'healthy':
                print(f"  {Fore.RED}└─ {name}: {result.status} ({result.error_message}){Style.RESET_ALL}")
                
    async def close(self):
        """Ferme proprement toutes les connexions"""
        self.logger.info("🔄 Fermeture des connexions...")
        
        if self.session:
            await self.session.close()
            
        if self.redis_client:
            self.redis_client.close()
            
        if self.docker_client:
            self.docker_client.close()
            
        self.logger.info("✅ Connexions fermées")


async def main():
    """Point d'entrée principal avec interface CLI"""
    parser = argparse.ArgumentParser(description='Gestionnaire Réseau Eloquence')
    parser.add_argument('--check', action='store_true', help='Vérification rapide de tous les services')
    parser.add_argument('--monitor', type=int, metavar='INTERVAL', help='Monitoring continu (interval en secondes)')
    parser.add_argument('--fix', action='store_true', help='Correction automatique des problèmes')
    parser.add_argument('--report', action='store_true', help='Générer un rapport complet')
    parser.add_argument('--config', type=str, default='eloquence_network_config.yaml', help='Chemin vers le fichier de configuration')
    parser.add_argument('--output', type=str, help='Fichier de sortie pour le rapport (JSON)')
    
    args = parser.parse_args()
    
    # Créer et initialiser le gestionnaire
    manager = EloquenceNetworkManager(config_path=args.config)
    
    try:
        if not await manager.initialize():
            print(f"{Fore.RED}❌ Échec de l'initialisation{Style.RESET_ALL}")
            return 1
            
        if args.check:
            # Vérification rapide
            print(f"{Fore.CYAN}🌐 Gestionnaire Réseau Eloquence - Vérification Complète{Style.RESET_ALL}\n")
            
            health_report = await manager.check_all_services()
            
            # Afficher les résultats
            for service_name, result in health_report['services'].items():
                service = manager.services[service_name]
                
                if result.status == 'healthy':
                    icon = "✅"
                    color = Fore.GREEN
                elif result.status == 'timeout':
                    icon = "⏱️"
                    color = Fore.YELLOW
                else:
                    icon = "❌"
                    color = Fore.RED
                    
                print(f"{color}{icon} {service_name} ({result.response_time:.0f}ms) - {result.status.title()}{Style.RESET_ALL}")
                if result.error_message:
                    print(f"    └─ {result.error_message}")
                    
            # Score global
            score = health_report['global_health_score']
            score_color = Fore.GREEN if score >= 90 else Fore.YELLOW if score >= 70 else Fore.RED
            print(f"\n{score_color}📊 Score de Santé Global: {score}%{Style.RESET_ALL}")
            
            # Recommandations
            if health_report.get('dependency_issues'):
                print(f"\n{Fore.YELLOW}🔧 Actions recommandées:{Style.RESET_ALL}")
                for issue in health_report['dependency_issues']:
                    print(f"  - {issue}")
                    
        elif args.monitor:
            # Monitoring continu
            await manager.monitor_continuously(args.monitor)
            
        elif args.fix:
            # Correction automatique
            print(f"{Fore.CYAN}🔧 Correction automatique des problèmes...{Style.RESET_ALL}\n")
            
            actions = await manager.auto_fix_issues()
            
            if actions:
                print(f"{Fore.GREEN}✅ Actions entreprises:{Style.RESET_ALL}")
                for action in actions:
                    print(f"  - {action}")
            else:
                print(f"{Fore.GREEN}✅ Aucune correction nécessaire{Style.RESET_ALL}")
                
        elif args.report:
            # Rapport complet
            print(f"{Fore.CYAN}📊 Génération du rapport complet...{Style.RESET_ALL}\n")
            
            report = await manager.generate_report()
            
            if args.output:
                # Sauvegarder en JSON
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(report, f, indent=2, default=str)
                print(f"{Fore.GREEN}✅ Rapport sauvegardé: {args.output}{Style.RESET_ALL}")
            else:
                # Afficher un résumé
                print(json.dumps(report, indent=2, default=str))
                
        else:
            # Afficher l'aide si aucune action spécifiée
            parser.print_help()
            
        return 0
        
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}🛑 Arrêt demandé par l'utilisateur{Style.RESET_ALL}")
        return 0
    except Exception as e:
        print(f"{Fore.RED}❌ Erreur fatale: {str(e)}{Style.RESET_ALL}")
        traceback.print_exc()
        return 1
    finally:
        await manager.close()


if __name__ == '__main__':
    # Configurer l'événement loop pour Windows
    if sys.platform.startswith('win'):
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
        
    exit_code = asyncio.run(main())
    sys.exit(exit_code)