# Dockerfile pour le service de tokens LiveKit
FROM python:3.11-slim

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copier les requirements
COPY requirements.txt .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY main.py .

# Exposer le port
EXPOSE 8004

# Variables d'environnement par défaut
ENV PYTHONUNBUFFERED=1
ENV LIVEKIT_API_KEY=devkey
ENV LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef
ENV LIVEKIT_URL=ws://localhost:7880

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8004/health || exit 1

# Démarrer le service
CMD ["python", "main.py"]