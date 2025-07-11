# Dockerfile pour le Service d'Évaluation Hybride VOSK + Whisper
FROM python:3.11-slim

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app

# Installation des dépendances système pour l'audio
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libasound2-dev \
    portaudio19-dev \
    libffi-dev \
    libssl-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Création du répertoire de travail
WORKDIR /app

# Copie des requirements et installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Téléchargement du modèle VOSK français
RUN mkdir -p /app/models && \
    cd /app/models && \
    wget https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip && \
    unzip vosk-model-fr-0.22.zip && \
    mv vosk-model-fr-0.22 vosk-model-fr && \
    rm vosk-model-fr-0.22.zip

# Copie du code source
COPY . .

# Création des répertoires nécessaires
RUN mkdir -p /app/logs /app/temp

# Exposition du port
EXPOSE 8002

# Variables d'environnement pour l'application
ENV VOSK_MODEL_PATH=/app/models/vosk-model-fr
ENV WHISPER_SERVICE_URL=http://whisper-large-v3-turbo:8001
ENV LOG_LEVEL=INFO
ENV ENVIRONMENT=production

# Point d'entrée
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--log-level", "info"]