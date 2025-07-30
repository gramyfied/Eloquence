#!/bin/bash
# ================================================================
# SCRIPT DE DÉPLOIEMENT SÉCURISÉ ELOQUENCE
# ================================================================
# Déploiement production sécurisé sur Scaleway
# ================================================================

set -euo pipefail

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="/var/backups/eloquence"
LOG_FILE="/var/log/eloquence-deploy.log"

# ================================================================
# FONCTIONS UTILITAIRES
# ================================================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# ================================================================
# VÉRIFICATIONS PRÉALABLES
# ================================================================

check_prerequisites() {
    log "🔍 Vérification des prérequis..."
    
    # Vérifier que nous sommes root
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en tant que root"
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose n'est pas installé"
    fi
    
    # Vérifier l'espace disque (minimum 10GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then
        error "Espace disque insuffisant (minimum 10GB requis)"
    fi
    
    # Vérifier la RAM (minimum 4GB)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_ram -lt 4096 ]]; then
        warn "RAM insuffisante (minimum 4GB recommandé)"
    fi
    
    log "✅ Prérequis validés"
}

# ================================================================
# GÉNÉRATION DES SECRETS
# ================================================================

generate_secrets() {
    log "🔑 Génération des secrets sécurisés..."
    
    # Créer le répertoire des secrets
    mkdir -p "$PROJECT_ROOT/security/secrets"
    chmod 700 "$PROJECT_ROOT/security/secrets"
    
    # Générer les secrets
    openssl rand -hex 32 > "$PROJECT_ROOT/security/secrets/jwt_secret"
    openssl rand -hex 32 > "$PROJECT_ROOT/security/secrets/encryption_key"
    openssl rand -base64 32 > "$PROJECT_ROOT/security/secrets/redis_password"
    openssl rand -hex 64 > "$PROJECT_ROOT/security/secrets/livekit_secret"
    
    # Sécuriser les permissions
    chmod 600 "$PROJECT_ROOT/security/secrets/"*
    
    log "✅ Secrets générés et sécurisés"
}

# ================================================================
# CONFIGURATION SSL/TLS
# ================================================================

setup_ssl() {
    log "🔒 Configuration SSL/TLS..."
    
    # Créer le répertoire SSL
    mkdir -p "$PROJECT_ROOT/security/certs"
    chmod 755 "$PROJECT_ROOT/security/certs"
    
    # Vérifier si les certificats existent
    if [[ ! -f "$PROJECT_ROOT/security/certs/eloquence.crt" ]]; then
        warn "Certificats SSL non trouvés, génération d'un certificat auto-signé..."
        
        # Générer un certificat auto-signé pour le développement
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$PROJECT_ROOT/security/certs/eloquence.key" \
            -out "$PROJECT_ROOT/security/certs/eloquence.crt" \
            -subj "/C=FR/ST=France/L=Paris/O=Eloquence/CN=localhost"
        
        chmod 600 "$PROJECT_ROOT/security/certs/eloquence.key"
        chmod 644 "$PROJECT_ROOT/security/certs/eloquence.crt"
        
        warn "⚠️ Certificat auto-signé généré. Remplacez par un certificat valide en production!"
    fi
    
    log "✅ SSL/TLS configuré"
}

# ================================================================
# CONFIGURATION SYSTÈME
# ================================================================

configure_system() {
    log "⚙️ Configuration système sécurisée..."
    
    # Créer les répertoires de données
    mkdir -p /var/lib/eloquence/{redis,vosk-models,monitoring}
    chown -R 1000:1000 /var/lib/eloquence
    chmod -R 755 /var/lib/eloquence
    
    # Créer les répertoires de logs
    mkdir -p /var/log/eloquence
    chmod 755 /var/log/eloquence
    
    # Configuration des limites système
    cat > /etc/security/limits.d/eloquence.conf << EOF
# Limites pour Eloquence
eloquence soft nofile 65536
eloquence hard nofile 65536
eloquence soft nproc 4096
eloquence hard nproc 4096
EOF
    
    # Configuration sysctl pour la performance réseau
    cat > /etc/sysctl.d/99-eloquence.conf << EOF
# Configuration réseau pour Eloquence
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
EOF
    
    sysctl -p /etc/sysctl.d/99-eloquence.conf
    
    log "✅ Système configuré"
}

