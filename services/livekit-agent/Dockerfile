FROM python:3.11-slim

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier les requirements et installer les dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . .

# Exposer le port (optionnel pour l'agent)
EXPOSE 8005

# Variables d'environnement par défaut
ENV LIVEKIT_URL=ws://livekit:7880
ENV LIVEKIT_API_KEY=devkey
ENV LIVEKIT_API_SECRET=secret
ENV MISTRAL_BASE_URL=https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1
ENV VOSK_SERVICE_URL=http://vosk-stt-analysis:2700

# Commande de démarrage
CMD ["python", "main.py", "start"]