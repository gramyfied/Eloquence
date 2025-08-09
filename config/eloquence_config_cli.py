#!/usr/bin/env python3
"""
Interface en ligne de commande pour la gestion de configuration Eloquence
Permet de valider, générer, sauvegarder et restaurer la configuration
"""
import argparse
import sys
import json
from pathlib import Path
from typing import Dict, Any

# Ajouter le répertoire config au path
config_dir = Path(__file__).parent
if str(config_dir) not in sys.path:
    sys.path.insert(0, str(config_dir))

from config_manager import get_config_manager, validate_and_generate
from config_loader import EloquenceConfigError

def print_banner():
    """Affiche la bannière du CLI"""
    print("""
╔══════════════════════════════════════════════════════════════╗
║                    🎯 ELOQUENCE CONFIG CLI                  ║
║              Gestionnaire de Configuration Unifié           ║
╚══════════════════════════════════════════════════════════════╝
""")

def print_status(status: Dict[str, Any]):
    """Affiche le statut des services de manière formatée"""
    print("\n🔍 STATUT DES SERVICES:")
    print("=" * 50)
    
    for service_name, service_status in status.items():
        if service_name == "error":
            print(f"❌ ERREUR: {service_status}")
            continue
            
        status_icon = "🟢" if service_status.get("status") == "running" else "🔴"
        status_text = service_status.get("status", "unknown")
        details = service_status.get("details", "")
        
        print(f"{status_icon} {service_name}: {status_text}")
        if details:
            print(f"    └─ {details}")
    
    print()

def print_config_summary(summary: Dict[str, Any]):
    """Affiche un résumé de la configuration"""
    print("\n📊 RÉSUMÉ DE LA CONFIGURATION:")
    print("=" * 50)
    
    print(f"📋 Version: {summary['version']}")
    print(f"🌍 Environnement: {summary['environment']}")
    print(f"🌐 Domaine: {summary['network']['domain']}")
    print(f"🔌 Ports configurés: {summary['network']['ports_count']}")
    print(f"📡 Plage RTC: {summary['network']['rtc_range']['start']}-{summary['network']['rtc_range']['end']}")
    print(f"⚙️ Services actifs: {summary['services']['enabled']}/{summary['services']['total']}")
    
    if summary['multi_agent']['enabled']:
        print(f"🤖 Multi-agents: {summary['multi_agent']['instances']} instances")
    else:
        print("🤖 Multi-agents: Désactivé")
    
    print()

def command_status(args):
    """Commande: afficher le statut des services"""
    try:
        manager = get_config_manager()
        
        print("🔍 Vérification du statut des services...")
        status = manager.check_service_status()
        
        print_status(status)
        
    except Exception as e:
        print(f"❌ Erreur lors de la vérification du statut: {e}")
        sys.exit(1)

def command_summary(args):
    """Commande: afficher un résumé de la configuration"""
    try:
        manager = get_config_manager()
        summary = manager.get_config_summary()
        
        print_config_summary(summary)
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération du résumé: {e}")
        sys.exit(1)

def command_validate(args):
    """Commande: valider la configuration"""
    try:
        manager = get_config_manager()
        
        print("🔍 Validation de la configuration...")
        is_valid, errors, warnings = manager.validate_configuration()
        
        if is_valid:
            print("✅ Configuration valide!")
        else:
            print("❌ Configuration invalide!")
            
        if errors:
            print(f"\n🚨 ERREURS ({len(errors)}):")
            for error in errors:
                print(f"   {error}")
        
        if warnings:
            print(f"\n⚠️ AVERTISSEMENTS ({len(warnings)}):")
            for warning in warnings:
                print(f"   {warning}")
        
        if not errors and not warnings:
            print("\n🎉 Aucun problème détecté!")
        
        return is_valid
        
    except Exception as e:
        print(f"❌ Erreur lors de la validation: {e}")
        sys.exit(1)

