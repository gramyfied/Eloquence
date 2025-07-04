#!/bin/bash
# Script de démarrage optimisé pour le développement

set -e

echo "🚀 Démarrage de l'environnement de développement Eloquence"
echo "=================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher des messages colorés
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier si on est dans WSL ou Windows
if grep -q Microsoft /proc/version 2>/dev/null; then
    log_info "Détection de WSL 2 - Configuration optimale détectée !"
    IN_WSL=true
else
    log_warning "Vous n'êtes pas dans WSL 2. Pour de meilleures performances, considérez déplacer votre projet dans WSL 2."
    IN_WSL=false
fi

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé ou pas dans le PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker n'est pas démarré ou inaccessible"
    exit 1
fi

log_success "Docker est disponible"

# Vérifier Docker Compose
if ! docker compose version &> /dev/null; then
    log_error "Docker Compose n'est pas disponible"
    exit 1
fi

log_success "Docker Compose est disponible"

# Nettoyer les conteneurs existants si demandé
if [ "$1" = "--clean" ]; then
    log_info "Nettoyage des conteneurs existants..."
    docker compose -f docker-compose.dev.yml down --volumes --remove-orphans 2>/dev/null || true
    docker system prune -f --volumes 2>/dev/null || true
    log_success "Nettoyage terminé"
fi

# Choisir le mode de démarrage
MODE=${1:-"dev"}

case $MODE in
    "watch")
        log_info "Démarrage en mode Docker Compose Watch (synchronisation ultra-rapide)"
        COMPOSE_FILE="docker-compose.watch.yml"
        COMMAND="docker compose -f $COMPOSE_FILE up --watch"
        ;;
    "dev"|*)
        log_info "Démarrage en mode développement standard"
        COMPOSE_FILE="docker-compose.dev.yml"
        COMMAND="docker compose -f $COMPOSE_FILE up --build"
        ;;
esac

log_info "Fichier de configuration: $COMPOSE_FILE"

# Vérifier que le fichier existe
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Le fichier $COMPOSE_FILE n'existe pas"
    exit 1
fi

# Construire les images si nécessaire
log_info "Construction des images Docker..."
docker compose -f $COMPOSE_FILE build --parallel

# Démarrer les services
log_info "Démarrage des services..."
echo ""
log_success "🎯 Services qui vont démarrer:"
echo "   • API Backend (port 8000) - Hot reload activé"
echo "   • LiveKit Server (port 7880)"
echo "   • Redis (port 6379)"
echo "   • Whisper STT (port 8001)"
echo "   • Azure TTS (port 5002)"
echo ""
log_info "🔥 Hot-reload activé - vos modifications seront appliquées instantanément !"
echo ""

# Démarrer avec la commande appropriée
exec $COMMAND