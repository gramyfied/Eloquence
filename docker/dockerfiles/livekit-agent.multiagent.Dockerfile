FROM python:3.11-slim

# Optimisations pour système multi-agents amélioré
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    AGENT_TYPE=multi_agent_enhanced

# Installer dépendances système
RUN apt-get update && apt-get install -y \
    curl gcc g++ make ffmpeg libsndfile1 portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier et installer dépendances Python
WORKDIR /app
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r ./requirements.txt

# Copier le code source
COPY . .

# Créer utilisateur non-root
RUN useradd -m -u 1000 agent && chown -R agent:agent /app
USER agent

# Point d'entrée: routeur unifié (multi-agents + individuel)
CMD ["sh", "-c", "python -u health_server.py & exec python -u unified_entrypoint.py start"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1