# 🚀 Guide de Démarrage Rapide - Backend Eloquence

## Problème Identifié

D'après vos tests de connectivité, le **backend principal sur le port 8000 n'est pas accessible**. 

**Cause**: Le service `backend-api` n'était pas configuré dans le `docker-compose.yml`.

**Solution**: J'ai ajouté la configuration manquante et créé des scripts pour faciliter le démarrage.

## ✅ Solution Immédiate

### 1. Sur votre serveur distant (51.159.110.4)

```bash
# Aller dans le répertoire du projet
cd /path/to/your/eloquence/project

# Démarrer le backend avec le script automatique
./start_backend.sh
```

### 2. Alternative manuelle

```bash
# Si le script ne fonctionne pas, utilisez cette commande
docker-compose up -d --build backend-api redis

# Vérifier que les services sont démarrés
docker-compose ps

# Tester la connectivité
curl http://localhost:8000/health
```

## 🔍 Vérification

Après le démarrage, testez depuis votre machine locale :

```bash
# Test de base
curl http://51.159.110.4:8000/health

# Test de l'API
curl http://51.159.110.4:8000/api/items

# Test avec votre script de connectivité
dart run test_server_connectivity.dart
```

## 📊 Résultats Attendus

Après le démarrage correct, vous devriez voir :

```
✅ Test API Base (http://51.159.110.4:8000)...
   ✅ Port 8000 accessible
   ✅ HTTP Status: 200
   📋 Server: uvicorn
   📄 Response: {"status":"healthy","service":"backend-api"}
```

## 🛠️ Dépannage

### Si le script ne fonctionne pas :

1. **Vérifiez Docker** :
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Vérifiez les permissions** :
   ```bash
   chmod +x start_backend.sh
   ```

3. **Démarrage manuel** :
   ```bash
   cd backend
   pip install -r requirements.txt
   python main.py
   ```

### Si le port est bloqué :

```bash
# Ouvrir le port 8000
sudo ufw allow 8000

# Vérifier les ports ouverts
sudo netstat -tlnp | grep :8000
```

## 📱 Test avec votre Frontend

Une fois le backend démarré :

1. Lancez votre application Flutter
2. L'indicateur de connexion devrait passer au vert
3. Vous devriez voir : "Connecté au serveur distant (http://51.159.110.4:8000)"

## 🔄 Commandes Utiles

```bash
# Voir les logs du backend
docker-compose logs -f backend-api

# Redémarrer le backend
docker-compose restart backend-api

# Arrêter tous les services
docker-compose down

# Reconstruire et redémarrer
docker-compose up -d --build backend-api redis
```

## 📞 Support

Si vous rencontrez encore des problèmes :

1. Vérifiez que vous êtes dans le bon répertoire
2. Assurez-vous que Docker est installé et fonctionne
3. Vérifiez que le port 8000 n'est pas utilisé par un autre service
4. Consultez les logs avec `docker-compose logs backend-api`

---

**Note**: Une fois le backend démarré, votre frontend Flutter se connectera automatiquement au serveur distant !
