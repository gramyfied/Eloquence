# Dockerfile pour OpenAI TTS Service

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
    curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un requirements.txt temporaire pour optimiser le cache de build
RUN echo "fastapi==0.104.1" >> requirements.txt && \
    echo "uvicorn==0.24.0" >> requirements.txt && \
    echo "requests==2.31.0" >> requirements.txt && \
    echo "python-multipart==0.0.6" >> requirements.txt && \
    echo "aiofiles==23.2.1" >> requirements.txt # Version figée, à vérifier si une version plus récente est nécessaire

# Installation des dépendances Python
RUN pip install -r requirements.txt


# --- Final Stage ---
FROM python:3.11.9-slim-bookworm

# Variables d'environnement pour le runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Installation des dépendances système Runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Répertoire de travail
WORKDIR /app

# Copie des dépendances installées depuis l'étape de build, incluant les scripts exécutables
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copie du service TTS OpenAI
COPY services/api-backend/services/tts_service_openai.py .

# Définition de l'utilisateur non-root et changement des permissions
RUN chown -R appuser:appuser /app
USER appuser

# Exposition du port
EXPOSE 5002

# Commande de démarrage
CMD ["uvicorn", "tts_service_openai:app", "--host", "0.0.0.0", "--port", "5002"]