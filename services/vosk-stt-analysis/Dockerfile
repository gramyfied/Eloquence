FROM python:3.11-slim

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV VOSK_MODEL_PATH=/app/models

# Dépendances système
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Répertoire de travail
WORKDIR /app

# Copier requirements et installer dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code
COPY . .

# Créer répertoire modèles
RUN mkdir -p /app/models

# Copier le script de téléchargement automatique
COPY vosk_auto_download_script.py /app/
RUN chmod +x /app/vosk_auto_download_script.py

# Exposer le port
EXPOSE 8001

# Santé
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Commande de démarrage
CMD python3 /app/vosk_auto_download_script.py && uvicorn app:app --host 0.0.0.0 --port 8001 --workers 4
