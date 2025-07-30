#!/bin/bash

# Script de déploiement pour l'application Eloquence
# Ce script configure et déploie l'application Python + Flutter

set -e  # Arrêter en cas d'erreur

echo "🚀 Déploiement de l'application Eloquence..."

# Variables de configuration
APP_DIR="/home/eloquence/app"
BACKUP_DIR="/home/eloquence/backups"
USER="eloquence"

# Fonction pour afficher les messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "docker-compose.yml" ]; then
    log "❌ Erreur: docker-compose.yml non trouvé. Assurez-vous d'être dans le répertoire de l'application."
    exit 1
fi

# Vérifier que Docker et Docker Compose sont installés
if ! command -v docker &> /dev/null; then
    log "❌ Docker n'est pas installé. Installation..."
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
    log "❌ Docker Compose n'est pas installé. Installation..."
    sudo apt-get install -y docker-compose
fi

# Créer le répertoire de sauvegarde s'il n'existe pas
sudo mkdir -p $BACKUP_DIR
sudo chown $USER:$USER $BACKUP_DIR

# Arrêter les conteneurs existants s'ils existent
log "🛑 Arrêt des conteneurs existants..."
docker-compose down --remove-orphans || true

# Créer une sauvegarde si des données existent
if [ -d "backend" ] && [ "$(ls -A backend 2>/dev/null)" ]; then
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    log "💾 Création d'une sauvegarde: $BACKUP_NAME"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" --exclude='node_modules' --exclude='build' --exclude='.git' .
fi

# Générer les certificats SSL si ils n'existent pas
if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
    log "🔐 Génération des certificats SSL..."
    chmod +x nginx/ssl/generate-certs.sh
    sudo nginx/ssl/generate-certs.sh
fi

# Construire et démarrer les conteneurs
log "🔨 Construction des images Docker..."
docker-compose build --no-cache

log "🚀 Démarrage des conteneurs..."
docker-compose up -d

# Attendre que les services soient prêts
log "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier que les services sont en cours d'exécution
log "🔍 Vérification des services..."
if docker-compose ps | grep -q "eloquence-backend.*Up"; then
    log "✅ Backend démarré avec succès"
else
    log "❌ Erreur: Le backend n'a pas démarré correctement"
    docker-compose logs eloquence-backend
    exit 1
fi

if docker-compose ps | grep -q "eloquence-frontend.*Up"; then
    log "✅ Frontend démarré avec succès"
else
    log "❌ Erreur: Le frontend n'a pas démarré correctement"
    docker-compose logs eloquence-frontend
    exit 1
fi

if docker-compose ps | grep -q "eloquence-nginx.*Up"; then
    log "✅ Nginx démarré avec succès"
else
    log "❌ Erreur: Nginx n'a pas démarré correctement"
    docker-compose logs eloquence-nginx
    exit 1
fi

# Test de connectivité
log "🌐 Test de connectivité..."
sleep 10

if curl -f http://localhost/health > /dev/null 2>&1; then
    log "✅ API accessible via Nginx"
else
    log "⚠️  API non accessible via Nginx, vérification directe..."
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log "✅ API accessible directement"
    else
        log "❌ API non accessible"
    fi
fi

# Afficher les informations de déploiement
log "📊 Informations de déploiement:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Application accessible sur:"
echo "   - HTTP:  http://localhost"
echo "   - HTTPS: https://localhost (certificat auto-signé)"
echo "   - API:   http://localhost/api/"
echo ""
echo "🐳 Conteneurs Docker:"
docker-compose ps
echo ""
echo "📝 Pour voir les logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Pour arrêter l'application:"
echo "   docker-compose down"
echo ""
echo "🔄 Pour mettre à jour:"
echo "   ./scripts/update.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "🎉 Déploiement terminé avec succès!"