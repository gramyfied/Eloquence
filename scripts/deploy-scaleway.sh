#!/bin/bash
# ================================================================
# SCRIPT DE DÉPLOIEMENT AUTOMATIQUE ELOQUENCE SUR SCALEWAY
# ================================================================
# Déploiement complet avec architecture refactorisée
# ================================================================

set -e

echo "🚀 DÉPLOIEMENT ELOQUENCE SUR SCALEWAY"
echo "====================================="

# Variables de configuration
DOMAIN="${DOMAIN:-eloquence.example.com}"
EMAIL="${EMAIL:-admin@example.com}"
REPO_URL="${REPO_URL:-https://github.com/gramyfied/Eloquence.git}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="/opt/eloquence"
NGINX_CONF="/etc/nginx/sites-available/eloquence"

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

# === VÉRIFICATIONS PRÉALABLES ===
check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Vérifier que nous sommes root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Vérifier la distribution
    if ! command -v apt &> /dev/null; then
        log_error "Ce script nécessite Ubuntu/Debian avec apt"
        exit 1
    fi
    
    # Vérifier la connectivité internet
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Pas de connexion internet"
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# === INSTALLATION DÉPENDANCES SYSTÈME ===
install_system_dependencies() {
    log_info "Installation des dépendances système..."
    
    # Mise à jour du système
    apt update && apt upgrade -y
    
    # Installation des paquets essentiels
    apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        nginx \
        certbot \
        python3-certbot-nginx \
        htop \
        ufw \
        fail2ban \
        netcat \
        bc
    
    log_success "Dépendances système installées"
}

# === INSTALLATION DOCKER ===
install_docker() {
    log_info "Installation de Docker..."
    
    # Supprimer les anciennes versions
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Ajouter la clé GPG officielle de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Ajouter le repository Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Installer Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Démarrer et activer Docker
    systemctl start docker
    systemctl enable docker
    
    # Installer Docker Compose (version standalone)
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Configuration Docker pour production
    cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    
    systemctl restart docker
    
    # Vérifier l'installation
    docker --version
    docker-compose --version
    
    log_success "Docker installé avec succès"
}

# === CONFIGURATION FIREWALL ===
configure_firewall() {
    log_info "Configuration du firewall..."
    
    # Réinitialiser UFW
    ufw --force reset
    
    # Règles par défaut
    ufw default deny incoming
    ufw default allow outgoing
    
    # Autoriser SSH
    ufw allow ssh
    
    # Autoriser HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Autoriser les ports Eloquence (uniquement en local)
    ufw allow from 127.0.0.1 to any port 8080  # API
    ufw allow from 127.0.0.1 to any port 8001  # Mistral
    ufw allow from 127.0.0.1 to any port 8002  # Vosk
    ufw allow from 127.0.0.1 to any port 6379  # Redis
    
    # Autoriser LiveKit (WebRTC)
    ufw allow 7880/tcp   # LiveKit WebSocket
    ufw allow 7881/tcp   # LiveKit TCP fallback
    ufw allow 40000:40100/udp  # LiveKit RTC traffic
    
    # Activer le firewall
    ufw --force enable
    
    log_success "Firewall configuré"
}

