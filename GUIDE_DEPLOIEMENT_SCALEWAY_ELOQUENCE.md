# 🚀 GUIDE DE DÉPLOIEMENT SCALEWAY ELOQUENCE

## 🎯 OBJECTIF
Déployer automatiquement l'application Eloquence refactorisée sur un serveur Scaleway avec installation complète et configuration optimisée.

## 📋 ARCHITECTURE DÉPLOYÉE

### 🏗️ SERVICES ELOQUENCE
```
Internet → Nginx (SSL) → Eloquence API (8080) → Services IA
                      ↓
                  LiveKit (7880) + Redis (6379)
                      ↓
              Vosk STT (8002) + Mistral IA (8001)
```

### 📦 COMPOSANTS
- **Eloquence API** : API unifiée (port 8080)
- **LiveKit Server** : WebRTC et tokens (port 7880)
- **Vosk STT** : Reconnaissance vocale (port 8002)
- **Mistral IA** : Intelligence artificielle (port 8001)
- **Redis** : Cache et sessions (port 6379)
- **Nginx** : Reverse proxy et SSL (ports 80/443)

## 🚀 DÉPLOIEMENT AUTOMATIQUE

### ÉTAPE 1 : Préparation Serveur Scaleway

#### A. Créer une instance Scaleway
```bash
# Recommandations serveur :
# - Type : DEV1-M ou GP1-S
# - OS : Ubuntu 22.04 LTS
# - RAM : 4GB minimum
# - Stockage : 40GB minimum
# - IP publique : Oui
```

#### B. Configuration DNS
```bash
# Pointer votre domaine vers l'IP du serveur
# Exemple avec Cloudflare/OVH/Gandi :
# A    votre-domaine.com    →    IP_SERVEUR
# A    www.votre-domaine.com →   IP_SERVEUR
```

### ÉTAPE 2 : Déploiement en Une Commande

#### A. Connexion au serveur
```bash
# Se connecter en SSH
ssh root@IP_SERVEUR

# Ou avec une clé
ssh -i votre-cle.pem root@IP_SERVEUR
```

#### B. Téléchargement et exécution
```bash
# Télécharger le script de déploiement
wget -O deploy-eloquence.sh https://raw.githubusercontent.com/gramyfied/Eloquence/main/scripts/deploy-scaleway.sh

# Rendre exécutable
chmod +x deploy-eloquence.sh

# Configurer les variables d'environnement
export DOMAIN="votre-domaine.com"
export EMAIL="votre@email.com"
export MISTRAL_API_KEY="votre_cle_mistral_scaleway"
export SCALEWAY_MISTRAL_URL="https://api.scaleway.ai/votre-projet-id/v1"

# Lancer le déploiement automatique
sudo ./deploy-eloquence.sh
```

### ÉTAPE 3 : Configuration Post-Déploiement

#### A. Vérification des services
```bash
# Vérifier que tous les services sont actifs
docker ps

# Tester l'API
curl https://votre-domaine.com/health

# Voir les logs
eloquence-logs
```

#### B. Configuration des clés API
```bash
# Éditer le fichier de configuration
sudo nano /opt/eloquence/.env

# Configurer vos vraies clés :
# MISTRAL_API_KEY=votre_vraie_cle_mistral
# SCALEWAY_MISTRAL_URL=https://api.scaleway.ai/votre-projet-id/v1

# Redémarrer après modification
eloquence-restart
```

## 🔧 COMMANDES DE GESTION

### 📋 Commandes Principales
```bash
# Démarrer l'application
eloquence-start

# Arrêter l'application
eloquence-stop

# Redémarrer l'application
eloquence-restart

# Voir les logs en temps réel
eloquence-logs

# Voir les logs d'un service spécifique
eloquence-logs eloquence-api

# Mettre à jour l'application
eloquence-update

# Sauvegarder l'application
eloquence-backup
```

### 🔍 Commandes de Diagnostic
```bash
# Vérifier l'état des conteneurs
docker ps

# Vérifier l'utilisation des ressources
docker stats

# Vérifier les logs système
tail -f /var/log/eloquence-monitor.log

# Vérifier la configuration Nginx
sudo nginx -t

# Vérifier les certificats SSL
sudo certbot certificates

# Vérifier le firewall
sudo ufw status
```

## 🛡️ SÉCURITÉ ET MONITORING

### 🔒 Sécurité Automatique
- **Firewall UFW** configuré automatiquement
- **Certificats SSL** Let's Encrypt avec renouvellement auto
- **Headers de sécurité** Nginx (HSTS, CSP, etc.)
- **Fail2ban** protection contre brute force
- **Isolation réseau** Docker avec ports internes

### 📊 Monitoring Automatique
- **Surveillance système** toutes les 5 minutes
- **Alertes automatiques** CPU/RAM/Disque
- **Nettoyage automatique** logs Docker anciens
- **Redémarrage automatique** services en panne
- **Sauvegarde quotidienne** configuration et données

### 📈 Logs et Métriques
```bash
# Logs de monitoring
tail -f /var/log/eloquence-monitor.log

# Logs Nginx
tail -f /var/log/nginx/eloquence_access.log
tail -f /var/log/nginx/eloquence_error.log

# Logs application
eloquence-logs eloquence-api
eloquence-logs vosk-stt
eloquence-logs mistral
```

## 🔧 MAINTENANCE ET MISE À JOUR

