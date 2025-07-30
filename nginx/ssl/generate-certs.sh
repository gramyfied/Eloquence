#!/bin/bash

# Script pour générer des certificats SSL auto-signés pour le développement
# NE PAS UTILISER EN PRODUCTION - Utiliser Let's Encrypt ou des certificats valides

echo "Génération des certificats SSL auto-signés..."

# Créer le répertoire s'il n'existe pas
mkdir -p /etc/nginx/ssl

# Générer la clé privée
openssl genrsa -out /etc/nginx/ssl/key.pem 2048

# Générer le certificat auto-signé
openssl req -new -x509 -key /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/cert.pem -days 365 -subj "/C=FR/ST=France/L=Paris/O=Eloquence/OU=IT/CN=localhost"

# Définir les permissions appropriées
chmod 600 /etc/nginx/ssl/key.pem
chmod 644 /etc/nginx/ssl/cert.pem

echo "Certificats SSL générés avec succès !"
echo "Emplacement: /etc/nginx/ssl/"
echo "Note: Ces certificats sont auto-signés et destinés au développement uniquement."