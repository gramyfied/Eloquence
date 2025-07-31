#!/bin/bash
# ================================================================
# INSTALLATION DU SERVICE SYSTEMD POUR ELOQUENCE
# ================================================================
# Installe un service systemd pour démarrer automatiquement Eloquence
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

# Vérifier les privilèges root
if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

# Déterminer le répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
USER_NAME=$(logname)

log_info "Installation du service systemd pour Eloquence"
log_info "Répertoire du projet: $PROJECT_DIR"
log_info "Utilisateur: $USER_NAME"

# Créer le fichier de service systemd
cat > /etc/systemd/system/eloquence.service << EOF
[Unit]
Description=Eloquence - Application de Formation à l'Éloquence
Documentation=https://github.com/gramyfied/Eloquence
After=docker.service
Requires=docker.service
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=forking
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$PROJECT_DIR
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=DOCKER_HOST=unix:///var/run/docker.sock

# Commandes de démarrage
ExecStartPre=/bin/bash -c 'cd $PROJECT_DIR && sudo docker compose -f docker-compose.yml pull --quiet'
ExecStart=/bin/bash -c 'cd $PROJECT_DIR && sudo docker compose -f docker-compose.yml up -d'
ExecStartPost=/bin/sleep 30
ExecStartPost=/bin/bash -c 'cd $PROJECT_DIR && ./scripts/monitor-and-recover.sh --check'

# Commandes d'arrêt
ExecStop=/bin/bash -c 'cd $PROJECT_DIR && sudo docker compose -f docker-compose.yml down'
ExecStopPost=/bin/bash -c 'if [ -f $PROJECT_DIR/logs/monitor.pid ]; then kill \$(cat $PROJECT_DIR/logs/monitor.pid) 2>/dev/null || true; rm -f $PROJECT_DIR/logs/monitor.pid; fi'

# Configuration de redémarrage
Restart=always
RestartSec=10
TimeoutStartSec=300
TimeoutStopSec=60

# Limites de ressources
LimitNOFILE=65536
LimitNPROC=4096

# Sécurité
PrivateTmp=false
ProtectSystem=false
ProtectHome=false
NoNewPrivileges=false

# Logs
StandardOutput=journal
StandardError=journal
SyslogIdentifier=eloquence

[Install]
WantedBy=multi-user.target
EOF

log_success "Fichier de service créé: /etc/systemd/system/eloquence.service"

# Créer le fichier de service pour le monitoring
cat > /etc/systemd/system/eloquence-monitor.service << EOF
[Unit]
Description=Eloquence Monitor - Surveillance et Récupération Automatique
Documentation=https://github.com/gramyfied/Eloquence
After=eloquence.service
Requires=eloquence.service
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$PROJECT_DIR
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Commande de démarrage du monitoring
ExecStart=/bin/bash $PROJECT_DIR/scripts/monitor-and-recover.sh --monitor

# Configuration de redémarrage
Restart=always
RestartSec=30
TimeoutStartSec=60
TimeoutStopSec=30

# Limites de ressources
LimitNOFILE=1024
LimitNPROC=512

# Sécurité
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true
ReadWritePaths=$PROJECT_DIR/logs $PROJECT_DIR/backups

# Logs
StandardOutput=journal
StandardError=journal
SyslogIdentifier=eloquence-monitor

[Install]
WantedBy=multi-user.target
EOF

log_success "Fichier de service monitoring créé: /etc/systemd/system/eloquence-monitor.service"

# Créer un script de gestion des services
cat > /usr/local/bin/eloquence-service << EOF
#!/bin/bash
# Script de gestion des services Eloquence

case "\$1" in
    start)
        echo "Démarrage des services Eloquence..."
        systemctl start eloquence
        systemctl start eloquence-monitor
        ;;
    stop)
        echo "Arrêt des services Eloquence..."
        systemctl stop eloquence-monitor
        systemctl stop eloquence
        ;;
    restart)
        echo "Redémarrage des services Eloquence..."
        systemctl restart eloquence
        systemctl restart eloquence-monitor
        ;;
    status)
        echo "=== Statut du service principal ==="
        systemctl status eloquence --no-pager
        echo ""
        echo "=== Statut du monitoring ==="
        systemctl status eloquence-monitor --no-pager
        ;;
    enable)
        echo "Activation du démarrage automatique..."
        systemctl enable eloquence
        systemctl enable eloquence-monitor
        ;;
    disable)
        echo "Désactivation du démarrage automatique..."
        systemctl disable eloquence-monitor
        systemctl disable eloquence
        ;;
    logs)
        if [ "\$2" = "monitor" ]; then
            journalctl -u eloquence-monitor -f
        else
            journalctl -u eloquence -f
        fi
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|enable|disable|logs [monitor]}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/eloquence-service
log_success "Script de gestion créé: /usr/local/bin/eloquence-service"

# Recharger systemd
systemctl daemon-reload
log_success "Configuration systemd rechargée"

# Créer les répertoires nécessaires
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/backups/auto"
mkdir -p "$PROJECT_DIR/backups/manual"
chown -R "$USER_NAME:$USER_NAME" "$PROJECT_DIR/logs" "$PROJECT_DIR/backups"

log_success "Répertoires de logs et sauvegardes créés"

# Afficher les instructions
echo ""
log_info "🎉 Installation terminée avec succès !"
echo ""
echo "Commandes disponibles:"
echo "  eloquence-service start    - Démarrer les services"
echo "  eloquence-service stop     - Arrêter les services"
echo "  eloquence-service restart  - Redémarrer les services"
echo "  eloquence-service status   - Voir le statut"
echo "  eloquence-service enable   - Activer le démarrage automatique"
echo "  eloquence-service disable  - Désactiver le démarrage automatique"
echo "  eloquence-service logs     - Voir les logs du service principal"
echo "  eloquence-service logs monitor - Voir les logs du monitoring"
echo ""
echo "Pour activer le démarrage automatique au boot:"
echo "  sudo eloquence-service enable"
echo ""
echo "Pour démarrer immédiatement:"
echo "  sudo eloquence-service start"
echo ""
log_warning "Note: Les services utilisent sudo pour Docker, assurez-vous que l'utilisateur $USER_NAME a les permissions sudo appropriées"
