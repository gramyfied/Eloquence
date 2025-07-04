# Dockerfile pour Whisper STT Service

# --- Build Stage ---
FROM python:3.11 as builder

# Variables d'environnement pour le build
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Répertoire de travail pour le build
WORKDIR /tmp/build

# Installation des dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un requirements.txt temporaire pour optimiser le cache de build
RUN echo "transformers==4.38.2" >> requirements.txt && \
    echo "torch==2.2.2" >> requirements.txt && \
    echo "flask==3.0.0" >> requirements.txt && \
    echo "flask-cors==4.0.0" >> requirements.txt && \
    echo "soundfile==0.12.1" >> requirements.txt && \
    echo "numpy==1.26.4" >> requirements.txt && \
    echo "accelerate==0.28.0" >> requirements.txt

# Installation des dépendances Python
RUN pip install -r requirements.txt


# --- Final Stage ---
FROM python:3.11.9-slim-bookworm

# Variables d'environnement pour le runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOME=/app \
    TRANSFORMERS_CACHE=/app/.cache/huggingface

# Installation des dépendances système Runtime (pour curl, wget, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root (sans répertoire home)
RUN groupadd -r appuser && useradd -r -g appuser -d /nonexistent -s /sbin/nologin appuser

# Répertoire de travail
WORKDIR /app

# Copie des dépendances installées depuis l'étape de build
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Créer le répertoire de cache pour Hugging Face et définir les permissions
RUN mkdir -p ${TRANSFORMERS_CACHE} && \
    chown -R appuser:appuser /app ${TRANSFORMERS_CACHE}

# Copie du script de téléchargement Turbo et du service Whisper
COPY ./services/whisper-stt/whisper-download-models-turbo.py /app/whisper-download-models-turbo.py
COPY ./services/api-backend/api/whisper_asr_service.py /app/whisper_asr_service.py
COPY ./services/whisper-stt/start.sh /app/start.sh

USER appuser

# Convertir les fins de ligne Windows (CRLF) en Unix (LF) et rendre exécutable
RUN sed -i 's/\r$//' /app/start.sh
RUN chmod +x /app/start.sh

# Exposition du port
EXPOSE 8001

# Commande de démarrage
CMD ["./start.sh"]