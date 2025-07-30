# Guide de Déploiement - Application Eloquence

Ce guide vous accompagne dans le déploiement de l'application Eloquence (Backend Python + Frontend Flutter) sur votre serveur distant.

## 📋 Prérequis

### Système
- **OS**: Ubuntu 20.04+ ou Debian 10+
- **RAM**: Minimum 2GB (recommandé 4GB+)
- **Stockage**: Minimum 10GB d'espace libre
- **Accès**: Droits sudo sur le serveur

### Logiciels requis
- Docker
- Docker Compose
- Git (pour cloner le projet)
- Curl (pour les tests)

## 🚀 Installation rapide

### 1. Préparation du serveur

```bash
# Se connecter au serveur
ssh your-user@your-server-ip

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer les dépendances
sudo apt install -y git curl docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 2. Déploiement automatique

```bash
# Aller dans le répertoire de l'application
cd /home/eloquence/app

# Lancer le déploiement
./scripts/deploy.sh
```

## 📁 Structure du projet

```
/home/eloquence/app/
├── backend/                # Application Python (FastAPI)
│   ├── main.py            # Point d'entrée de l'API
│   ├── requirements.txt   # Dépendances Python
│   ├── Dockerfile         # Image Docker backend
│   └── .dockerignore      # Fichiers ignorés
├── frontend/              # Application Flutter
│   ├── lib/
│   │   └── main.dart      # Application Flutter
│   ├── web/
│   │   └── index.html     # Template HTML
│   ├── pubspec.yaml       # Configuration Flutter
│   ├── Dockerfile         # Image Docker frontend
│   ├── nginx.conf         # Configuration Nginx pour Flutter
│   └── .dockerignore      # Fichiers ignorés
├── nginx/                 # Configuration Nginx (reverse proxy)
│   ├── nginx.conf         # Configuration principale
│   └── ssl/
│       └── generate-certs.sh  # Génération certificats SSL
├── scripts/               # Scripts de déploiement
│   ├── deploy.sh          # Déploiement complet
│   ├── update.sh          # Mise à jour
│   └── stop.sh            # Arrêt
├── docker-compose.yml     # Orchestration des conteneurs
└── README.md              # Documentation principale
```

## 🐳 Services Docker

L'application est composée de 3 services principaux :

### 1. Backend (eloquence-backend)
- **Port**: 8000
- **Framework**: FastAPI
- **Base de données**: SQLite (en mémoire pour la démo)
- **Health check**: `http://localhost:8000/health`

### 2. Frontend (eloquence-frontend)
- **Port**: 3000 (interne)
- **Framework**: Flutter Web
- **Serveur**: Nginx
- **Build**: Production optimisée

### 3. Nginx (eloquence-nginx)
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Rôle**: Reverse proxy + Load balancer
- **SSL**: Certificats auto-signés (développement)

## 🔧 Configuration

### Variables d'environnement

Vous pouvez modifier ces variables dans [`docker-compose.yml`](../docker-compose.yml:13) :

```yaml
environment:
  - ENV=production
  - DATABASE_URL=sqlite:///./app.db
  - PYTHONPATH=/app
```

### Ports

- **80**: Application web (HTTP)
- **443**: Application web (HTTPS)
- **8000**: API Backend (accès direct)
- **3000**: Frontend Flutter (accès direct)

### SSL/TLS

Par défaut, des certificats auto-signés sont générés pour le développement. Pour la production :

1. Remplacez les certificats dans `nginx/ssl/`
2. Modifiez la configuration dans [`nginx/nginx.conf`](../nginx/nginx.conf:75)

## 📚 Commandes utiles

### Scripts de gestion

```bash
# Déploiement initial
./scripts/deploy.sh

# Mise à jour de l'application
./scripts/update.sh

# Arrêt de l'application
./scripts/stop.sh
```

### Commandes Docker

```bash
# Voir l'état des conteneurs
docker-compose ps

# Voir les logs
docker-compose logs -f

# Redémarrer un service
docker-compose restart eloquence-backend

# Reconstruire et redémarrer
docker-compose up -d --build

# Arrêter tous les services
docker-compose down

# Nettoyer les volumes et images
docker-compose down -v
docker system prune -af
```

### Surveillance

```bash
# Surveiller les logs en temps réel
docker-compose logs -f

# Statistiques des conteneurs
docker stats

# Vérifier la santé des services
curl http://localhost/health
curl http://localhost/api/items
```

## 🐛 Dépannage

### Problèmes courants

#### 1. Les conteneurs ne démarrent pas
```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h
```

#### 2. L'application n'est pas accessible
```bash
# Vérifier que les ports sont ouverts
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Vérifier le firewall
sudo ufw status
```

#### 3. Erreurs SSL
```bash
# Régénérer les certificats
sudo ./nginx/ssl/generate-certs.sh

# Redémarrer nginx
docker-compose restart eloquence-nginx
```

#### 4. Problèmes de permissions
```bash
# Corriger les permissions
sudo chown -R eloquence:eloquence /home/eloquence/app
chmod +x scripts/*.sh
```

### Logs et monitoring

```bash
# Logs de l'application
docker-compose logs eloquence-backend

# Logs de nginx
docker-compose logs eloquence-nginx

# Logs du frontend
docker-compose logs eloquence-frontend
```

## 🔄 Mise à jour

Pour mettre à jour l'application :

1. **Automatique** (recommandé) :
   ```bash
   ./scripts/update.sh
   ```

2. **Manuelle** :
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

## 🔒 Sécurité

### Recommandations pour la production

1. **Certificats SSL** : Utilisez Let's Encrypt ou des certificats valides
2. **Firewall** : Configurez ufw pour restreindre l'accès
3. **Mots de passe** : Utilisez des mots de passe forts pour la base de données
4. **Mise à jour** : Maintenez le système et Docker à jour
5. **Backup** : Configurez des sauvegardes automatiques

### Configuration firewall

```bash
# Configurer ufw
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
```

## 📊 Monitoring

### Health checks

L'application inclut des vérifications de santé :
- Backend : `http://localhost:8000/health`
- Via Nginx : `http://localhost/health`

### Métriques

```bash
# Usage des ressources
docker stats

# Espace disque
df -h

# Processus
top
```

## 🆘 Support

En cas de problème :

1. Consultez les logs : `docker-compose logs`
2. Vérifiez la configuration : `docker-compose config`
3. Redémarrez les services : `./scripts/deploy.sh`
4. Vérifiez l'espace disque et la mémoire

## 📝 Notes importantes

- L'application utilise SQLite en mémoire par défaut (les données sont perdues au redémarrage)
- Les certificats SSL sont auto-signés (navigateur affichera un avertissement)
- Le backend expose une API REST complète
- Le frontend Flutter communique avec l'API via nginx

---

🎉 **Félicitations !** Votre application Eloquence est maintenant déployée et accessible.