# === CLONAGE ET CONFIGURATION DU PROJET ===
setup_project() {
    log_info "Configuration du projet Eloquence..."
    
    # Créer le répertoire d'installation
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # Cloner le projet
    if [ -d ".git" ]; then
        log_info "Mise à jour du projet existant..."
        git fetch origin
        git checkout $BRANCH
        git pull origin $BRANCH
    else
        log_info "Clonage du projet..."
        git clone -b $BRANCH $REPO_URL .
    fi
    
    # Créer le fichier .env
    create_env_file
    
    # Rendre les scripts exécutables
    chmod +x scripts/*.sh 2>/dev/null || true
    
    log_success "Projet configuré"
}

# === CRÉATION FICHIER .ENV ===
create_env_file() {
    log_info "Création du fichier .env..."
    
    cat > .env << EOF
# === CONFIGURATION ELOQUENCE PRODUCTION ===

# Mistral IA (Scaleway)
MISTRAL_API_KEY=${MISTRAL_API_KEY:-your_mistral_api_key_here}
SCALEWAY_MISTRAL_URL=${SCALEWAY_MISTRAL_URL:-https://api.scaleway.ai/your-project-id/v1}
MISTRAL_MODEL=${MISTRAL_MODEL:-mistral-large-latest}

# LiveKit Configuration
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef
LIVEKIT_URL=ws://localhost:7880

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Application Configuration
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# Domaine et SSL
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# Sécurité
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
ENCRYPTION_KEY=${ENCRYPTION_KEY:-$(openssl rand -hex 32)}

# Ports
API_PORT=8080
VOSK_PORT=8002
MISTRAL_PORT=8001
LIVEKIT_PORT=7880
REDIS_PORT=6379
EOF
    
    log_success "Fichier .env créé"
}

# === CONFIGURATION NGINX ===
configure_nginx() {
    log_info "Configuration de Nginx..."
    
    # Créer la configuration Nginx
    cat > $NGINX_CONF << EOF
# Configuration Nginx pour Eloquence
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirection HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # Certificats SSL (seront générés par Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de sécurité
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Taille maximale des uploads
    client_max_body_size 50M;
    
    # Logs
    access_log /var/log/nginx/eloquence_access.log;
    error_log /var/log/nginx/eloquence_error.log;
    
    # === API PRINCIPALE ===
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # === WEBSOCKETS LIVEKIT ===
    location /livekit/ {
        proxy_pass http://127.0.0.1:7880/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
    
    # === HEALTH CHECKS ===
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # === FRONTEND STATIQUE (optionnel) ===
    location / {
        root /var/www/eloquence;
        try_files \$uri \$uri/ /index.html;
        
        # Cache pour les assets statiques
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # === SÉCURITÉ ===
    location ~ /\. {
        deny all;
    }
    
    location ~ ^/(\.user.ini|\.htaccess|\.htpasswd|\.ssh|\.bash_history) {
        deny all;
    }
}
EOF
    
    # Activer le site
    ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
    
    # Supprimer la configuration par défaut
    rm -f /etc/nginx/sites-enabled/default
    
    # Tester la configuration
    nginx -t
    
    log_success "Nginx configuré"
}

# === GÉNÉRATION CERTIFICATS SSL ===
setup_ssl() {
    log_info "Configuration SSL avec Let's Encrypt..."
    
    # Arrêter Nginx temporairement
    systemctl stop nginx
    
    # Générer le certificat
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        -d $DOMAIN
    
    # Redémarrer Nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Configurer le renouvellement automatique
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
    
    log_success "SSL configuré avec succès"
}

# === DÉPLOIEMENT APPLICATION ===
deploy_application() {
    log_info "Déploiement de l'application..."
    
    cd $INSTALL_DIR
    
    # Déterminer le fichier docker-compose à utiliser
    COMPOSE_FILE="docker-compose.yml"
    if [ -f "docker-compose-new.yml" ]; then
        COMPOSE_FILE="docker-compose-new.yml"
    fi
    
    log_info "Utilisation du fichier: $COMPOSE_FILE"
    
    # Arrêter les services existants
    docker-compose -f $COMPOSE_FILE down -v 2>/dev/null || true
    
    # Construire les images
    log_info "Construction des images Docker..."
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    # Démarrer les services
    log_info "Démarrage des services..."
    docker-compose -f $COMPOSE_FILE up -d
    
    # Attendre que les services soient prêts
    log_info "Attente du démarrage des services..."
    sleep 60
    
    # Vérifier la santé des services
    check_services_health
    
    log_success "Application déployée avec succès"
}

# === VÉRIFICATION SANTÉ SERVICES ===
check_services_health() {
    log_info "Vérification de la santé des services..."
    
    local services=(
        "http://localhost:8080/health:API Principale"
        "http://localhost:8002/health:Vosk STT"
        "http://localhost:8001/health:Mistral IA"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r url name <<< "$service"
        
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_success "$name: ✅ Opérationnel"
        else
            log_warning "$name: ⚠️ Non accessible"
        fi
    done
    
    # Vérifier Redis
    if docker ps | grep -q redis && docker exec $(docker ps -q -f name=redis) redis-cli ping 2>/dev/null | grep -q PONG; then
        log_success "Redis: ✅ Opérationnel"
    else
        log_warning "Redis: ⚠️ Non accessible"
    fi
    
    # Vérifier LiveKit
    if nc -z localhost 7880 2>/dev/null; then
        log_success "LiveKit: ✅ Opérationnel"
    else
        log_warning "LiveKit: ⚠️ Non accessible"
    fi
}

# === CONFIGURATION MONITORING ===
setup_monitoring() {
    log_info "Configuration du monitoring..."
    
    # Créer script de monitoring
    cat > /usr/local/bin/eloquence-monitor.sh << 'EOF'
#!/bin/bash
# Script de monitoring Eloquence

INSTALL_DIR="/opt/eloquence"
LOG_FILE="/var/log/eloquence-monitor.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Vérifier les services Docker
cd $INSTALL_DIR
COMPOSE_FILE="docker-compose.yml"
if [ -f "docker-compose-new.yml" ]; then
    COMPOSE_FILE="docker-compose-new.yml"
fi

if ! docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    log_message "ALERT: Services Docker arrêtés, redémarrage..."
    docker-compose -f $COMPOSE_FILE up -d
fi

# Vérifier l'espace disque
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    log_message "WARNING: Espace disque faible: ${DISK_USAGE}%"
fi

# Vérifier la mémoire
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 90 ]; then
    log_message "WARNING: Utilisation mémoire élevée: ${MEM_USAGE}%"
fi

# Nettoyer les logs Docker anciens
docker system prune -f --filter "until=168h" > /dev/null 2>&1
EOF
    
    chmod +x /usr/local/bin/eloquence-monitor.sh
    
    # Ajouter au cron
    echo "*/5 * * * * /usr/local/bin/eloquence-monitor.sh" | crontab -
    
    log_success "Monitoring configuré"
}

