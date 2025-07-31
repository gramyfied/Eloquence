# 🛡️ Guide de Robustesse Eloquence - Services Systématiquement Accessibles

## 🎯 Objectif

Ce guide détaille toutes les améliorations de robustesse apportées à l'infrastructure Eloquence pour garantir que **tous les services soient systématiquement accessibles** et résistants aux pannes.

---

## 🔧 Améliorations Apportées

### 1. 🐳 Configuration Docker Compose Renforcée

#### ✅ Politiques de Redémarrage Automatique
- **Avant**: `restart: unless-stopped` ou `restart: on-failure:5`
- **Après**: `restart: always` pour tous les services critiques
- **Bénéfice**: Redémarrage automatique même après un reboot système

#### ✅ Health Checks Optimisés
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 15s      # Vérification toutes les 15s (au lieu de 30s)
  timeout: 5s        # Timeout réduit à 5s
  retries: 5         # 5 tentatives (au lieu de 3)
  start_period: 30s  # Période de grâce augmentée
```

#### ✅ Politiques de Redémarrage Avancées
```yaml
deploy:
  restart_policy:
    condition: any           # Redémarrer dans tous les cas
    delay: 5s               # Délai avant redémarrage
    max_attempts: 10        # Jusqu'à 10 tentatives
    window: 120s            # Fenêtre de surveillance
```

#### ✅ Gestion des Ressources
```yaml
deploy:
  resources:
    limits:
      memory: 2G            # Limite mémoire
    reservations:
      memory: 1G            # Mémoire réservée
```

#### ✅ Logging Structuré
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"         # Rotation des logs
    max-file: "3"           # Garder 3 fichiers
```

### 2. 🗄️ Configuration Redis Optimisée

#### ✅ Persistance Renforcée
- **AOF (Append Only File)**: Activé avec `appendfsync everysec`
- **Sauvegardes automatiques**: `save 900 1`, `save 300 10`, `save 60 10000`
- **Compression**: RDB avec compression et checksum

#### ✅ Sécurité
- Commandes dangereuses désactivées: `FLUSHDB`, `FLUSHALL`, `KEYS`
- Configuration `CONFIG` renommée pour sécurité

#### ✅ Performance
- Politique mémoire: `allkeys-lru` avec limite 512MB
- Optimisations réseau: `tcp-keepalive 300`
- Monitoring: `latency-monitor-threshold 100`

### 3. 🔍 Monitoring et Récupération Automatique

#### ✅ Script de Monitoring Intelligent
**Fichier**: `scripts/monitor-and-recover.sh`

**Fonctionnalités**:
- ✅ Surveillance continue de tous les services (60s)
- ✅ Vérification des conteneurs Docker
- ✅ Tests de santé HTTP et Redis
- ✅ Redémarrage automatique en cas de panne
- ✅ Alertes par email/Slack (configurable)
- ✅ Monitoring des ressources système
- ✅ Nettoyage automatique des logs
- ✅ Sauvegardes automatiques

**Services Surveillés**:
```bash
backend-api (8000:/health)
eloquence-exercises-api (8005:/health)
vosk-stt (8002:/health)
mistral-conversation (8001:/health)
livekit-server (7880:/)
livekit-token-service (8004:/health)
redis (6379:ping)
```

#### ✅ Récupération Automatique
1. **Détection de panne** → 3 tentatives avec délai
2. **Redémarrage du service** → Attente 30s
3. **Vérification post-redémarrage** → Alerte si échec
4. **Escalade** → Notification critique si problème persistant

### 4. 🖥️ Service Systemd pour Démarrage Automatique

#### ✅ Installation Automatisée
**Script**: `scripts/install-systemd-service.sh`

**Services Créés**:
- `eloquence.service` - Service principal
- `eloquence-monitor.service` - Monitoring automatique
- `eloquence-service` - Script de gestion unifié

#### ✅ Fonctionnalités Systemd
```ini
[Service]
Type=forking
Restart=always
RestartSec=10
TimeoutStartSec=300
StartLimitBurst=3
```

**Commandes de Gestion**:
```bash
sudo eloquence-service start     # Démarrer
sudo eloquence-service stop      # Arrêter
sudo eloquence-service restart   # Redémarrer
sudo eloquence-service status    # Statut
sudo eloquence-service enable    # Auto-démarrage
sudo eloquence-service logs      # Logs
```

### 5. 📊 Script de Gestion Amélioré

#### ✅ Nouvelles Commandes
**Fichier**: `eloquence-manage.sh`

```bash
bash eloquence-manage.sh monitor  # Démarrer monitoring
bash eloquence-manage.sh check    # Vérification rapide
bash eloquence-manage.sh backup   # Sauvegarde complète
```

#### ✅ Corrections
- Port API corrigé: 8000 (au lieu de 8080)
- Ajout de l'API Exercices (8005)
- Vérifications de santé améliorées

---

## 🚀 Mise en Œuvre

### Étape 1: Appliquer la Configuration Robuste

```bash
# Redémarrer avec la nouvelle configuration
bash eloquence-manage.sh restart

# Vérifier que tous les services sont opérationnels
bash eloquence-manage.sh check
```

