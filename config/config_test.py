"""
Tests pour le système de configuration centralisée Eloquence
Valide toutes les fonctionnalités du système
"""
import unittest
import tempfile
import shutil
import yaml
from pathlib import Path
import sys
import os

# Ajouter le répertoire config au path
config_dir = Path(__file__).parent
if str(config_dir) not in sys.path:
    sys.path.insert(0, str(config_dir))

from config_loader import ConfigLoader, EloquenceConfigError
from config_validator import ConfigValidator
from config_generator import ConfigGenerator
from config_manager import ConfigManager
from config_client import get_livekit_config, get_services_urls

class TestConfigSystem(unittest.TestCase):
    """Tests pour le système de configuration complet"""
    
    def setUp(self):
        """Configuration initiale pour les tests"""
        # Créer un répertoire temporaire pour les tests
        self.test_dir = Path(tempfile.mkdtemp())
        self.config_dir = self.test_dir / "config"
        self.config_dir.mkdir()
        
        # Créer une configuration de test
        self.test_config = {
            'eloquence_config': {
                'version': '1.0.0',
                'environment': 'test',
                'network': {
                    'domain': 'localhost',
                    'ports': {
                        'livekit_server': 7880,
                        'livekit_tcp': 7881,
                        'agent_http': 8080,
                        'redis': 6379,
                        'mistral_api': 8001,
                        'vosk_stt': 8002,
                        'eloquence_api': 8003,
                        'haproxy': 8081
                    },
                    'rtc_port_range': {
                        'start': 40000,
                        'end': 40100
                    },
                    'docker_network': 'eloquence-test-network'
                },
                'services': {
                    'livekit_server': {
                        'enabled': True,
                        'image': 'livekit/livekit-server:latest',
                        'internal_host': 'livekit-server',
                        'external_host': 'localhost'
                    },
                    'livekit_agent': {
                        'enabled': True,
                        'mode': 'multi',
                        'instances': 2,
                        'internal_host': 'livekit-agent',
                        'external_host': 'localhost'
                    },
                    'redis': {
                        'enabled': True,
                        'image': 'redis:7-alpine',
                        'internal_host': 'eloquence-redis',
                        'external_host': 'localhost'
                    },
                    'mistral_api': {
                        'enabled': True,
                        'internal_host': 'mistral-conversation',
                        'external_host': 'localhost'
                    },
                    'vosk_stt': {
                        'enabled': True,
                        'internal_host': 'vosk-stt',
                        'external_host': 'localhost'
                    },
                    'haproxy': {
                        'enabled': True,
                        'image': 'haproxy:2.8-alpine',
                        'internal_host': 'haproxy',
                        'external_host': 'localhost'
                    }
                },
                'urls': {
                    'docker': {
                        'livekit': 'ws://livekit-server:7880',
                        'agent': 'http://livekit-agent:8080',
                        'redis': 'redis://eloquence-redis:6379',
                        'mistral': 'http://mistral-conversation:8001/v1/chat/completions',
                        'vosk': 'http://vosk-stt:8002'
                    },
                    'external': {
                        'livekit': 'ws://localhost:7880',
                        'agent': 'http://localhost:8080',
                        'redis': 'redis://localhost:6379',
                        'mistral': 'http://localhost:8001/v1/chat/completions',
                        'vosk': 'http://localhost:8002'
                    }
                },
                'security': {
                    'livekit': {
                        'api_key': 'testkey',
                        'api_secret': 'testsecret123456789abcdef0123456789abcdef'
                    }
                },
                'multi_agent': {
                    'enabled': True,
                    'instances': 2,
                    'ports': {
                        'agent_1': 8011,
                        'agent_2': 8012
                    },
                    'metrics_ports': {
                        'agent_1': 9091,
                        'agent_2': 9092
                    }
                }
            }
        }
        
        # Écrire la configuration de test
        self.config_file = self.config_dir / "eloquence.config.yaml"
        with open(self.config_file, 'w', encoding='utf-8') as f:
            yaml.dump(self.test_config, f, default_flow_style=False)
        
        # Changer vers le répertoire de test
        self.original_cwd = os.getcwd()
        os.chdir(self.test_dir)
    
    def tearDown(self):
        """Nettoyage après les tests"""
        # Restaurer le répertoire de travail original
        os.chdir(self.original_cwd)
        
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.test_dir)
    
    def test_config_loader(self):
        """Test du chargeur de configuration"""
        loader = ConfigLoader()
        
        # Vérifier que la configuration est chargée
        self.assertIsNotNone(loader._config)
        self.assertEqual(loader._config['version'], '1.0.0')
        self.assertEqual(loader._config['environment'], 'test')
        
        # Vérifier les ports
        self.assertEqual(loader.get_port('livekit_server'), 7880)
        self.assertEqual(loader.get_port('redis'), 6379)
        
        # Vérifier les URLs
        self.assertEqual(loader.get_docker_url('livekit'), 'ws://livekit-server:7880')
        self.assertEqual(loader.get_external_url('livekit'), 'ws://localhost:7880')
        
        # Vérifier les credentials
        credentials = loader.get_livekit_credentials()
        self.assertEqual(credentials['api_key'], 'testkey')
        self.assertEqual(credentials['api_secret'], 'testsecret123456789abcdef0123456789abcdef')
    
    def test_config_validator(self):
        """Test du validateur de configuration"""
        validator = ConfigValidator(str(self.config_file))
        
        # Valider la configuration
        is_valid, errors, warnings = validator.validate_all()
        
        # La configuration de test doit être valide
        self.assertTrue(is_valid)
        self.assertEqual(len(errors), 0)
        
        # Vérifier que les sections principales sont présentes
        self.assertIn('network', validator.config)
        self.assertIn('services', validator.config)
        self.assertIn('urls', validator.config)
        self.assertIn('security', validator.config)
    
    def test_config_generator(self):
        """Test du générateur de configuration"""
        generator = ConfigGenerator()
        
        # Générer tous les fichiers
        generator.generate_all_files()
        
        # Vérifier que les fichiers ont été créés
        docker_compose_file = self.test_dir / "docker-compose.yml"
        env_file = self.test_dir / ".env"
        livekit_file = self.test_dir / "livekit.yaml"
        
        self.assertTrue(docker_compose_file.exists())
        self.assertTrue(env_file.exists())
        self.assertTrue(livekit_file.exists())
        
        # Vérifier le contenu du docker-compose.yml
        with open(docker_compose_file, 'r', encoding='utf-8') as f:
            docker_compose_content = yaml.safe_load(f)
        
        self.assertIn('services', docker_compose_content)
        self.assertIn('eloquence-redis', docker_compose_content['services'])
        self.assertIn('livekit-server', docker_compose_content['services'])
        
        # Vérifier le contenu du .env
        with open(env_file, 'r', encoding='utf-8') as f:
            env_content = f.read()
        
        self.assertIn('LIVEKIT_URL=ws://localhost:7880', env_content)
        self.assertIn('LIVEKIT_API_KEY=testkey', env_content)
        
        # Vérifier le contenu du livekit.yaml
        with open(livekit_file, 'r', encoding='utf-8') as f:
            livekit_content = yaml.safe_load(f)
        
        self.assertEqual(livekit_content['port'], 7880)
        self.assertEqual(livekit_content['rtc']['tcp_port'], 7881)
    
    def test_config_manager(self):
        """Test du gestionnaire de configuration"""
        manager = ConfigManager()
        
        # Vérifier le résumé de la configuration
        summary = manager.get_config_summary()
        self.assertEqual(summary['version'], '1.0.0')
        self.assertEqual(summary['environment'], 'test')
        self.assertEqual(summary['network']['ports_count'], 8)
        self.assertEqual(summary['services']['enabled'], 6)
        self.assertEqual(summary['services']['total'], 6)
        self.assertTrue(summary['multi_agent']['enabled'])
        self.assertEqual(summary['multi_agent']['instances'], 2)
        
        # Vérifier la validation
        is_valid, errors, warnings = manager.validate_configuration()
        self.assertTrue(is_valid)
        
        # Vérifier la génération des fichiers
        results = manager.generate_config_files()
        self.assertTrue(all(results.values()))
        
        # Vérifier les informations réseau
        network_info = manager.get_network_info()
        self.assertEqual(network_info['domain'], 'localhost')
        self.assertEqual(len(network_info['ports']), 8)
        self.assertEqual(network_info['rtc_range']['start'], 40000)
        self.assertEqual(network_info['rtc_range']['end'], 40100)
    
    def test_config_client(self):
        """Test du client de configuration"""
        # Vérifier la configuration LiveKit
        livekit_config = get_livekit_config()
        self.assertEqual(livekit_config['url'], 'ws://livekit-server:7880')
        self.assertEqual(livekit_config['api_key'], 'testkey')
        self.assertEqual(livekit_config['api_secret'], 'testsecret123456789abcdef0123456789abcdef')
        
        # Vérifier les URLs des services
        services_urls = get_services_urls()
        self.assertEqual(services_urls['livekit'], 'ws://livekit-server:7880')
        self.assertEqual(services_urls['redis'], 'redis://eloquence-redis:6379')
        self.assertEqual(services_urls['mistral'], 'http://mistral-conversation:8001/v1/chat/completions')
        self.assertEqual(services_urls['vosk'], 'http://vosk-stt:8002')
    
    def test_config_update(self):
        """Test de la mise à jour de configuration"""
        manager = ConfigManager()
        
        # Mettre à jour un port
        success = manager.update_config_value('network.ports.redis', 6380)
        self.assertTrue(success)
        
        # Vérifier que la valeur a été mise à jour
        updated_port = manager.config_loader.get_port('redis')
        self.assertEqual(updated_port, 6380)
        
        # Mettre à jour un service
        success = manager.update_config_value('services.redis.enabled', False)
        self.assertTrue(success)
        
        # Vérifier que le service a été désactivé
        redis_service = manager.config['services']['redis']
        self.assertFalse(redis_service['enabled'])
    
    def test_config_backup_restore(self):
        """Test de la sauvegarde et restauration"""
        manager = ConfigManager()
        
        # Créer une sauvegarde
        backup_path = manager.backup_configuration()
        self.assertTrue(backup_path.exists())
        
        # Modifier la configuration
        manager.update_config_value('network.ports.redis', 6380)
        
        # Restaurer la configuration
        success = manager.restore_configuration(str(backup_path))
        self.assertTrue(success)
        
        # Vérifier que la valeur a été restaurée
        restored_port = manager.config_loader.get_port('redis')
        self.assertEqual(restored_port, 6379)
    
    def test_config_schema_export(self):
        """Test de l'export du schéma de configuration"""
        manager = ConfigManager()
        
        # Exporter le schéma
        schema = manager.export_config_schema()
        
        # Vérifier la structure du schéma
        self.assertEqual(schema['version'], '1.0.0')
        self.assertEqual(schema['description'], 'Schéma de configuration Eloquence')
        self.assertIn('structure', schema)
        self.assertIn('required_fields', schema)
        self.assertIn('examples', schema)
        
        # Vérifier que les champs requis sont présents
        required_fields = schema['required_fields']
        self.assertIn('network.ports.livekit_server', required_fields)
        self.assertIn('network.ports.redis', required_fields)
        self.assertIn('security.livekit.api_key', required_fields)
    
    def test_error_handling(self):
        """Test de la gestion des erreurs"""
        # Test avec un fichier de configuration invalide
        invalid_config = {'invalid': 'config'}
        invalid_config_file = self.config_dir / "invalid.config.yaml"
        
        with open(invalid_config_file, 'w', encoding='utf-8') as f:
            yaml.dump(invalid_config, f)
        
        # Le validateur doit détecter l'erreur
        validator = ConfigValidator(str(invalid_config_file))
        is_valid, errors, warnings = validator.validate_all()
        self.assertFalse(is_valid)
        self.assertGreater(len(errors), 0)
    
    def test_multi_agent_config(self):
        """Test de la configuration multi-agents"""
        manager = ConfigManager()
        
        # Vérifier la configuration multi-agents
        multi_agent_config = manager.config_loader.get_multi_agent_config()
        self.assertTrue(multi_agent_config['enabled'])
        self.assertEqual(multi_agent_config['instances'], 2)
        
        # Vérifier les ports des agents
        self.assertEqual(multi_agent_config['ports']['agent_1'], 8011)
        self.assertEqual(multi_agent_config['ports']['agent_2'], 8012)
        
        # Vérifier les ports de métriques
        self.assertEqual(multi_agent_config['metrics_ports']['agent_1'], 9091)
        self.assertEqual(multi_agent_config['metrics_ports']['agent_2'], 9092)

def run_tests():
    """Lance tous les tests"""
    print("🧪 Lancement des tests du système de configuration...")
    
    # Créer la suite de tests
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestConfigSystem)
    
    # Lancer les tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Afficher le résumé
    print(f"\n📊 RÉSULTATS DES TESTS:")
    print(f"   Tests exécutés: {result.testsRun}")
    print(f"   Échecs: {len(result.failures)}")
    print(f"   Erreurs: {len(result.errors)}")
    
    if result.failures:
        print(f"\n❌ ÉCHECS:")
        for test, traceback in result.failures:
            print(f"   {test}: {traceback}")
    
    if result.errors:
        print(f"\n🚨 ERREURS:")
        for test, traceback in result.errors:
            print(f"   {test}: {traceback}")
    
    return result.wasSuccessful()

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
