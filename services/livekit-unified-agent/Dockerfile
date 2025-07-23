# === DOCKERFILE POUR AGENT LIVEKIT UNIFIÉ ===
FROM python:3.11-slim

# Métadonnées
LABEL maintainer="Eloquence Team"
LABEL description="Agent LiveKit unifié pour exercices Confidence Boost"
LABEL version="1.0.0"

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV LIVEKIT_URL=ws://localhost:7880
ENV LIVEKIT_ROOM=confidence-boost
ENV VOSK_URL=http://localhost:8002
ENV MISTRAL_URL=http://localhost:8001

# Installation des dépendances système pour l'audio
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    pkg-config \
    libffi-dev \
    libssl-dev \
    libasound2-dev \
    portaudio19-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Création utilisateur non-root
RUN useradd --create-home --shell /bin/bash agent
USER agent
WORKDIR /home/agent/app

# Installation des dépendances Python
COPY --chown=agent:agent requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Copie du code source
COPY --chown=agent:agent main.py .

# Création des répertoires de travail
RUN mkdir -p logs temp

# Configuration des permissions
USER root
RUN chown -R agent:agent /home/agent/app
USER agent

# Exposition des ports (pour monitoring/debug)
EXPOSE 8080

# Vérification de santé
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import asyncio; print('Agent OK')" || exit 1

# Point d'entrée avec gestion des signaux
CMD ["python", "-u", "main.py"]