### Étape 2: Installer le Service Systemd (Optionnel)

```bash
# Installation (nécessite sudo)
sudo ./scripts/install-systemd-service.sh

# Activer le démarrage automatique
sudo eloquence-service enable

# Démarrer les services
sudo eloquence-service start
```

### Étape 3: Démarrer le Monitoring

```bash
# Option 1: Via le script de gestion
bash eloquence-manage.sh monitor

# Option 2: Via systemd (si installé)
sudo eloquence-service start

# Option 3: Vérification unique
bash eloquence-manage.sh check
```

---

## 📈 Métriques de Robustesse

### ✅ Temps de Récupération
- **Détection de panne**: < 60 secondes
- **Redémarrage automatique**: < 30 secondes
- **Vérification post-redémarrage**: < 30 secondes
- **Temps total de récupération**: < 2 minutes

### ✅ Disponibilité Cible
- **Uptime visé**: 99.9% (8h45min de downtime/an maximum)
- **MTTR (Mean Time To Recovery)**: < 2 minutes
- **MTBF (Mean Time Between Failures)**: > 30 jours

### ✅ Surveillance
- **Fréquence de monitoring**: 60 secondes
- **Health checks**: 15 secondes
- **Alertes**: Temps réel
- **Logs**: Rotation automatique

---

## 🔧 Configuration Avancée

### Alertes Email/Slack

Éditer `scripts/monitor-and-recover.sh`:
```bash
ALERT_EMAIL="admin@votre-domaine.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/..."
```

### Personnalisation du Monitoring

Modifier les services surveillés:
```bash
declare -A SERVICES=(
    ["votre-service"]="8080:/health"
    # Ajouter d'autres services
)
```

### Optimisation des Ressources

Ajuster les limites dans `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 4G        # Augmenter si nécessaire
      cpus: '2.0'       # Limiter CPU
```

---

## 🛠️ Dépannage

### Problème: Service ne redémarre pas

```bash
# Vérifier les logs
sudo journalctl -u eloquence -f

# Vérifier Docker
sudo docker ps -a
sudo docker logs settings-[service-name]-1

# Redémarrage manuel
bash eloquence-manage.sh restart
```

### Problème: Monitoring ne fonctionne pas

```bash
# Vérifier le script
./scripts/monitor-and-recover.sh --check

# Vérifier les permissions
ls -la scripts/monitor-and-recover.sh

# Logs du monitoring
tail -f logs/monitor.log
```

### Problème: Ressources insuffisantes

```bash
# Vérifier l'utilisation
free -h
df -h
top

# Nettoyer Docker
bash eloquence-manage.sh clean
```

---

## 📋 Checklist de Robustesse

### ✅ Configuration
- [ ] Docker Compose avec `restart: always`
- [ ] Health checks configurés (15s/5s/5 retries)
- [ ] Politiques de redémarrage avancées
- [ ] Limites de ressources définies
- [ ] Logging structuré activé

### ✅ Monitoring
- [ ] Script de monitoring installé et exécutable
- [ ] Services surveillés configurés
- [ ] Alertes configurées (email/Slack)
- [ ] Logs de monitoring fonctionnels

### ✅ Automatisation
- [ ] Service systemd installé (optionnel)
- [ ] Démarrage automatique activé
- [ ] Script de gestion fonctionnel
- [ ] Sauvegardes automatiques configurées

### ✅ Tests
- [ ] Tous les services répondent aux health checks
- [ ] Redémarrage automatique testé
- [ ] Récupération après panne testée
- [ ] Monitoring en continu validé

---

## 🎯 Résultats Attendus

Avec ces améliorations, votre infrastructure Eloquence sera:

### 🛡️ **Hautement Disponible**
- Redémarrage automatique en cas de panne
- Récupération en moins de 2 minutes
- Surveillance continue 24/7

### 🔄 **Auto-Réparatrice**
- Détection proactive des problèmes
- Redémarrage intelligent des services
- Escalade automatique des alertes

### 📊 **Monitorée en Temps Réel**
- Métriques de santé en continu
- Logs structurés et rotatifs
- Alertes instantanées

### 🚀 **Prête pour la Production**
- Configuration enterprise-grade
- Sauvegardes automatiques
- Démarrage automatique au boot

---

## 📞 Support et Maintenance

### Commandes de Diagnostic Rapide

```bash
# Statut complet
bash eloquence-manage.sh status
bash eloquence-manage.sh health

# Logs en temps réel
bash eloquence-manage.sh logs

# Monitoring ponctuel
bash eloquence-manage.sh check

# Sauvegarde manuelle
bash eloquence-manage.sh backup
```

### Maintenance Préventive

```bash
# Nettoyage hebdomadaire
bash eloquence-manage.sh clean

# Mise à jour mensuelle
bash eloquence-manage.sh update

# Vérification des sauvegardes
ls -la backups/auto/
ls -la backups/manual/
```

---

*Guide créé le 31 janvier 2025 - Infrastructure Eloquence Robuste v2.0*