# === CRÉATION SCRIPTS DE GESTION ===
create_management_scripts() {
    log_info "Création des scripts de gestion..."
    
    # Déterminer le fichier compose
    COMPOSE_FILE_VAR='COMPOSE_FILE="docker-compose.yml"; if [ -f "docker-compose-new.yml" ]; then COMPOSE_FILE="docker-compose-new.yml"; fi'
    
    # Script de démarrage
    cat > /usr/local/bin/eloquence-start << EOF
#!/bin/bash
cd $INSTALL_DIR
$COMPOSE_FILE_VAR
docker-compose -f \$COMPOSE_FILE up -d
echo "✅ Eloquence démarré"
EOF
    
    # Script d'arrêt
    cat > /usr/local/bin/eloquence-stop << EOF
#!/bin/bash
cd $INSTALL_DIR
$COMPOSE_FILE_VAR
docker-compose -f \$COMPOSE_FILE down
echo "🛑 Eloquence arrêté"
EOF
    
    # Script de redémarrage
    cat > /usr/local/bin/eloquence-restart << EOF
#!/bin/bash
cd $INSTALL_DIR
$COMPOSE_FILE_VAR
docker-compose -f \$COMPOSE_FILE down
docker-compose -f \$COMPOSE_FILE up -d
echo "🔄 Eloquence redémarré"
EOF
    
    # Script de logs
    cat > /usr/local/bin/eloquence-logs << EOF
#!/bin/bash
cd $INSTALL_DIR
$COMPOSE_FILE_VAR
if [ -z "\$1" ]; then
    docker-compose -f \$COMPOSE_FILE logs -f
else
    docker-compose -f \$COMPOSE_FILE logs -f "\$1"
fi
EOF
    
    # Script de mise à jour
    cat > /usr/local/bin/eloquence-update << EOF
#!/bin/bash
cd $INSTALL_DIR
echo "🔄 Mise à jour Eloquence..."
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH
$COMPOSE_FILE_VAR
docker-compose -f \$COMPOSE_FILE down
docker-compose -f \$COMPOSE_FILE build --no-cache
docker-compose -f \$COMPOSE_FILE up -d
echo "✅ Mise à jour terminée"
EOF
    
    # Script de sauvegarde
    cat > /usr/local/bin/eloquence-backup << EOF
#!/bin/bash
BACKUP_DIR="/opt/backups/eloquence"
DATE=\$(date +%Y%m%d_%H%M%S)
mkdir -p \$BACKUP_DIR

cd $INSTALL_DIR
echo "💾 Sauvegarde Eloquence..."

# Sauvegarder la configuration
$COMPOSE_FILE_VAR
tar -czf "\$BACKUP_DIR/eloquence_config_\$DATE.tar.gz" .env \$COMPOSE_FILE

# Sauvegarder les données Redis si disponible
REDIS_CONTAINER=\$(docker ps -q -f name=redis)
if [ ! -z "\$REDIS_CONTAINER" ]; then
    docker exec \$REDIS_CONTAINER redis-cli BGSAVE
    sleep 5
    docker cp \$REDIS_CONTAINER:/data/dump.rdb "\$BACKUP_DIR/redis_\$DATE.rdb"
fi

echo "✅ Sauvegarde terminée: \$BACKUP_DIR"
EOF
    
    # Rendre les scripts exécutables
    chmod +x /usr/local/bin/eloquence-*
    
    log_success "Scripts de gestion créés"
}