def command_generate(args):
    """Commande: générer les fichiers de configuration"""
    try:
        manager = get_config_manager()
        
        if args.force:
            print("🔄 Génération forcée des fichiers de configuration...")
        else:
            print("🔄 Génération des fichiers de configuration...")
        
        results = manager.generate_config_files(force=args.force)
        
        print("\n📁 RÉSULTATS DE LA GÉNÉRATION:")
        print("=" * 40)
        
        for file_name, success in results.items():
            status = "✅" if success else "❌"
            print(f"{status} {file_name}")
        
        if all(results.values()):
            print("\n🎉 Tous les fichiers ont été générés avec succès!")
        else:
            print("\n⚠️ Certains fichiers n'ont pas pu être générés")
            sys.exit(1)
        
    except Exception as e:
        print(f"❌ Erreur lors de la génération: {e}")
        sys.exit(1)

def command_backup(args):
    """Commande: créer une sauvegarde de la configuration"""
    try:
        manager = get_config_manager()
        
        print("💾 Création d'une sauvegarde de configuration...")
        backup_path = manager.backup_configuration()
        
        print(f"✅ Sauvegarde créée: {backup_path}")
        
        if args.info:
            print(f"\n📁 Contenu de la sauvegarde:")
            for file_path in backup_path.iterdir():
                if file_path.is_file():
                    print(f"   📄 {file_path.name}")
        
    except Exception as e:
        print(f"❌ Erreur lors de la sauvegarde: {e}")
        sys.exit(1)

def command_restore(args):
    """Commande: restaurer une configuration depuis une sauvegarde"""
    try:
        manager = get_config_manager()
        
        if not args.backup_path:
            print("❌ Chemin de sauvegarde requis (--backup-path)")
            sys.exit(1)
        
        print(f"🔄 Restauration depuis: {args.backup_path}")
        
        # Demander confirmation
        if not args.force:
            response = input("⚠️ Cette opération va remplacer la configuration actuelle. Continuer? (y/N): ")
            if response.lower() != 'y':
                print("❌ Restauration annulée")
                return
        
        success = manager.restore_configuration(args.backup_path)
        
        if success:
            print("✅ Configuration restaurée avec succès!")
        else:
            print("❌ Échec de la restauration")
            sys.exit(1)
        
    except Exception as e:
        print(f"❌ Erreur lors de la restauration: {e}")
        sys.exit(1)

def command_update(args):
    """Commande: mettre à jour une valeur de configuration"""
    try:
        manager = get_config_manager()
        
        if not args.path or not args.value:
            print("❌ Chemin et valeur requis (--path et --value)")
            sys.exit(1)
        
        print(f"🔄 Mise à jour: {args.path} = {args.value}")
        
        # Convertir la valeur si nécessaire
        if args.value.lower() in ['true', 'false']:
            value = args.value.lower() == 'true'
        elif args.value.isdigit():
            value = int(args.value)
        else:
            value = args.value
        
        success = manager.update_config_value(args.path, value)
        
        if success:
            print("✅ Configuration mise à jour avec succès!")
        else:
            print("❌ Échec de la mise à jour")
            sys.exit(1)
        
    except Exception as e:
        print(f"❌ Erreur lors de la mise à jour: {e}")
        sys.exit(1)

