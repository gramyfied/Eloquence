FROM python:3.11-slim

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copie des requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Crée le répertoire des modèles
RUN mkdir -p /app/models

# Copie le code de l'application
COPY . .

# Script de téléchargement automatique du modèle
COPY download_model.sh /app/
RUN chmod +x /app/download_model.sh

# Télécharge le modèle au build
RUN /app/download_model.sh

EXPOSE 2700

CMD ["python", "main.py"]