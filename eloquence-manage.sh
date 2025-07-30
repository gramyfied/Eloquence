#!/bin/bash
# ================================================================
# SCRIPT DE GESTION ELOQUENCE
# ================================================================
# Script pour gérer facilement l'application Eloquence
# ================================================================

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Déterminer le fichier docker-compose à utiliser
COMPOSE_FILE="docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    COMPOSE_FILE="docker-compose-new.yml"
fi

# Fonction d'aide
show_help() {
    echo "🎙️ ELOQUENCE - Gestionnaire d'Application"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [COMMANDE]"
    echo ""
    echo "Commandes disponibles:"
    echo "  start     - Démarrer tous les services"
    echo "  stop      - Arrêter tous les services"
    echo "  restart   - Redémarrer tous les services"
    echo "  status    - Afficher l'état des services"
    echo "  logs      - Afficher les logs en temps réel"
    echo "  logs [service] - Afficher les logs d'un service spécifique"
    echo "  health    - Vérifier la santé des services"
    echo "  build     - Reconstruire les images Docker"
    echo "  clean     - Nettoyer les conteneurs et images inutilisés"
    echo "  update    - Mettre à jour l'application"
    echo "  backup    - Créer une sauvegarde"
    echo "  help      - Afficher cette aide"
    echo ""
    echo "Services disponibles:"
    echo "  - eloquence-api (port 8080)"
    echo "  - vosk-stt (port 8002)"
    echo "  - mistral (port 8001)"
    echo "  - livekit (port 7880)"
    echo "  - redis (port 6379)"
    echo ""
    echo "URLs d'accès:"
    echo "  🌍 API Health: http://localhost:8080/health"
    echo "  📊 API Docs: http://localhost:8080/docs"
    echo "  🎤 Vosk STT: http://localhost:8002/health"
    echo "  🤖 Mistral IA: http://localhost:8001/health"
    echo "  🔴 LiveKit: http://localhost:7880/"
}

# Démarrer les services
start_services() {
    log_info "Démarrage des services Eloquence..."
    sudo docker compose -f $COMPOSE_FILE up -d
    log_success "Services démarrés avec succès !"
    echo ""
    show_status
}

# Arrêter les services
stop_services() {
    log_info "Arrêt des services Eloquence..."
    sudo docker compose -f $COMPOSE_FILE down
    log_success "Services arrêtés avec succès !"
}

# Redémarrer les services
restart_services() {
    log_info "Redémarrage des services Eloquence..."
    sudo docker compose -f $COMPOSE_FILE down
    sudo docker compose -f $COMPOSE_FILE up -d
    log_success "Services redémarrés avec succès !"
    echo ""
    show_status
}

# Afficher l'état des services
show_status() {
    log_info "État des services Eloquence:"
    echo ""
    sudo docker ps --filter "name=settings-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Afficher les logs
show_logs() {
    if [ -z "$1" ]; then
        log_info "Affichage des logs de tous les services..."
        sudo docker compose -f $COMPOSE_FILE logs -f
    else
        log_info "Affichage des logs du service: $1"
        sudo docker compose -f $COMPOSE_FILE logs -f "$1"
    fi
}

# Vérifier la santé des services
check_health() {
    log_info "Vérification de la santé des services..."
    echo ""
    
    # Test API principale
    if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
        log_success "✅ API Eloquence (port 8080): Opérationnelle"
    else
        log_error "❌ API Eloquence (port 8080): Non accessible"
    fi
    
    # Test Vosk STT
    if curl -f -s http://localhost:8002/health > /dev/null 2>&1; then
        log_success "✅ Vosk STT (port 8002): Opérationnel"
    else
        log_warning "⚠️ Vosk STT (port 8002): Non accessible"
    fi
    
    # Test Mistral
    if curl -f -s http://localhost:8001/health > /dev/null 2>&1; then
        log_success "✅ Mistral IA (port 8001): Opérationnel"
    else
        log_warning "⚠️ Mistral IA (port 8001): Non accessible (clés API requises)"
    fi
    
    # Test LiveKit
    if curl -f -s http://localhost:7880/ > /dev/null 2>&1; then
        log_success "✅ LiveKit (port 7880): Opérationnel"
    else
        log_warning "⚠️ LiveKit (port 7880): Non accessible"
    fi
    
    # Test Redis
    if sudo docker exec settings-redis-1 redis-cli ping 2>/dev/null | grep -q PONG; then
        log_success "✅ Redis (port 6379): Opérationnel"
    else
        log_warning "⚠️ Redis (port 6379): Non accessible"
    fi
    
    echo ""
    log_info "💡 Pour configurer les clés API, éditez le fichier .env"
}

# Reconstruire les images
build_images() {
    log_info "Reconstruction des images Docker..."
    sudo docker compose -f $COMPOSE_FILE build --no-cache
    log_success "Images reconstruites avec succès !"
}

# Nettoyer Docker
clean_docker() {
    log_info "Nettoyage des conteneurs et images inutilisés..."
    sudo docker system prune -f
    log_success "Nettoyage terminé !"
}

# Mettre à jour l'application
update_app() {
    log_info "Mise à jour de l'application Eloquence..."
    
    # Arrêter les services
    sudo docker compose -f $COMPOSE_FILE down
    
    # Reconstruire les images
    sudo docker compose -f $COMPOSE_FILE build --no-cache
    
    # Redémarrer les services
    sudo docker compose -f $COMPOSE_FILE up -d
    
    log_success "Mise à jour terminée !"
    echo ""
    show_status
}

# Créer une sauvegarde
create_backup() {
    BACKUP_DIR="./backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    log_info "Création d'une sauvegarde..."
    
    mkdir -p $BACKUP_DIR
    
    # Sauvegarder la configuration
    tar -czf "$BACKUP_DIR/eloquence_config_$DATE.tar.gz" .env $COMPOSE_FILE
    
    # Sauvegarder Redis si possible
    if sudo docker ps | grep -q settings-redis-1; then
        sudo docker exec settings-redis-1 redis-cli BGSAVE
        sleep 2
        sudo docker cp settings-redis-1:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"
    fi
    
    log_success "Sauvegarde créée: $BACKUP_DIR/eloquence_config_$DATE.tar.gz"
}

# Fonction principale
main() {
    case "${1:-help}" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        health)
            check_health
            ;;
        build)
            build_images
            ;;
        clean)
            clean_docker
            ;;
        update)
            update_app
            ;;
        backup)
            create_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Commande inconnue: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Exécution
main "$@"
