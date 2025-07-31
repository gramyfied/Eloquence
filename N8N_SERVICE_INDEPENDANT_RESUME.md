# 🎯 N8N - Service Indépendant Configuré

## ✅ Installation Complète

N8N a été installé et configuré comme **service indépendant** sur votre serveur Scaleway, totalement séparé de votre application Eloquence.

## 🌐 Accès N8N

### Interface Web
- **URL** : `http://dashboard-n8n.eu`
- **Utilisateur** : `admin`
- **Mot de passe** : `n8n_dashboard_secure_2025_admin`
- **Status** : ✅ Opérationnel

### Localisation
- **Répertoire** : `/opt/n8n/`
- **Configuration** : `/opt/n8n/.env`
- **Scripts de gestion** : `/opt/n8n/scripts/n8n-manager.sh`

## 🔧 Gestion du Service

### Commandes Principales
```bash
# Démarrer N8N
cd /opt/n8n && ./scripts/n8n-manager.sh start

# Arrêter N8N
cd /opt/n8n && ./scripts/n8n-manager.sh stop

# Redémarrer N8N
cd /opt/n8n && ./scripts/n8n-manager.sh restart

# Voir les logs
cd /opt/n8n && ./scripts/n8n-manager.sh logs

# Status des services
cd /opt/n8n && ./scripts/n8n-manager.sh status
```

## 📊 Services Inclus

1. **N8N Core** - Automation platform
2. **PostgreSQL** - Base de données
3. **Redis** - Cache et sessions
4. **Nginx** - Reverse proxy
5. **Prometheus** - Monitoring
6. **Grafana** - Dashboards (port 3000)

## 🔗 Utilisation

### Webhooks
- **URL** : `http://dashboard-n8n.eu/webhook/{webhook-id}`
- **Méthode** : POST
- **Authentification** : Aucune

### API REST
- **URL** : `http://dashboard-n8n.eu/api/v1/`
- **Clé API** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ODExODNlYS0zNTUyLTRmMmUtYmMxZC1iNDQwOWY2ZTlhZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQ5MzI2OTEyfQ.HlWG7QVUB45fkrDFkgbOlqA6UNy0Kwhk4Gh1PoAHBBo`

## 🚀 Prêt à Utiliser

N8N est maintenant **complètement indépendant** et prêt pour :
- ✅ Créer des workflows d'automatisation
- ✅ Intégrer avec des APIs externes
- ✅ Traiter des webhooks
- ✅ Automatiser des tâches
- ✅ Connecter différents services

## 📝 Notes Importantes

- **Indépendant** : N8N fonctionne séparément de votre app Eloquence
- **Persistant** : Les données sont sauvegardées en base PostgreSQL
- **Sécurisé** : Authentification configurée
- **Monitoré** : Prometheus + Grafana inclus
- **Scalable** : Configuration optimisée pour Scaleway

Votre service N8N est opérationnel et prêt à être utilisé ! 🎉
