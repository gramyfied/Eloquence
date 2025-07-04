# Rapport d'Analyse et Correction de l'API LiveKit

## 1. Diagnostic de l'Échec d'Authentification

L'erreur `{"code":"unauthenticated","msg":"permissions denied"}` indique que le token JWT, bien que probablement signé correctement, ne contient pas les permissions (claims) nécessaires pour exécuter des actions administratives sur l'API REST de LiveKit.

L'analyse a révélé que le payload du JWT initial contenait `{"livekit": {"roomList": True}}`. Cette structure de permission est typiquement utilisée pour les **clients** se connectant à une salle, et non pour les **opérations d'administration** du serveur.

## 2. Correction Appliquée au JWT

Pour résoudre ce problème, le script `services/api-backend/generate_jwt.py` a été modifié pour inclure des permissions d'administration. Le nouveau payload est :

```python
payload = {
    "exp": int(time.time()) + 60 * 60,
    "iss": api_key,
    "name": "api-backend",
    "video": {
        "roomAdmin": True,
    },
}
```

- **`"video": {"roomAdmin": True}`** : C'est la modification clé. Ce claim accorde des privilèges d'administration sur les salles, ce qui est nécessaire pour des opérations comme `roomList`.
- **`"name": "api-backend"`** : Ajout d'un identifiant pour savoir quelle partie du système a généré le token.

## 3. Commande `curl` Corrigée

Pour interroger l'API REST, il est également crucial de spécifier le bon `Content-Type`. Voici la commande `curl` complète et corrigée à utiliser :

```bash
# 1. Générez le nouveau token avec les permissions admin
TOKEN=$(python3 services/api-backend/generate_jwt.py)

# 2. Exécutez la requête curl avec le bon Content-Type
curl -X POST "http://localhost:7880/twirp/livekit.RoomService/ListRooms" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{}'
```

**Points importants :**
- **`-X POST`** : La méthode pour l'API Twirp est POST.
- **`-H "Content-Type: application/json"`** : Ce header est souvent obligatoire pour que le serveur interprète correctement la requête.
- **`-d '{}'`** : Un corps de requête JSON vide est nécessaire pour la requête POST.

## 4. Prochaines Étapes

Avec ces corrections, la requête à l'API LiveKit devrait maintenant réussir. Veuillez exécuter la commande `curl` ci-dessus pour confirmer.
