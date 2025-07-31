#!/bin/bash
# ================================================================
# SCRIPT DE MONITORING ET RÉCUPÉRATION AUTOMATIQUE ELOQUENCE
# ================================================================
# Surveille les services et les redémarre automatiquement si nécessaire
# ================================================================

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/monitor.log"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ALERT_EMAIL=""  # Configurer si nécessaire
SLACK_WEBHOOK=""  # Configurer si nécessaire

# Créer le dossier de logs s'il n'existe pas
mkdir -p "$PROJECT_DIR/logs"

# Fonction de logging
log_with_timestamp() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log_with_timestamp "${BLUE}INFO${NC}" "$1"
}

log_success() {
    log_with_timestamp "${GREEN}SUCCESS${NC}" "$1"
}

log_warning() {
    log_with_timestamp "${YELLOW}WARNING${NC}" "$1"
}

log_error() {
    log_with_timestamp "${RED}ERROR${NC}" "$1"
}

log_critical() {
    log_with_timestamp "${PURPLE}CRITICAL${NC}" "$1"
}

# Services à surveiller avec leurs ports et endpoints
declare -A SERVICES=(
    ["backend-api"]="8000:/health"
    ["eloquence-exercises-api"]="8005:/health"
    ["vosk-stt"]="8002:/health"
    ["mistral-conversation"]="8001:/health"
    ["livekit-server"]="7880:/"
    ["livekit-token-service"]="8004:/health"
    ["redis"]="6379:ping"
)

