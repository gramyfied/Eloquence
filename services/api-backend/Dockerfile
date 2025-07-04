# Dockerfile pour l'API Backend Eloquence
# Dockerfile pour l'API Backend Eloquence

# --- Build Stage ---
FROM python:3.11 as builder

# Variables d'environnement pour le build
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Installation des dépendances système pour le build (y compris celles pour livekit CLI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copie des fichiers de requirements et installation des dépendances Python
# L'installation de livekit-agents[silero] garantit que toutes les dépendances VAD sont incluses.
WORKDIR /tmp
COPY services/api-backend/requirements.agent.v1.txt .
RUN pip install --no-cache-dir -r requirements.agent.v1.txt && \
    pip install --no-cache-dir --upgrade 'livekit-agents[silero]'

# Install LiveKit CLI (utilisé dans le binaire final)
ARG TARGETARCH
RUN case ${TARGETARCH} in \
    "amd64") ARCH="amd64" ;; \
    "arm64") ARCH="arm64" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -L -o livekit.tar.gz "https://github.com/livekit/livekit/releases/download/v1.9.0/livekit_1.9.0_linux_${ARCH}.tar.gz" && \
    tar -zxvf livekit.tar.gz && \
    mv livekit-server /usr/local/bin/lk && \
    rm livekit.tar.gz

# --- Final Stage ---
FROM python:3.11.9-slim-bookworm

# Variables d'environnement pour le runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Installation de curl dans l'image finale
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/lk /usr/local/bin/lk


# Copie du code de l'application
COPY services/api-backend/app.py .
COPY services/api-backend/api ./api
COPY services/api-backend/services ./services
COPY services/api-backend/tests ./tests
COPY services/api-backend/wsgi.py .
COPY services/api-backend/start-agent-v1.sh .
COPY services/api-backend/start-both.sh .
COPY services/api-backend/generate_jwt.py .

# Définition de l'utilisateur non-root et changement des permissions
RUN chown -R appuser:appuser /app
USER appuser

# Rendre les scripts exécutables
RUN chmod +x start-agent-v1.sh start-both.sh

# Exposition du port
EXPOSE 8000

# Commande de démarrage qui lance le backend Flask ET l'agent LiveKit
CMD ["./start-both.sh"]