# ================================================================
# FIREWALL ET SÉCURITÉ RÉSEAU
# ================================================================

configure_firewall() {
    log "🛡️ Configuration du firewall..."
    
    # Installer UFW si nécessaire
    if ! command -v ufw &> /dev/null; then
        apt-get update && apt-get install -y ufw
    fi
    
    # Réinitialiser UFW
    ufw --force reset
    
    # Politique par défaut
    ufw default deny incoming
    ufw default allow outgoing
    
    # Autoriser SSH (attention à ne pas se bloquer)
    ufw allow ssh
    
    # Autoriser HTTP et HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Autoriser LiveKit UDP
    ufw allow 40000:40100/udp
    
    # Activer le firewall
    ufw --force enable
    
    log "✅ Firewall configuré"
}

# ================================================================
# SAUVEGARDE
# ================================================================

create_backup() {
    log "💾 Création de la sauvegarde..."
    
    # Créer le répertoire de sauvegarde
    mkdir -p "$BACKUP_DIR"
    
    # Timestamp pour la sauvegarde
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/eloquence_backup_$TIMESTAMP.tar.gz"
    
    # Sauvegarder les données existantes
    if [[ -d "/var/lib/eloquence" ]]; then
        tar -czf "$BACKUP_FILE" -C /var/lib eloquence
        log "✅ Sauvegarde créée: $BACKUP_FILE"
    else
        info "Aucune donnée existante à sauvegarder"
    fi
}

# ================================================================
# CONSTRUCTION DES IMAGES
# ================================================================

build_images() {
    log "🏗️ Construction des images Docker sécurisées..."
    
    cd "$PROJECT_ROOT"
    
    # Construire l'image de l'API principale
    info "Construction de l'image eloquence-api..."
    docker build -f services/eloquence-api/Dockerfile.secure \
        -t eloquence/api:latest \
        services/eloquence-api/
    
    # Construire l'image Vosk STT
    info "Construction de l'image vosk-stt..."
    docker build -f services/vosk-stt-analysis/Dockerfile.secure \
        -t eloquence/vosk-stt:latest \
        services/vosk-stt-analysis/
    
    # Scanner les images pour les vulnérabilités
    if command -v trivy &> /dev/null; then
        info "Scan de sécurité des images..."
        trivy image eloquence/api:latest
        trivy image eloquence/vosk-stt:latest
    else
        warn "Trivy non installé, scan de sécurité ignoré"
    fi
    
    log "✅ Images construites et scannées"
}

# ================================================================
# DÉPLOIEMENT
# ================================================================

deploy_application() {
    log "🚀 Déploiement de l'application..."
    
    cd "$PROJECT_ROOT"
    
    # Arrêter les services existants
    if [[ -f "docker-compose.production.yml" ]]; then
        docker-compose -f docker-compose.production.yml down || true
    fi
    
    # Nettoyer les ressources Docker inutilisées
    docker system prune -f
    
    # Démarrer les services en mode production
    docker-compose -f docker-compose.production.yml up -d
    
    # Attendre que les services soient prêts
    info "Attente du démarrage des services..."
    sleep 30
    
    # Vérifier la santé des services
    check_services_health
    
    log "✅ Application déployée"
}

# ================================================================
# VÉRIFICATION DE SANTÉ
# ================================================================

check_services_health() {
    log "🏥 Vérification de la santé des services..."
    
    local services=("nginx" "eloquence-api" "redis" "vosk-stt" "livekit")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if docker-compose -f docker-compose.production.yml ps "$service" | grep -q "Up"; then
            info "✅ $service: OK"
        else
            error "❌ $service: ÉCHEC"
            failed_services+=("$service")
        fi
    done
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        error "Services en échec: ${failed_services[*]}"
    fi
    
    # Test de connectivité HTTP
    if curl -f -s http://localhost/health > /dev/null; then
        info "✅ Test HTTP: OK"
    else
        warn "⚠️ Test HTTP: ÉCHEC"
    fi
    
    log "✅ Vérification de santé terminée"
}

