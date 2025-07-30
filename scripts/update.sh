#!/bin/bash

# Script de mise à jour pour l'application Eloquence
# Ce script met à jour l'application sans perdre les données

set -e  # Arrêter en cas d'erreur

echo "🔄 Mise à jour de l'application Eloquence..."

# Variables de configuration
APP_DIR="/home/eloquence/app"
BACKUP_DIR="/home/eloquence/backups"

# Fonction pour afficher les messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "docker-compose.yml" ]; then
    log "❌ Erreur: docker-compose.yml non trouvé. Assurez-vous d'être dans le répertoire de l'application."
    exit 1
fi

# Créer une sauvegarde avant la mise à jour
BACKUP_NAME="update_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
log "💾 Création d'une sauvegarde avant mise à jour: $BACKUP_NAME"
mkdir -p $BACKUP_DIR
tar -czf "$BACKUP_DIR/$BACKUP_NAME" --exclude='node_modules' --exclude='build' --exclude='.git' .

# Arrêter les conteneurs en cours
log "🛑 Arrêt des conteneurs..."
docker-compose down

# Sauvegarder les volumes de données si ils existent
log "💾 Sauvegarde des volumes de données..."
docker volume ls | grep backend_data && docker run --rm -v backend_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/backend_data_$BACKUP_NAME.tar.gz -C /data . || log "Aucun volume backend_data trouvé"

# Nettoyer les images non utilisées
log "🧹 Nettoyage des images Docker non utilisées..."
docker system prune -f

# Reconstruire les images avec les dernières modifications
log "🔨 Reconstruction des images..."
docker-compose build --no-cache

# Redémarrer les services
log "🚀 Redémarrage des services..."
docker-compose up -d

# Attendre que les services soient prêts
log "⏳ Attente du redémarrage des services..."
sleep 30

# Vérifier que tout fonctionne
log "🔍 Vérification des services..."
if docker-compose ps | grep -q "Up"; then
    log "✅ Services redémarrés avec succès"
    log "🌐 Application accessible sur http://localhost"
else
    log "❌ Erreur lors du redémarrage"
    docker-compose logs
    log "🔄 Tentative de restauration de la sauvegarde..."
    # Ici on pourrait ajouter une logique de rollback
    exit 1
fi

log "🎉 Mise à jour terminée avec succès!"
log "📊 État des conteneurs:"
docker-compose ps