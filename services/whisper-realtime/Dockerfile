# =============================================================================
# Dockerfile pour Service Whisper Temps Réel Eloquence
# =============================================================================
# Service simplifié remplaçant l'architecture hybride VOSK + Whisper
# Utilise Whisper-large-v3-turbo pour reconnaissance vocale temps réel
# 
# Avantages:
# - Pas de téléchargement de modèles volumineux (utilise HuggingFace Hub)
# - Architecture simplifiée et maintenable
# - Compatible avec l'infrastructure existante
# - Performance optimisée pour temps réel

FROM python:3.11-slim

# Métadonnées
LABEL maintainer="Eloquence Team"
LABEL description="Service Whisper Temps Réel pour Eloquence"
LABEL version="1.0.0"

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    # Audio et multimedia
    ffmpeg \
    libsndfile1 \
    # Outils système
    curl \
    wget \
    # Nettoyage pour réduire la taille de l'image
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Définition du répertoire de travail
WORKDIR /app

# Installation des dépendances Python optimisées
# Installation en une seule couche pour optimiser le cache Docker
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    # FastAPI et serveur
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    # WebSocket
    websockets==12.0 \
    python-multipart==0.0.6 \
    # Machine Learning
    transformers==4.38.2 \
    torch==2.2.2 \
    torchaudio==2.2.2 \
    # Audio processing
    numpy==1.26.4 \
    soundfile==0.12.1 \
    librosa==0.10.1 \
    # Utilitaires
    pydantic==2.5.3 \
    httpx==0.25.2

# Copie du code source
COPY main.py .

# Création des répertoires nécessaires
RUN mkdir -p /app/.cache /app/logs /app/temp

# Configuration des variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV TRANSFORMERS_CACHE=/app/.cache
ENV HF_HOME=/app/.cache/huggingface
ENV TORCH_HOME=/app/.cache/torch
ENV TOKENIZERS_PARALLELISM=false
ENV OMP_NUM_THREADS=1

# Variables d'environnement par défaut
ENV HOST=0.0.0.0
ENV PORT=8006
ENV WHISPER_MODEL_ID=openai/whisper-large-v3-turbo
ENV WHISPER_DEVICE=cpu
ENV AUDIO_SAMPLE_RATE=16000
ENV AUDIO_CHUNK_DURATION=3.0
ENV MAX_AUDIO_BUFFER_SIZE=48000

# Exposition du port
EXPOSE 8006

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8006/health || exit 1

# Utilisateur non-root pour la sécurité
RUN groupadd -r whisper && useradd -r -g whisper whisper
RUN chown -R whisper:whisper /app
USER whisper

# Point d'entrée avec gestion des signaux
CMD ["python", "main.py"]

# Métadonnées finales
LABEL org.opencontainers.image.title="Whisper Realtime Service"
LABEL org.opencontainers.image.description="Service d'évaluation vocale temps réel basé sur Whisper"
LABEL org.opencontainers.image.vendor="Eloquence"
LABEL org.opencontainers.image.version="1.0.0"