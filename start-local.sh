#!/bin/bash

# Script pour démarrer l'environnement de développement local d'Eloquence

# Exporter les variables d'environnement
set -a
source .env
set +a

# Arrêter les conteneurs existants
docker-compose -f docker-compose.local.yml down

# Construire et démarrer les nouveaux conteneurs
docker-compose -f docker-compose.local.yml up --build -d