# Fonction pour vérifier la santé d'un service HTTP
check_http_service() {
    local service_name=$1
    local port=$2
    local endpoint=$3
    local url="http://localhost:${port}${endpoint}"
    
    if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier Redis
check_redis_service() {
    if sudo docker exec settings-redis-1 redis-cli ping 2>/dev/null | grep -q PONG; then
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier un service
check_service() {
    local service_name=$1
    local port_endpoint=$2
    local port=$(echo "$port_endpoint" | cut -d':' -f1)
    local endpoint=$(echo "$port_endpoint" | cut -d':' -f2)
    
    if [ "$service_name" = "redis" ]; then
        check_redis_service
    else
        check_http_service "$service_name" "$port" "$endpoint"
    fi
}

# Fonction pour redémarrer un service
restart_service() {
    local service_name=$1
    log_warning "Redémarrage du service: $service_name"
    
    cd "$PROJECT_DIR"
    if sudo docker compose -f "$COMPOSE_FILE" restart "$service_name"; then
        log_success "Service $service_name redémarré avec succès"
        sleep 30  # Attendre que le service soit complètement démarré
        return 0
    else
        log_error "Échec du redémarrage du service $service_name"
        return 1
    fi
}

# Fonction pour vérifier l'état des conteneurs Docker
check_container_status() {
    local service_name=$1
    local container_name="settings-${service_name}-1"
    
    if sudo docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        return 0
    else
        return 1
    fi
}

# Fonction pour envoyer une alerte
send_alert() {
    local message=$1
    local severity=$2
    
    # Log local
    if [ "$severity" = "critical" ]; then
        log_critical "$message"
    else
        log_error "$message"
    fi
    
    # Email (si configuré)
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Eloquence Alert: $severity" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Slack (si configuré)
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Eloquence Alert: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Fonction pour vérifier et récupérer un service
monitor_and_recover_service() {
    local service_name=$1
    local port_endpoint=$2
    local max_retries=3
    local retry_count=0
    
    log_info "Vérification du service: $service_name"
    
    # Vérifier si le conteneur est en cours d'exécution
    if ! check_container_status "$service_name"; then
        log_error "Conteneur $service_name n'est pas en cours d'exécution"
        send_alert "Conteneur $service_name arrêté" "critical"
        restart_service "$service_name"
        return
    fi
    
    # Vérifier la santé du service
    while [ $retry_count -lt $max_retries ]; do
        if check_service "$service_name" "$port_endpoint"; then
            log_success "Service $service_name: OK"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_warning "Service $service_name non accessible (tentative $retry_count/$max_retries)"
            sleep 5
        fi
    done
    
    # Service non accessible après plusieurs tentatives
    log_error "Service $service_name non accessible après $max_retries tentatives"
    send_alert "Service $service_name non accessible" "critical"
    
    # Tentative de redémarrage
    if restart_service "$service_name"; then
        # Vérifier après redémarrage
        sleep 30
        if check_service "$service_name" "$port_endpoint"; then
            log_success "Service $service_name récupéré après redémarrage"
            send_alert "Service $service_name récupéré" "info"
        else
            log_critical "Service $service_name toujours non accessible après redémarrage"
            send_alert "CRITIQUE: Service $service_name ne répond pas après redémarrage" "critical"
        fi
    fi
}

# Fonction pour vérifier l'utilisation des ressources
check_system_resources() {
    log_info "Vérification des ressources système"
    
    # Vérifier l'utilisation du disque
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 85 ]; then
        log_warning "Utilisation du disque élevée: ${disk_usage}%"
        send_alert "Utilisation du disque élevée: ${disk_usage}%" "warning"
    fi
    
    # Vérifier l'utilisation de la mémoire
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt 85 ]; then
        log_warning "Utilisation de la mémoire élevée: ${mem_usage}%"
        send_alert "Utilisation de la mémoire élevée: ${mem_usage}%" "warning"
    fi
    
    # Vérifier la charge système
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    local load_threshold=$((cpu_cores * 2))
    
    if (( $(echo "$load_avg > $load_threshold" | bc -l) )); then
        log_warning "Charge système élevée: $load_avg (seuil: $load_threshold)"
        send_alert "Charge système élevée: $load_avg" "warning"
    fi
}

# Fonction pour nettoyer les logs anciens
cleanup_logs() {
    log_info "Nettoyage des logs anciens"
    
    # Garder seulement les logs des 7 derniers jours
    find "$PROJECT_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Nettoyer les logs Docker
    sudo docker system prune -f --filter "until=168h" 2>/dev/null || true
}

# Fonction pour sauvegarder les données critiques
backup_critical_data() {
    local backup_dir="$PROJECT_DIR/backups/auto"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    log_info "Sauvegarde automatique des données critiques"
    
    # Sauvegarder Redis
    if check_container_status "redis"; then
        sudo docker exec settings-redis-1 redis-cli BGSAVE 2>/dev/null || true
        sleep 5
        sudo docker cp settings-redis-1:/data/dump.rdb "$backup_dir/redis_${timestamp}.rdb" 2>/dev/null || true
    fi
    
    # Sauvegarder la configuration
    tar -czf "$backup_dir/config_${timestamp}.tar.gz" \
        "$PROJECT_DIR/.env" \
        "$PROJECT_DIR/docker-compose.yml" \
        "$PROJECT_DIR/redis.conf" 2>/dev/null || true
    
    # Nettoyer les anciennes sauvegardes (garder 3 jours)
    find "$backup_dir" -name "*.rdb" -mtime +3 -delete 2>/dev/null || true
    find "$backup_dir" -name "*.tar.gz" -mtime +3 -delete 2>/dev/null || true
}

# Fonction principale de monitoring
main_monitoring_loop() {
    log_info "Démarrage du monitoring Eloquence"
    
    while true; do
        log_info "=== Cycle de monitoring $(date) ==="
        
        # Vérifier chaque service
        for service_name in "${!SERVICES[@]}"; do
            monitor_and_recover_service "$service_name" "${SERVICES[$service_name]}"
        done
        
        # Vérifier les ressources système
        check_system_resources
        
        # Nettoyage périodique (une fois par jour)
        local hour=$(date +%H)
        if [ "$hour" = "02" ]; then
            cleanup_logs
            backup_critical_data
        fi
        
        log_info "Cycle de monitoring terminé. Attente de 60 secondes..."
        sleep 60
    done
}

# Fonction pour un check unique (mode one-shot)
single_check() {
    log_info "Vérification unique de tous les services"
    
    local all_healthy=true
    
    for service_name in "${!SERVICES[@]}"; do
        if check_service "$service_name" "${SERVICES[$service_name]}"; then
            log_success "✅ $service_name: OK"
        else
            log_error "❌ $service_name: ÉCHEC"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        log_success "🎉 Tous les services sont opérationnels"
        exit 0
    else
        log_error "⚠️ Certains services ont des problèmes"
        exit 1
    fi
}

# Fonction d'aide
show_help() {
    echo "🔍 ELOQUENCE - Monitoring et Récupération Automatique"
    echo "====================================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --monitor     Démarrer le monitoring continu (défaut)"
    echo "  --check       Effectuer une vérification unique"
    echo "  --help        Afficher cette aide"
    echo ""
    echo "Services surveillés:"
    for service_name in "${!SERVICES[@]}"; do
        echo "  - $service_name"
    done
    echo ""
    echo "Logs: $LOG_FILE"
}

# Point d'entrée principal
case "${1:-monitor}" in
    --monitor|monitor)
        main_monitoring_loop
        ;;
    --check|check)
        single_check
        ;;
    --help|help|-h)
        show_help
        ;;
    *)
        echo "Option inconnue: $1"
        show_help
        exit 1
        ;;
esac
