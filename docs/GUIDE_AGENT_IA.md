# Guide d'application des corrections avec l'agent IA

Ce document explique comment votre agent IA doit modifier la configuration pour corriger les probl\xC3\xA8mes de connexion \xC3\xA0 LiveKit. Toutes les parties de l'application doivent utiliser le m\xC3\xAAme port **7881** et les identifiants de d\xC3\xA9veloppement `devkey` / `devsecret...`.

## 1. Fichier `livekit.yaml`
- S'assurer que la cl\xC3\xA9 `port` est `7881`.
- Dans la section `keys`, d\xC3\xA9finir :
  ```yaml
  keys:
    devkey: devsecret123456789abcdef0123456789abcdef0123456789abcdef
  ```
- Le `webhook` doit utiliser la m\xC3\xAAme cl\xC3\xA9.

## 2. Fichier `.env` du backend
- Cr\xC3\xA9er un fichier `.env` au m\xC3\xAAme niveau que `eloquence-backend/app.py`.
- Contenu conseill\xC3\xA9 :
  ```env
  PUBLIC_LIVEKIT_URL=ws://10.0.2.2:7881
  LIVEKIT_API_KEY=devkey
  LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef0123456789abcdef
  BACKEND_PORT=5000
  ```
- Le backend charge automatiquement ce fichier gr\xC3\xA2ce \xC3\xA0 `load_dotenv`.

## 3. Fichier `.env` du frontend
- Dans `eloquence_v_2/eloquence_v_2_frontend`, cr\xC3\xA9er un `.env` identique aux variables ci-dessus mais avec la cl\xC3\xA9 `LIVEKIT_WS_URL` :
  ```env
  LIVEKIT_WS_URL=ws://10.0.2.2:7881
  LIVEKIT_API_KEY=devkey
  LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef0123456789abcdef
  ```

## 4. Red\xC3\xA9marrage des services
1. Lancer `start_livekit_server.bat` pour d\xC3\xA9marrer LiveKit avec Docker (port 7881).
2. D\xC3\xA9marrer le backend :
   ```cmd
   python eloquence-backend/app.py
   ```
3. Lancer l'application Flutter depuis `eloquence_v_2/eloquence_v_2_frontend`.

## 5. Validation
- Ex\xC3\xA9cuter `validate_livekit_config.bat` afin de v\xC3\xA9rifier la pr\xC3\xA9sence des fichiers `.env`, la coh\xC3\xA9rence du port 7881 et des cl\xC3\xA9s API.

En suivant ces \xC3\xA9tapes, votre environnement sera synchronis\xC3\xA9 et votre application devrait se connecter correctement \xC3\xA0 LiveKit.