# ================================================================
# MONITORING ET ALERTES
# ================================================================

setup_monitoring() {
    log "📊 Configuration du monitoring..."
    
    # Script de monitoring
    cat > /usr/local/bin/eloquence-monitor.sh << 'EOF'
#!/bin/bash
# Script de monitoring Eloquence

LOG_FILE="/var/log/eloquence-monitor.log"

log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Vérifier l'utilisation CPU
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    log_event "ALERT: CPU usage high: $cpu_usage%"
fi

# Vérifier l'utilisation mémoire
mem_usage=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
if (( $(echo "$mem_usage > 85" | bc -l) )); then
    log_event "ALERT: Memory usage high: $mem_usage%"
fi

# Vérifier l'espace disque
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $disk_usage -gt 85 ]]; then
    log_event "ALERT: Disk usage high: $disk_usage%"
fi

# Vérifier les services Docker
if ! docker-compose -f /opt/eloquence/docker-compose.production.yml ps | grep -q "Up"; then
    log_event "ALERT: Some Docker services are down"
fi

log_event "Monitoring check completed"
EOF
    
    chmod +x /usr/local/bin/eloquence-monitor.sh
    
    # Ajouter au crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/eloquence-monitor.sh") | crontab -
    
    log "✅ Monitoring configuré"
}

# ================================================================
# NETTOYAGE POST-DÉPLOIEMENT
# ================================================================

cleanup() {
    log "🧹 Nettoyage post-déploiement..."
    
    # Nettoyer les images Docker inutilisées
    docker image prune -f
    
    # Nettoyer les volumes orphelins
    docker volume prune -f
    
    # Nettoyer les logs anciens (> 30 jours)
    find /var/log/eloquence -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Nettoyer les sauvegardes anciennes (> 7 jours)
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
    log "✅ Nettoyage terminé"
}

# ================================================================
# FONCTION PRINCIPALE
# ================================================================

main() {
    log "🚀 DÉBUT DU DÉPLOIEMENT SÉCURISÉ ELOQUENCE"
    log "=============================================="
    
    # Vérifications préalables
    check_prerequisites
    
    # Sauvegarde
    create_backup
    
    # Configuration sécurisée
    generate_secrets
    setup_ssl
    configure_system
    configure_firewall
    
    # Construction et déploiement
    build_images
    deploy_application
    
    # Monitoring
    setup_monitoring
    
    # Nettoyage
    cleanup
    
    log "=============================================="
    log "🎉 DÉPLOIEMENT SÉCURISÉ TERMINÉ AVEC SUCCÈS !"
    log "=============================================="
    
    info "📋 Informations importantes :"
    info "  • Application accessible sur : https://$(hostname -I | awk '{print $1}')"
    info "  • Logs de déploiement : $LOG_FILE"
    info "  • Logs de monitoring : /var/log/eloquence-monitor.log"
    info "  • Sauvegarde : $BACKUP_DIR"
    info ""
    info "🔧 Commandes utiles :"
    info "  • Voir les logs : docker-compose -f docker-compose.production.yml logs -f"
    info "  • Redémarrer : docker-compose -f docker-compose.production.yml restart"
    info "  • Arrêter : docker-compose -f docker-compose.production.yml down"
    info ""
    warn "⚠️ N'oubliez pas de :"
    warn "  1. Remplacer le certificat SSL auto-signé par un certificat valide"
    warn "  2. Configurer vos clés API dans .env.production"
    warn "  3. Tester tous les endpoints de l'application"
    warn "  4. Configurer la sauvegarde automatique"
}

# ================================================================
# GESTION DES SIGNAUX
# ================================================================

trap 'error "Déploiement interrompu par l'\''utilisateur"' INT TERM

# ================================================================
# EXÉCUTION
# ================================================================

# Vérifier les arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --help, -h    Afficher cette aide"
            echo "  --check       Vérifier uniquement les prérequis"
            exit 0
            ;;
        --check)
            check_prerequisites
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            ;;
    esac
fi

# Exécution principale
main "$@"
