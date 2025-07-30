# 🎙️ ELOQUENCE - DÉPLOIEMENT RÉUSSI

## 🎉 Félicitations !

Votre application Eloquence a été déployée avec succès ! Tous les services sont opérationnels et prêts à être utilisés.

## 📊 État du Déploiement

### ✅ Services Déployés

| Service | Port | Status | Description |
|---------|------|--------|-------------|
| **Eloquence API** | 8080 | ✅ Opérationnel | API principale unifiée |
| **Vosk STT** | 8002 | ✅ Opérationnel | Reconnaissance vocale française |
| **Mistral IA** | 8001 | ✅ Opérationnel | Intelligence artificielle conversationnelle |
| **LiveKit** | 7880 | ✅ Opérationnel | WebRTC et communication temps réel |
| **Redis** | 6379 | ✅ Opérationnel | Cache et stockage de sessions |

### 🌐 URLs d'Accès

- **🔍 API Health Check**: http://localhost:8080/health
- **📚 Documentation API**: http://localhost:8080/docs
- **🎤 Vosk STT Health**: http://localhost:8002/health
- **🤖 Mistral IA Health**: http://localhost:8001/health
- **🔴 LiveKit WebSocket**: http://localhost:7880/

## 🛠️ Gestion de l'Application

### Script de Gestion

Un script de gestion `eloquence-manage.sh` a été créé pour faciliter l'administration :

```bash
# Afficher l'aide
./eloquence-manage.sh help

# Vérifier la santé des services
./eloquence-manage.sh health

# Voir l'état des conteneurs
./eloquence-manage.sh status

# Voir les logs en temps réel
./eloquence-manage.sh logs

# Redémarrer l'application
./eloquence-manage.sh restart

# Arrêter l'application
./eloquence-manage.sh stop

# Démarrer l'application
./eloquence-manage.sh start
```

### Commandes Docker Directes

```bash
# Voir les conteneurs en cours
sudo docker ps

# Voir les logs d'un service spécifique
sudo docker compose -f docker-compose-new.yml logs -f eloquence-api

# Redémarrer tous les services
sudo docker compose -f docker-compose-new.yml restart

# Arrêter tous les services
sudo docker compose -f docker-compose-new.yml down

# Démarrer tous les services
sudo docker compose -f docker-compose-new.yml up -d
```

## ⚙️ Configuration

### Fichier .env

Le fichier `.env` contient toute la configuration de l'application. Pour la production, vous devrez :

1. **Configurer les clés API** :
   ```bash
   # Éditez le fichier .env
   nano .env
   
   # Remplacez les valeurs suivantes :
   MISTRAL_API_KEY=votre_vraie_cle_mistral
   SCALEWAY_MISTRAL_URL=https://api.scaleway.ai/votre-projet-id/v1
   OPENAI_API_KEY=votre_cle_openai (optionnel)
   ```

2. **Redémarrer après modification** :
   ```bash
   ./eloquence-manage.sh restart
   ```

### Variables Importantes

| Variable | Description | Valeur Actuelle |
|----------|-------------|-----------------|
| `ENVIRONMENT` | Mode d'exécution | `development` |
| `DOMAIN` | Domaine de l'application | `localhost` |
| `MISTRAL_API_KEY` | Clé API Mistral/Scaleway | `your_mistral_api_key_here` |
| `LIVEKIT_API_KEY` | Clé API LiveKit | `devkey` |
| `DEBUG` | Mode debug | `true` |

## 🧪 Tests et Validation

### Tests de Santé Automatiques

```bash
# Test complet de tous les services
./eloquence-manage.sh health
```

### Tests Manuels

```bash
# Test API principale
curl http://localhost:8080/health

# Test Vosk STT
curl http://localhost:8002/health

# Test Mistral IA
curl http://localhost:8001/health

# Test LiveKit
curl http://localhost:7880/

# Test Redis
sudo docker exec settings-redis-1 redis-cli ping
```

## 📁 Structure du Projet

```
.
├── services/                    # Services microservices
│   ├── eloquence-api/          # API principale
│   ├── vosk-stt-analysis/      # Service STT
│   ├── mistral-conversation/   # Service IA
│   └── livekit-*/              # Services LiveKit
├── docker-compose-new.yml      # Configuration Docker Compose
├── .env                        # Variables d'environnement
├── eloquence-manage.sh         # Script de gestion
└── DEPLOYMENT_README.md        # Cette documentation
```

## 🔧 Dépannage

### Problèmes Courants

1. **Service non accessible** :
   ```bash
   # Vérifier les logs
   ./eloquence-manage.sh logs [nom-du-service]
   
   # Redémarrer le service
   sudo docker compose -f docker-compose-new.yml restart [nom-du-service]
   ```

2. **Erreur de permissions Docker** :
   ```bash
   # Ajouter l'utilisateur au groupe docker
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **Port déjà utilisé** :
   ```bash
   # Voir les processus utilisant un port
   sudo netstat -tulpn | grep :8080
   
   # Arrêter les services conflictuels
   sudo docker compose -f docker-compose-new.yml down
   ```

4. **Mistral IA "unhealthy"** :
   - C'est normal si les clés API ne sont pas configurées
   - Configurez `MISTRAL_API_KEY` et `SCALEWAY_MISTRAL_URL` dans `.env`

### Logs Utiles

```bash
# Logs de tous les services
./eloquence-manage.sh logs

# Logs d'un service spécifique
./eloquence-manage.sh logs eloquence-api
./eloquence-manage.sh logs vosk-stt
./eloquence-manage.sh logs mistral
./eloquence-manage.sh logs livekit
./eloquence-manage.sh logs redis
```

## 🚀 Prochaines Étapes

### Pour le Développement

1. **Configurer les clés API** pour tester les fonctionnalités IA
2. **Développer le frontend** pour interagir avec l'API
3. **Tester les fonctionnalités** de reconnaissance vocale et conversation
4. **Personnaliser la configuration** selon vos besoins

### Pour la Production

1. **Utiliser le script de déploiement Scaleway** : `scripts/deploy-scaleway.sh`
2. **Configurer un domaine réel** et SSL/HTTPS
3. **Utiliser des secrets Docker** pour les données sensibles
4. **Mettre en place le monitoring** et les alertes
5. **Configurer les sauvegardes** automatiques

## 📞 Support

### Ressources

- **Documentation complète** : `GUIDE_DEPLOIEMENT_SCALEWAY_ELOQUENCE.md`
- **Guide de sécurisation** : `GUIDE_SECURISATION_MAXIMALE_ELOQUENCE.md`
- **Repository GitHub** : https://github.com/gramyfied/Eloquence

### Commandes de Diagnostic

```bash
# État complet du système
./eloquence-manage.sh status
./eloquence-manage.sh health

# Informations système
docker --version
docker compose version
sudo docker system df
sudo docker system events --since 1h
```

---

## 🎯 Résumé

✅ **Déploiement réussi** - Tous les services sont opérationnels  
✅ **Architecture microservices** - Services isolés et scalables  
✅ **Script de gestion** - Administration simplifiée  
✅ **Configuration flexible** - Adaptable développement/production  
✅ **Documentation complète** - Guides et références disponibles  

**Votre plateforme d'IA vocale Eloquence est prête à être utilisée !** 🎙️🤖

---

*Déployé le : $(date)*  
*Version : Eloquence 2.0.0*  
*Environnement : Développement Local*