def command_schema(args):
    """Commande: exporter le schéma de configuration"""
    try:
        manager = get_config_manager()
        
        print("📋 Export du schéma de configuration...")
        schema = manager.export_config_schema()
        
        if args.output:
            output_path = Path(args.output)
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(schema, f, indent=2, ensure_ascii=False)
            print(f"✅ Schéma exporté vers: {output_path}")
        else:
            print(json.dumps(schema, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"❌ Erreur lors de l'export du schéma: {e}")
        sys.exit(1)

def command_network(args):
    """Commande: afficher les informations réseau"""
    try:
        manager = get_config_manager()
        
        print("🌐 INFORMATIONS RÉSEAU:")
        print("=" * 40)
        
        network_info = manager.get_network_info()
        
        print(f"🌍 Domaine: {network_info['domain']}")
        print(f"🔌 Réseau Docker: {network_info['docker_network']}")
        
        print(f"\n🔌 PORTS:")
        for service, port in network_info['ports'].items():
            print(f"   {service}: {port}")
        
        rtc_range = network_info['rtc_range']
        print(f"\n📡 Plage RTC: {rtc_range['start']}-{rtc_range['end']}")
        
        print(f"\n🐳 URLs Docker:")
        for service, url in network_info['urls']['docker'].items():
            print(f"   {service}: {url}")
        
        print(f"\n🌐 URLs Externes:")
        for service, url in network_info['urls']['external'].items():
            print(f"   {service}: {url}")
        
        print()
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des informations réseau: {e}")
        sys.exit(1)

def command_auto(args):
    """Commande: validation et génération automatiques"""
    try:
        print("🚀 Validation et génération automatiques...")
        
        success = validate_and_generate()
        
        if success:
            print("🎉 Configuration validée et générée avec succès!")
        else:
            print("❌ Échec de la validation/génération")
            sys.exit(1)
        
    except Exception as e:
        print(f"❌ Erreur lors de l'opération automatique: {e}")
        sys.exit(1)

def main():
    """Fonction principale du CLI"""
    parser = argparse.ArgumentParser(
        description="Gestionnaire de configuration Eloquence",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
EXEMPLES:
  # Vérifier le statut des services
  python eloquence_config_cli.py status
  
  # Valider la configuration
  python eloquence_config_cli.py validate
  
  # Générer les fichiers de configuration
  python eloquence_config_cli.py generate
  
  # Validation et génération automatiques
  python eloquence_config_cli.py auto
  
  # Créer une sauvegarde
  python eloquence_config_cli.py backup
  
  # Restaurer depuis une sauvegarde
  python eloquence_config_cli.py restore --backup-path ./config_backup/backup_20241201_120000
  
  # Mettre à jour une valeur
  python eloquence_config_cli.py update --path network.ports.redis --value 6380
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commandes disponibles')
    
    # Commande status
    status_parser = subparsers.add_parser('status', help='Afficher le statut des services')
    
    # Commande summary
    summary_parser = subparsers.add_parser('summary', help='Afficher un résumé de la configuration')
    
    # Commande validate
    validate_parser = subparsers.add_parser('validate', help='Valider la configuration')
    
    # Commande generate
    generate_parser = subparsers.add_parser('generate', help='Générer les fichiers de configuration')
    generate_parser.add_argument('--force', action='store_true', help='Forcer la régénération')
    
    # Commande backup
    backup_parser = subparsers.add_parser('backup', help='Créer une sauvegarde de la configuration')
    backup_parser.add_argument('--info', action='store_true', help='Afficher les informations de la sauvegarde')
    
    # Commande restore
    restore_parser = subparsers.add_parser('restore', help='Restaurer une configuration depuis une sauvegarde')
    restore_parser.add_argument('--backup-path', required=True, help='Chemin vers la sauvegarde')
    restore_parser.add_argument('--force', action='store_true', help='Forcer la restauration sans confirmation')
    
    # Commande update
    update_parser = subparsers.add_parser('update', help='Mettre à jour une valeur de configuration')
    update_parser.add_argument('--path', required=True, help='Chemin de la valeur (ex: network.ports.redis)')
    update_parser.add_argument('--value', required=True, help='Nouvelle valeur')
    
    # Commande schema
    schema_parser = subparsers.add_parser('schema', help='Exporter le schéma de configuration')
    schema_parser.add_argument('--output', help='Fichier de sortie (JSON)')
    
    # Commande network
    network_parser = subparsers.add_parser('network', help='Afficher les informations réseau')
    
    # Commande auto
    auto_parser = subparsers.add_parser('auto', help='Validation et génération automatiques')
    
    args = parser.parse_args()
    
    if not args.command:
        print_banner()
        parser.print_help()
        return
    
    # Exécuter la commande appropriée
    try:
        if args.command == 'status':
            command_status(args)
        elif args.command == 'summary':
            command_summary(args)
        elif args.command == 'validate':
            command_validate(args)
        elif args.command == 'generate':
            command_generate(args)
        elif args.command == 'backup':
            command_backup(args)
        elif args.command == 'restore':
            command_restore(args)
        elif args.command == 'update':
            command_update(args)
        elif args.command == 'schema':
            command_schema(args)
        elif args.command == 'network':
            command_network(args)
        elif args.command == 'auto':
            command_auto(args)
        else:
            print(f"❌ Commande inconnue: {args.command}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n❌ Opération annulée par l'utilisateur")
        sys.exit(1)
    except EloquenceConfigError as e:
        print(f"❌ Erreur de configuration: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erreur inattendue: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