### 🔄 Mise à Jour Automatique
```bash
# Mettre à jour vers la dernière version
eloquence-update

# Le script fait automatiquement :
# 1. Récupération du code depuis GitHub
# 2. Arrêt des services
# 3. Reconstruction des images Docker
# 4. Redémarrage des services
# 5. Vérification de santé
```

### 💾 Sauvegarde et Restauration
```bash
# Créer une sauvegarde manuelle
eloquence-backup

# Les sauvegardes sont stockées dans :
# /opt/backups/eloquence/

# Contenu sauvegardé :
# - Configuration (.env, docker-compose)
# - Données Redis
# - Logs importants
```

### 🚨 Résolution de Problèmes

#### Problème : Services ne démarrent pas
```bash
# Vérifier les logs
eloquence-logs

# Vérifier l'espace disque
df -h

# Nettoyer Docker
docker system prune -f

# Redémarrer
eloquence-restart
```

#### Problème : SSL ne fonctionne pas
```bash
# Vérifier les certificats
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew

# Vérifier la configuration Nginx
sudo nginx -t
sudo systemctl reload nginx
```

#### Problème : API non accessible
```bash
# Vérifier le firewall
sudo ufw status

# Vérifier Nginx
sudo systemctl status nginx

# Vérifier les conteneurs
docker ps

# Redémarrer Nginx
sudo systemctl restart nginx
```

## 📊 OPTIMISATIONS PRODUCTION

### ⚡ Performance
```bash
# Optimisations automatiquement appliquées :
# - Configuration Docker optimisée
# - Limites système ajustées
# - Cache Nginx activé
# - Compression Gzip
# - Keep-alive configuré
```

### 🔧 Configuration Avancée
```bash
# Modifier la configuration
sudo nano /opt/eloquence/.env

# Variables importantes :
# LOG_LEVEL=INFO          # DEBUG pour plus de détails
# API_WORKERS=4           # Nombre de workers API
# REDIS_MAX_CONNECTIONS=20 # Connexions Redis max
# NGINX_WORKER_PROCESSES=auto # Workers Nginx
```

### 📈 Scaling
```bash
# Pour augmenter les performances :
# 1. Augmenter la taille du serveur Scaleway
# 2. Modifier API_WORKERS dans .env
# 3. Redémarrer : eloquence-restart

# Pour load balancing :
# 1. Déployer sur plusieurs serveurs
# 2. Utiliser un load balancer Scaleway
# 3. Partager Redis entre instances
```

## 🎯 TESTS DE VALIDATION

### ✅ Tests Automatiques Post-Déploiement
```bash
# Le script teste automatiquement :
# ✅ API principale (port 8080)
# ✅ Vosk STT (port 8002)
# ✅ Mistral IA (port 8001)
# ✅ Redis (port 6379)
# ✅ LiveKit (port 7880)
# ✅ Nginx (ports 80/443)
```

### 🧪 Tests Manuels
```bash
# Test API Health
curl https://votre-domaine.com/health

# Test API Documentation
curl https://votre-domaine.com/api/docs

# Test WebSocket LiveKit
# (nécessite un client WebSocket)

# Test STT
curl -X POST https://votre-domaine.com/api/stt/analyze \
  -H "Content-Type: application/json" \
  -d '{"audio_data": "base64_audio_data"}'

# Test IA Conversation
curl -X POST https://votre-domaine.com/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Bonjour"}'
```

## 📞 SUPPORT ET RESSOURCES

### 🆘 Support Technique
- **Logs détaillés** : `eloquence-logs`
- **Monitoring** : `/var/log/eloquence-monitor.log`
- **Configuration** : `/opt/eloquence/.env`
- **Documentation** : `GUIDE_SECURISATION_MAXIMALE_ELOQUENCE.md`

### 🔗 Liens Utiles
- **Repository GitHub** : https://github.com/gramyfied/Eloquence
- **Documentation Scaleway** : https://www.scaleway.com/en/docs/
- **Support Scaleway** : https://console.scaleway.com/support/
- **Let's Encrypt** : https://letsencrypt.org/

### 📋 Checklist Finale
- [ ] Serveur Scaleway créé et accessible
- [ ] Domaine pointé vers l'IP du serveur
- [ ] Script de déploiement exécuté avec succès
- [ ] Tous les services actifs (docker ps)
- [ ] API accessible via HTTPS
- [ ] Certificats SSL valides
- [ ] Clés API configurées
- [ ] Tests de fonctionnement réussis
- [ ] Monitoring actif
- [ ] Sauvegarde configurée

---

## 🎉 FÉLICITATIONS !

Votre application Eloquence est maintenant déployée en production sur Scaleway !

### 📊 Résumé du déploiement :
- **🌐 URL** : https://votre-domaine.com
- **🔒 Sécurité** : SSL + Firewall + Monitoring
- **⚡ Performance** : Optimisée pour production
- **🛠️ Maintenance** : Scripts automatisés
- **📈 Monitoring** : Surveillance 24/7
- **💾 Sauvegarde** : Automatique quotidienne

**Votre application d'IA vocale est prête à servir vos utilisateurs !** 🎯✨

### 🚀 Prochaines étapes :
1. Tester toutes les fonctionnalités
2. Configurer le monitoring avancé
3. Planifier les mises à jour
4. Optimiser selon l'usage
5. Mettre en place la CI/CD

**Bonne utilisation d'Eloquence en production !** 🎙️🤖