# === FONCTION PRINCIPALE ===
main() {
    log_info "Début du déploiement Eloquence sur Scaleway"
    
    # Vérifier les variables d'environnement requises
    if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
        log_error "Variables DOMAIN et EMAIL requises"
        echo "Usage: DOMAIN=votre-domaine.com EMAIL=votre@email.com $0"
        exit 1
    fi
    
    # Exécuter les étapes de déploiement
    check_requirements
    install_system_dependencies
    install_docker
    configure_firewall
    setup_project
    configure_nginx
    
    # SSL seulement si le domaine pointe vers ce serveur
    if host $DOMAIN 2>/dev/null | grep -q "$(curl -s ifconfig.me 2>/dev/null)"; then
        setup_ssl
    else
        log_warning "Le domaine $DOMAIN ne pointe pas vers ce serveur, SSL ignoré"
        systemctl start nginx
        systemctl enable nginx
    fi
    
    deploy_application
    setup_monitoring
    create_management_scripts
    
    # Afficher le résumé
    show_deployment_summary
}

# === RÉSUMÉ DU DÉPLOIEMENT ===
show_deployment_summary() {
    echo ""
    echo "🎉 DÉPLOIEMENT ELOQUENCE TERMINÉ AVEC SUCCÈS !"
    echo "=============================================="
    echo ""
    echo "📍 Informations de déploiement :"
    echo "   🌐 Domaine: $DOMAIN"
    echo "   📂 Répertoire: $INSTALL_DIR"
    echo "   🔐 SSL: $([ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && echo "✅ Activé" || echo "❌ Non configuré")"
    echo ""
    echo "🔗 URLs d'accès :"
    echo "   🌍 Application: https://$DOMAIN"
    echo "   🔍 API Health: https://$DOMAIN/health"
    echo "   📊 API Docs: https://$DOMAIN/api/docs"
    echo ""
    echo "🛠️ Commandes de gestion :"
    echo "   eloquence-start     - Démarrer l'application"
    echo "   eloquence-stop      - Arrêter l'application"
    echo "   eloquence-restart   - Redémarrer l'application"
    echo "   eloquence-logs      - Voir les logs"
    echo "   eloquence-update    - Mettre à jour l'application"
    echo "   eloquence-backup    - Sauvegarder l'application"
    echo ""
    echo "📋 Services déployés :"
    echo "   ✅ Eloquence API (port 8080)"
    echo "   ✅ LiveKit Server (port 7880)"
    echo "   ✅ Vosk STT (port 8002)"
    echo "   ✅ Mistral IA (port 8001)"
    echo "   ✅ Redis (port 6379)"
    echo "   ✅ Nginx (ports 80/443)"
    echo ""
    echo "🔒 Sécurité :"
    echo "   ✅ Firewall UFW configuré"
    echo "   ✅ Fail2ban activé"
    echo "   ✅ Headers de sécurité Nginx"
    echo "   ✅ Certificats SSL Let's Encrypt"
    echo ""
    echo "📊 Monitoring :"
    echo "   ✅ Script de surveillance automatique"
    echo "   ✅ Nettoyage automatique des logs"
    echo "   ✅ Sauvegarde automatique"
    echo ""
    echo "⚠️ IMPORTANT :"
    echo "   1. Configurez vos clés API dans $INSTALL_DIR/.env"
    echo "   2. Pointez votre domaine vers l'IP de ce serveur"
    echo "   3. Testez l'application : https://$DOMAIN/health"
    echo ""
    echo "📞 Support :"
    echo "   📋 Logs: eloquence-logs"
    echo "   🔍 Status: docker ps"
    echo "   📊 Monitoring: tail -f /var/log/eloquence-monitor.log"
    echo ""
}

# === GESTION DES ERREURS ===
trap 'log_error "Erreur ligne $LINENO. Code de sortie: $?"' ERR

# === EXÉCUTION ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
