FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1 \
    ffmpeg \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create models directory
RUN mkdir -p /app/models

# Download VOSK French model
RUN wget -q https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip && \
    unzip -q vosk-model-fr-0.22.zip && \
    mv vosk-model-fr-0.22 /app/models/ && \
    rm vosk-model-fr-0.22.zip

# Copy application code
COPY main.py .

# Set environment variables
ENV VOSK_MODEL_PATH=/app/models/vosk-model-fr-0.22
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 8003

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8003/health || exit 1

# Run the application
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003"]