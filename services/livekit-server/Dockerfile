FROM python:3.9-slim

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copier les requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code
COPY main.py .

# Variables d'environnement par défaut
ENV LIVEKIT_API_KEY=devkey
ENV LIVEKIT_API_SECRET=secret
ENV LIVEKIT_URL=ws://localhost:7880

# Exposer le port
EXPOSE 8004

# Lancer l'application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8004", "--reload"]