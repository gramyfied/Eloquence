# Utiliser l'image officielle de LiveKit comme base
FROM livekit/livekit-server:latest

# L'image de base utilise un utilisateur non-root.
# Passer a root pour installer des paquets
USER root

# Mettre a jour les paquets et installer curl
# --no-cache pour ne pas garder le cache de l'index des paquets
RUN apk update && apk add --no-cache curl

# Copier le fichier de configuration
COPY livekit.yaml /app/livekit.yaml

# Revenir a l'utilisateur par defaut de l'image de base si necessaire
# (Dans ce cas, livekit, uid 1000)
USER 1000