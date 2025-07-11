# Guide de Maintenance et Déploiement - Système Hybride VOSK + Whisper

## Table des Matières

1. [Procédures de Déploiement](#procédures-de-déploiement)
2. [Maintenance Opérationnelle](#maintenance-opérationnelle)
3. [Monitoring et Alertes](#monitoring-et-alertes)
4. [Procédures de Dépannage](#procédures-de-dépannage)
5. [Mises à Jour et Évolutions](#mises-à-jour-et-évolutions)
6. [Sauvegarde et Récupération](#sauvegarde-et-récupération)
7. [Sécurité Opérationnelle](#sécurité-opérationnelle)
8. [Procédures d'Urgence](#procédures-durgence)

---

## Procédures de Déploiement

### 1. **Déploiement Initial**

#### **Prérequis Système**
```bash
# Serveur minimum requis
CPU: 4 cores
RAM: 8GB
Stockage: 50GB SSD
OS: Ubuntu 20.04+ / CentOS 8+
Docker: 24.0+
Docker Compose: 2.0+
```

#### **Installation Pas à Pas**

##### **Étape 1 : Préparation Environnement**
```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Installation Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installation Docker Compose
sudo apt install docker-compose-plugin

# Vérification
docker --version
docker compose version
```

##### **Étape 2 : Clonage et Configuration**
```bash
# Clonage du projet
git clone <repository-url> eloquence-hybrid
cd eloquence-hybrid

# Configuration environnement
cp .env.example .env
nano .env

# Variables essentielles à configurer
HYBRID_SERVICE_PORT=8002
WHISPER_SERVICE_URL=http://whisper-large-v3-turbo:8001
VOSK_MODEL_PATH=/opt/vosk/models/vosk-model-fr-0.22
MAX_CONCURRENT_SESSIONS=100
LOG_LEVEL=INFO
```

##### **Étape 3 : Téléchargement Modèles**
```bash
# Création répertoire modèles
sudo mkdir -p /opt/vosk/models
cd /opt/vosk/models

# Téléchargement modèle VOSK français
sudo wget https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip
sudo unzip vosk-model-fr-0.22.zip
sudo rm vosk-model-fr-0.22.zip

# Permissions
sudo chown -R 1000:1000 /opt/vosk/models
```

##### **Étape 4 : Build et Démarrage**
```bash
# Build des images
docker compose build

# Démarrage des services
docker compose up -d

# Vérification statut
docker compose ps
docker compose logs -f hybrid-speech-evaluation
```

##### **Étape 5 : Tests de Validation**
```bash
# Test santé service hybride
curl http://localhost:8002/health

# Test WebSocket (optionnel)
wscat -c ws://localhost:8002/ws/realtime

# Tests automatisés
cd services/hybrid-speech-evaluation
python -m pytest tests/ -v
```

### 2. **Script de Déploiement Automatisé**

```bash
#!/bin/bash
# deploy-hybrid.sh

set -e

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}

echo "🚀 Déploiement Système Hybride - Version: $VERSION"

# Validation prérequis
echo "📋 Vérification prérequis..."
docker --version || exit 1
docker compose version || exit 1

# Sauvegarde configuration actuelle
echo "💾 Sauvegarde configuration..."
docker compose config > backup-compose-$(date +%Y%m%d-%H%M%S).yml

# Pull nouvelle version
echo "📥 Téléchargement nouvelle version..."
git fetch --tags
git checkout v$VERSION

# Build nouvelle image
echo "🔨 Construction image..."
docker compose build --no-cache hybrid-speech-evaluation

# Tests de santé sur nouvelle image
echo "🧪 Tests de validation..."
docker compose run --rm hybrid-speech-evaluation python -m pytest tests/test_health.py

# Déploiement rolling update
echo "🔄 Déploiement rolling..."
docker compose up -d --scale hybrid-speech-evaluation=2
sleep 30

# Validation nouveau déploiement
echo "✅ Validation déploiement..."
for i in {1..5}; do
    if curl -f http://localhost:8002/health; then
        echo "✅ Service opérationnel"
        break
    fi
    echo "⏳ Attente service... ($i/5)"
    sleep 10
done

# Nettoyage anciennes images
echo "🧹 Nettoyage..."
docker image prune -f
docker volume prune -f

echo "🎉 Déploiement terminé avec succès!"
```

---

## Maintenance Opérationnelle

### 1. **Routines de Maintenance Quotidienne**

#### **Script de Vérification Quotidienne**
```bash
#!/bin/bash
# daily-check.sh

echo "🔍 Vérification quotidienne - $(date)"

# Statut des services
echo "📊 Statut des services:"
docker compose ps

# Utilisation ressources
echo "💾 Utilisation ressources:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Logs d'erreur récents
echo "🚨 Erreurs récentes (24h):"
docker compose logs --since=24h hybrid-speech-evaluation | grep -i error | tail -10

# Espace disque
echo "💿 Espace disque:"
df -h /var/lib/docker
du -sh /opt/vosk/models

# Sessions actives
echo "👥 Sessions actives:"
curl -s http://localhost:8002/status | jq '.active_sessions'

# Test de santé complet
echo "🏥 Test de santé:"
curl -s http://localhost:8002/health | jq '.'

echo "✅ Vérification terminée"
```

#### **Automatisation Cron**
```bash
# Ajout dans crontab
crontab -e

# Vérification quotidienne à 8h00
0 8 * * * /opt/eloquence/scripts/daily-check.sh >> /var/log/eloquence/daily-check.log

# Nettoyage hebdomadaire dimanche 2h00
0 2 * * 0 /opt/eloquence/scripts/weekly-cleanup.sh

# Sauvegarde quotidienne à 3h00
0 3 * * * /opt/eloquence/scripts/backup.sh
```

### 2. **Maintenance Hebdomadaire**

#### **Script de Nettoyage Hebdomadaire**
```bash
#!/bin/bash
# weekly-cleanup.sh

echo "🧹 Nettoyage hebdomadaire - $(date)"

# Nettoyage conteneurs arrêtés
docker container prune -f

# Nettoyage images non utilisées
docker image prune -f

# Nettoyage volumes orphelins
docker volume prune -f

# Nettoyage réseaux non utilisés
docker network prune -f

# Rotation des logs
find /var/log/eloquence -name "*.log" -mtime +7 -delete

# Redémarrage containers pour RAM
docker compose restart hybrid-speech-evaluation

echo "✅ Nettoyage terminé"
```

### 3. **Monitoring des Performances**

#### **Script de Monitoring Performance**
```bash
#!/bin/bash
# performance-monitor.sh

# Collecte métriques système
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)

# Métriques service hybride
ACTIVE_SESSIONS=$(curl -s http://localhost:8002/status | jq '.active_sessions')
RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:8002/health)

# Log des métriques
echo "$TIMESTAMP,CPU:$CPU_USAGE,MEM:$MEMORY_USAGE,DISK:$DISK_USAGE,SESSIONS:$ACTIVE_SESSIONS,RESPONSE:$RESPONSE_TIME" >> /var/log/eloquence/performance.csv

# Alertes seuils
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "⚠️ ALERTE: CPU usage élevé: $CPU_USAGE%"
fi

if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "⚠️ ALERTE: Mémoire usage élevé: $MEMORY_USAGE%"
fi
```

---

## Monitoring et Alertes

### 1. **Configuration Monitoring**

#### **Métriques Critiques à Surveiller**
```bash
# Disponibilité service
SERVICE_STATUS="curl -f http://localhost:8002/health"

# Latence WebSocket
WEBSOCKET_LATENCY="wscat -c ws://localhost:8002/ws/realtime --timeout 5000"

# Utilisation ressources
CPU_THRESHOLD=80      # %
MEMORY_THRESHOLD=85   # %
DISK_THRESHOLD=90     # %

# Sessions concurrentes
MAX_SESSIONS=100
```

#### **Script de Monitoring Temps Réel**
```bash
#!/bin/bash
# realtime-monitor.sh

while true; do
    # Vérification santé service
    if ! curl -f -s http://localhost:8002/health > /dev/null; then
        echo "🚨 CRITIQUE: Service hybride indisponible"
        # Envoyer alerte
    fi
    
    # Vérification sessions actives
    SESSIONS=$(curl -s http://localhost:8002/status | jq '.active_sessions')
    if [ "$SESSIONS" -gt 90 ]; then
        echo "⚠️ ATTENTION: Proche de la limite de sessions: $SESSIONS/100"
    fi
    
    # Vérification logs d'erreur
    ERRORS=$(docker compose logs --since=1m hybrid-speech-evaluation | grep -c ERROR)
    if [ "$ERRORS" -gt 5 ]; then
        echo "🚨 ALERTE: Taux d'erreur élevé: $ERRORS erreurs/minute"
    fi
    
    sleep 60
done
```

### 2. **Alertes par Email/Slack**

#### **Configuration Alertes**
```bash
#!/bin/bash
# alert-config.sh

# Configuration email
SMTP_SERVER="smtp.company.com"
ALERT_EMAIL="devops@company.com"

# Configuration Slack
SLACK_WEBHOOK="https://hooks.slack.com/services/..."
SLACK_CHANNEL="#eloquence-alerts"

# Fonction envoi alerte
send_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Email
    echo "Subject: [Eloquence $severity] $message" | \
    mail -s "[Eloquence] $severity Alert" $ALERT_EMAIL
    
    # Slack
    curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"🚨 *Eloquence $severity*\n$message\n_$timestamp_\"}" \
    $SLACK_WEBHOOK
}
```

### 3. **Dashboard de Monitoring**

#### **Métriques à Afficher**
```bash
# Statut services
- Service Hybride (port 8002)
- Service Whisper (port 8001)  
- Base de données

# Performance temps réel
- Sessions actives
- Latence moyenne WebSocket
- Throughput audio (chunks/s)
- Taux d'erreur

# Ressources système
- CPU usage
- Memory usage
- Disk usage
- Network I/O

# Métriques métier
- Transcriptions réussies/échouées
- Temps moyen de traitement
- Qualité des transcriptions
```

---

## Procédures de Dépannage

### 1. **Diagnostic Rapide**

#### **Script de Diagnostic Global**
```bash
#!/bin/bash
# quick-diagnosis.sh

echo "🔍 Diagnostic rapide du système hybride"

# 1. Vérification connectivité
echo "📡 Test connectivité:"
ping -c 3 localhost
curl -I http://localhost:8002/health

# 2. Statut containers
echo "🐳 Statut containers:"
docker compose ps

# 3. Logs récents
echo "📝 Logs récents (5 min):"
docker compose logs --since=5m --tail=20

# 4. Utilisation ressources
echo "💾 Ressources:"
docker stats --no-stream

# 5. Test WebSocket
echo "🔌 Test WebSocket:"
timeout 5 wscat -c ws://localhost:8002/ws/realtime

# 6. Vérification modèles
echo "🧠 Modèles VOSK:"
ls -la /opt/vosk/models/

echo "✅ Diagnostic terminé"
```

### 2. **Problèmes Fréquents et Solutions**

#### **Service ne démarre pas**
```bash
# Symptôme: Container se ferme immédiatement
# Solution:
docker compose logs hybrid-speech-evaluation

# Vérifications:
1. Modèle VOSK présent: ls /opt/vosk/models/
2. Permissions: chown -R 1000:1000 /opt/vosk/models
3. Port disponible: netstat -tulpn | grep 8002
4. Variables environnement: docker compose config
```

#### **Performance dégradée**
```bash
# Symptôme: Latence élevée, timeouts
# Solution:
1. Vérifier charge CPU/RAM:
   docker stats hybrid-speech-evaluation

2. Redimensionner si nécessaire:
   docker update --memory=4g --cpus=2 hybrid-speech-evaluation

3. Nettoyer cache:
   docker system prune -f

4. Redémarrer service:
   docker compose restart hybrid-speech-evaluation
```

#### **WebSocket se déconnecte**
```bash
# Symptôme: Connexions WebSocket instables
# Solution:
1. Vérifier configuration réseau:
   nano docker-compose.yml
   # Ajouter: network_mode: "host"

2. Ajuster timeouts:
   # Dans main.py
   websocket_timeout = 60.0
   keepalive_interval = 30.0

3. Vérifier proxy/load balancer:
   # Configuration Nginx
   proxy_read_timeout 86400;
   proxy_send_timeout 86400;
```

### 3. **Logs et Debugging**

#### **Configuration Logs Détaillés**
```python
# services/hybrid-speech-evaluation/logging_config.py
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps({
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        })

# Configuration dans main.py
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/hybrid-service.log'),
        logging.StreamHandler()
    ]
)
```

#### **Commandes de Debug Utiles**
```bash
# Logs en temps réel
docker compose logs -f hybrid-speech-evaluation

# Logs avec grep pour erreurs
docker compose logs hybrid-speech-evaluation | grep -i error

# Accès shell container
docker compose exec hybrid-speech-evaluation bash

# Test direct VOSK
docker compose exec hybrid-speech-evaluation python -c "
from services.vosk_realtime_service import VoskRealtimeService
service = VoskRealtimeService()
print('VOSK initialisé:', service.model is not None)
"

# Test direct Whisper
curl -X POST http://localhost:8001/transcribe \
  -H "Content-Type: multipart/form-data" \
  -F "audio=@test_audio.wav"
```

---

## Mises à Jour et Évolutions

### 1. **Procédure de Mise à Jour**

#### **Mise à Jour Mineure (Patch)**
```bash
#!/bin/bash
# update-patch.sh

VERSION=$1
echo "🔄 Mise à jour patch vers $VERSION"

# Sauvegarde
docker compose exec hybrid-speech-evaluation cp -r /app/data /backup/

# Pull nouvelle version
git fetch
git checkout v$VERSION

# Rebuild sans cache
docker compose build --no-cache hybrid-speech-evaluation

# Rolling update
docker compose up -d hybrid-speech-evaluation

# Validation
sleep 30
curl -f http://localhost:8002/health || {
    echo "❌ Rollback nécessaire"
    git checkout -
    docker compose up -d hybrid-speech-evaluation
    exit 1
}

echo "✅ Mise à jour réussie"
```

#### **Mise à Jour Majeure**
```bash
#!/bin/bash
# update-major.sh

echo "🚀 Mise à jour majeure - Mode maintenance"

# Activer mode maintenance
curl -X POST http://localhost:8002/admin/maintenance-mode

# Attendre fin sessions actives
while [ $(curl -s http://localhost:8002/status | jq '.active_sessions') -gt 0 ]; do
    echo "⏳ Attente fin sessions..."
    sleep 10
done

# Sauvegarde complète
./backup.sh

# Mise à jour
git pull origin main
docker compose build
docker compose up -d

# Tests post-mise à jour
./run-tests.sh

# Désactiver mode maintenance
curl -X POST http://localhost:8002/admin/maintenance-mode -d '{"enabled": false}'

echo "✅ Mise à jour majeure terminée"
```

### 2. **Migration des Données**

#### **Script de Migration**
```python
#!/usr/bin/env python3
# migrate-data.py

import json
import sqlite3
from pathlib import Path

def migrate_session_data():
    """Migration format sessions v1 -> v2"""
    
    # Connexion base
    conn = sqlite3.connect('/app/data/sessions.db')
    
    # Lecture anciennes sessions
    old_sessions = conn.execute(
        "SELECT * FROM sessions WHERE version < 2"
    ).fetchall()
    
    for session in old_sessions:
        # Conversion format
        new_data = {
            'session_id': session[0],
            'vosk_results': json.loads(session[1]) if session[1] else [],
            'whisper_result': json.loads(session[2]) if session[2] else {},
            'prosody_metrics': calculate_new_metrics(session),
            'version': 2
        }
        
        # Mise à jour
        conn.execute(
            "UPDATE sessions SET data=?, version=2 WHERE id=?",
            (json.dumps(new_data), session[0])
        )
    
    conn.commit()
    conn.close()
    print(f"✅ Migré {len(old_sessions)} sessions")

if __name__ == "__main__":
    migrate_session_data()
```

### 3. **Tests de Régression**

#### **Suite de Tests Post-Mise à Jour**
```bash
#!/bin/bash
# regression-tests.sh

echo "🧪 Tests de régression post-mise à jour"

# Tests API de base
echo "1. Tests API:"
curl -f http://localhost:8002/health
curl -f http://localhost:8002/status

# Tests WebSocket
echo "2. Tests WebSocket:"
timeout 10 wscat -c ws://localhost:8002/ws/realtime -x '{"type":"start_session"}'

# Tests end-to-end
echo "3. Tests E2E:"
cd services/hybrid-speech-evaluation
python -m pytest tests/test_integration.py -v

# Tests performance
echo "4. Tests performance:"
python -m pytest tests/test_performance.py -m "not slow"

# Tests compatibilité
echo "5. Tests compatibilité:"
python test_backward_compatibility.py

echo "✅ Tests de régression terminés"
```

---

## Sauvegarde et Récupération

### 1. **Stratégie de Sauvegarde**

#### **Script de Sauvegarde Automatique**
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/eloquence"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "💾 Sauvegarde démarrée: $BACKUP_PATH"

# Création répertoire
mkdir -p $BACKUP_PATH

# 1. Configuration Docker
docker compose config > $BACKUP_PATH/docker-compose.yml
cp .env $BACKUP_PATH/

# 2. Données application
docker compose exec -T hybrid-speech-evaluation tar czf - /app/data \
  > $BACKUP_PATH/app-data.tar.gz

# 3. Modèles VOSK
tar czf $BACKUP_PATH/vosk-models.tar.gz /opt/vosk/models/

# 4. Logs récents
docker compose logs --since=24h > $BACKUP_PATH/recent-logs.txt

# 5. État des containers
docker compose ps > $BACKUP_PATH/containers-status.txt

# 6. Base de données (si applicable)
if [ -f "/app/data/sessions.db" ]; then
    docker compose exec -T hybrid-speech-evaluation \
      sqlite3 /app/data/sessions.db .dump > $BACKUP_PATH/sessions.sql
fi

# Compression finale
cd $BACKUP_DIR
tar czf backup_$TIMESTAMP.tar.gz backup_$TIMESTAMP/
rm -rf backup_$TIMESTAMP/

# Nettoyage anciennes sauvegardes (>30 jours)
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +30 -delete

echo "✅ Sauvegarde terminée: backup_$TIMESTAMP.tar.gz"
```

#### **Sauvegarde Continue des Sessions Actives**
```python
# backup_service.py
import asyncio
import json
import time
from pathlib import Path

class SessionBackupService:
    def __init__(self):
        self.backup_path = Path("/app/backups/sessions")
        self.backup_path.mkdir(exist_ok=True)
        
    async def backup_active_sessions(self):
        """Sauvegarde continue des sessions actives"""
        while True:
            try:
                # Récupération sessions actives
                active_sessions = await self.get_active_sessions()
                
                # Sauvegarde chaque session
                for session_id, session_data in active_sessions.items():
                    backup_file = self.backup_path / f"{session_id}.json"
                    
                    with open(backup_file, 'w') as f:
                        json.dump({
                            'session_id': session_id,
                            'data': session_data,
                            'backup_time': time.time()
                        }, f)
                
                await asyncio.sleep(30)  # Sauvegarde toutes les 30s
                
            except Exception as e:
                print(f"Erreur sauvegarde sessions: {e}")
                await asyncio.sleep(60)
```

### 2. **Procédures de Récupération**

#### **Restauration Complète**
```bash
#!/bin/bash
# restore.sh

BACKUP_FILE=$1
RESTORE_DIR="/tmp/restore_$(date +%s)"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./restore.sh backup_YYYYMMDD_HHMMSS.tar.gz"
    exit 1
fi

echo "🔄 Restauration depuis: $BACKUP_FILE"

# 1. Arrêt services
docker compose down

# 2. Extraction sauvegarde
mkdir -p $RESTORE_DIR
tar xzf $BACKUP_FILE -C $RESTORE_DIR

# 3. Restauration configuration
cp $RESTORE_DIR/backup_*/docker-compose.yml .
cp $RESTORE_DIR/backup_*/.env .

# 4. Restauration données
docker volume rm eloquence_app_data 2>/dev/null || true
docker volume create eloquence_app_data
docker run --rm -v eloquence_app_data:/data -v $RESTORE_DIR:/backup \
  ubuntu tar xzf /backup/backup_*/app-data.tar.gz -C /data --strip-components=2

# 5. Restauration modèles
sudo rm -rf /opt/vosk/models/*
sudo tar xzf $RESTORE_DIR/backup_*/vosk-models.tar.gz -C / --strip-components=3

# 6. Redémarrage
docker compose up -d

# 7. Validation
sleep 30
curl -f http://localhost:8002/health || {
    echo "❌ Restauration échouée"
    exit 1
}

echo "✅ Restauration réussie"
rm -rf $RESTORE_DIR
```

#### **Récupération Session Spécifique**
```bash
#!/bin/bash
# recover-session.sh

SESSION_ID=$1
BACKUP_PATH="/app/backups/sessions"

if [ -z "$SESSION_ID" ]; then
    echo "Usage: ./recover-session.sh <session_id>"
    exit 1
fi

echo "🔄 Récupération session: $SESSION_ID"

# Recherche sauvegarde
BACKUP_FILE="$BACKUP_PATH/$SESSION_ID.json"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Sauvegarde session non trouvée"
    exit 1
fi

# Restauration via API
curl -X POST http://localhost:8002/admin/restore-session \
  -H "Content-Type: application/json" \
  -d @$BACKUP_FILE

echo "✅ Session récupérée"
```

---

## Sécurité Opérationnelle

### 1. **Configuration Sécurisée**

#### **Variables d'Environnement Sécurisées**
```bash
# .env.production
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=WARNING

# Sécurité réseau
ALLOWED_HOSTS=localhost,api.eloquence.com
CORS_ORIGINS=https://app.eloquence.com

# Authentification
JWT_SECRET_KEY=<secret-key-fort>
API_KEY_REQUIRED=true

# Limitations
MAX_CONCURRENT_SESSIONS=50
MAX_AUDIO_SIZE=10MB
SESSION_TIMEOUT=1800

# Monitoring
ENABLE_METRICS=true
METRICS_AUTH_TOKEN=<token-securise>
```

#### **Configuration Firewall**
```bash
#!/bin/bash
# setup-firewall.sh

# Politique par défaut : tout bloquer
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH (port personnalisé)
ufw allow 22022/tcp

# Services Eloquence
ufw allow 8002/tcp comment "Service Hybride"
ufw allow from 10.0.0.0/8 to any port 8001 comment "Whisper interne"

# Monitoring
ufw allow from 192.168.1.0/24 to any port 9090 comment "Prometheus"

# Activation
ufw --force enable
ufw status verbose
```

### 2. **Audit et Logs Sécurisé**

#### **Configuration Logs Audit**
```python
# security_logger.py
import logging
import json
from datetime import datetime

security_logger = logging.getLogger('security')
security_handler = logging.FileHandler('/var/log/eloquence/security.log')
security_handler.setFormatter(logging.Formatter('%(message)s'))
security_logger.addHandler(security_handler)
security_logger.setLevel(logging.INFO)

def log_security_event(event_type, details):
    """Log d'événement sécuritaire"""
    event = {
        'timestamp': datetime.utcnow().isoformat(),
        'type': event_type,
        'details': details,
        'severity': 'INFO'
    }
    security_logger.info(json.dumps(event))

# Exemples d'usage:
# log_security_event('AUTH_FAILED', {'ip': '192.168.1.100', 'user': 'admin'})
# log_security_event('SUSPICIOUS_ACTIVITY', {'session_id': 'xxx', 'reason': 'too_many_requests'})
```

#### **Monitoring Sécuritaire**
```bash
#!/bin/bash
# security-monitor.sh

# Détection tentatives d'intrusion
FAILED_LOGINS=$(grep "AUTH_FAILED" /var/log/eloquence/security.log | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "🚨 ALERTE: $FAILED_LOGINS tentatives d'authentification échouées"
fi

# Détection utilisation anormale
SESSIONS_COUNT=$(curl -s http://localhost:8002/status | jq '.active_sessions')
if [ $SESSIONS_COUNT -gt 80 ]; then
    echo "⚠️ ATTENTION: Utilisation élevée - $SESSIONS_COUNT sessions"
fi

# Vérification intégrité fichiers
if ! sha256sum -c /etc/eloquence/checksums.txt > /dev/null 2>&1; then
    echo "🚨 CRITIQUE: Intégrité fichiers compromise"
fi
```

### 3. **Mise à Jour Sécuritaires**

#### **Patch de Sécurité Automatique**
```bash
#!/bin/bash
# security-updates.sh

echo "🔒 Application patches de sécurité"

# Mise à jour système
apt update && apt upgrade -y

# Mise à jour images Docker
docker compose pull

# Scan vulnérabilités
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image eloquence/hybrid-speech-evaluation:latest

# Redémarrage si nécessaire
if [ -f /var/run/reboot-required ]; then
    echo "⚠️ Redémarrage requis pour patches noyau"
    # Planifier redémarrage maintenance
fi

echo "✅ Patches sécurité appliqués"
```

---

## Procédures d'Urgence

### 1. **Plan de Continuité d'Activité**

#### **Procédure d'Urgence Générale**
```bash
#!/bin/bash
# emergency-response.sh

INCIDENT_TYPE=$1

echo "🚨 PROCÉDURE D'URGENCE ACTIVÉE - Type: $INCIDENT_TYPE"

case $INCIDENT_TYPE in
    "service_down")
        echo "🔄 Service principal indisponible"
        
        # 1. Diagnostic rapide
        ./quick-diagnosis.sh
        
        # 2. Tentative redémarrage
        docker compose restart hybrid-speech-evaluation
        sleep 30
        
        # 3. Validation
        if curl -f http://localhost:8002/health; then
            echo "✅ Service restauré"
            exit 0
        fi
        
        # 4. Fallback service de secours
        echo "🔄 Activation service de secours"
        docker run -d -p 8002:8002 eloquence/emergency-fallback:latest
        ;;
        
    "high_load")
        echo "⚠️ Charge système critique"
        
        # 1. Scale horizontal immédiat
        docker compose up -d --scale hybrid-speech-evaluation=3
        
        # 2. Limitation nouvelles sessions
        curl -X POST http://localhost:8002/admin/limit-sessions -d '{"max":10}'
        
        # 3. Notification équipe
        send_alert "CRITICAL" "Charge système critique - Scaling activé"
        ;;
        
    "security_breach")
        echo "🔒 Incident sécurité détecté"
        
        # 1. Isolation immédiate
        ufw deny in
        
        # 2. Sauvegarde logs
        cp -r /var/log/eloquence /backup/incident-$(date +%s)/
        
        # 3. Notification urgente
        send_alert "SECURITY" "Incident sécurité - Système isolé"
        ;;
esac
```

### 2. **Fallback Service d'Urgence**

#### **Service Minimal de Secours**
```python
# emergency_service.py
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Eloquence Emergency Service")

@app.get("/health")
async def health():
    return {"status": "emergency_mode", "message": "Service principal indisponible"}

@app.post("/transcribe")
async def emergency_transcribe():
    return {
        "transcription": "Service temporairement indisponible. Veuillez réessayer plus tard.",
        "confidence": 0.0,
        "mode": "emergency"
    }

@app.get("/status")
async def status():
    return {
        "active_sessions": 0,
        "mode": "emergency",
        "message": "Mode de secours activé"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
```

### 3. **Récupération Post-Incident**

#### **Checklist de Récupération**
```bash
#!/bin/bash
# post-incident-recovery.sh

echo "🔄 Procédure de récupération post-incident"

# 1. Validation sécurité
echo "1. Validation sécurité système..."
./security-audit.sh

# 2. Vérification intégrité données
echo "2. Vérification intégrité données..."
./check-data-integrity.sh

# 3. Tests fonctionnels complets
echo "3. Tests fonctionnels..."
./full-functional-tests.sh

# 4. Validation performance
echo "4. Tests performance..."
./performance-baseline.sh

# 5. Restauration service normal
echo "5. Restauration service normal..."
docker compose up -d
sleep 60

# 6. Validation finale
echo "6. Validation finale..."
if curl -f http://localhost:8002/health && \
   [ $(curl -s http://localhost:8002/status | jq '.mode') = '"normal"' ]; then
    echo "✅ Récupération complète réussie"
    send_alert "INFO" "Système restauré - Fonctionnement normal"
else
    echo "❌ Récupération échouée"
    send_alert "CRITICAL" "Échec récupération système"
    exit 1
fi

# 7. Rapport d'incident
echo "7. Génération rapport d'incident..."
./generate-incident-report.sh
```

### 4. **Contacts et Escalade**

#### **Plan d'Escalade**
```bash
# Plan d'escalade incidents

# Niveau 1 - Équipe technique (0-30 min)
TECH_TEAM="tech-team@eloquence.com"
TECH_PHONE="+33123456789"

# Niveau 2 - Lead technique (30-60 min)
TECH_LEAD="tech-lead@eloquence.com" 
TECH_LEAD_PHONE="+33123456790"

# Niveau 3 - Management (1-2h)
MANAGEMENT="management@eloquence.com"
MANAGEMENT_PHONE="+33123456791"

# Niveau 4 - Direction (2h+)
EXECUTIVE="executive@eloquence.com"
EXECUTIVE_PHONE="+33123456792"

# Services externes
HOSTING_SUPPORT="support@hosting-provider.com"
SECURITY_VENDOR="security@vendor.com"
```

---

## Conclusion

Ce guide de maintenance et déploiement fournit tous les outils et procédures nécessaires pour :

- **Déployer** le système hybride VOSK + Whisper de manière fiable
- **Maintenir** les services en conditions opérationnelles optimales  
- **Surveiller** les performances et détecter les problèmes
- **Dépanner** efficacement les incidents
- **Récupérer** rapidement en cas de panne
- **Sécuriser** l'infrastructure en continu

**Points clés à retenir :**

1. **Automatisation** : Tous les scripts sont automatisables via cron
2. **Monitoring** : Surveillance continue des métriques critiques
3. **Sauvegarde** : Stratégie de sauvegarde robuste et testée
4. **Sécurité** : Procédures de sécurité intégrées
5. **Urgence** : Plans d'urgence et de récupération documentés

**Prochaines étapes recommandées :**

- Adapter les scripts à votre environnement spécifique
- Tester toutes les procédures en environnement de staging
- Former l'équipe aux procédures d'urgence
- Mettre en place le monitoring automatisé
- Planifier les exercices de récupération périodiques

Pour toute question technique, consultez la [documentation architecture](ARCHITECTURE_HYBRIDE_VOSK_WHISPER.md).