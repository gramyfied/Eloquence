# Eloquence - Application de Coaching Vocal

Application de coaching vocal avec IA conversationnelle utilisant LiveKit, Whisper, Piper et Mistral.

## Prérequis

- Git
- Docker et Docker Compose

## ⚙️ Installation et Configuration

1.  **Cloner le projet :**
    Ce projet utilise des sous-modules Git (pour le frontend Flutter). Pour cloner le projet principal et initialiser les sous-modules, utilisez :
    ```bash
    git clone --recurse-submodules https://github.com/gramyfied/25Eloquence-Finalisation.git
    cd 25Eloquence-Finalisation
    ```
    Si vous avez déjà cloné le projet sans l'option `--recurse-submodules`, naviguez dans le dossier du projet et exécutez :
    ```bash
    git submodule update --init --recursive
    ```

2.  **Configuration de l'environnement :**
    Le projet nécessite des variables d'environnement pour fonctionner (clés API, URLs, etc.).
    -   **Fichier `.env` principal :** Un fichier `.env` est requis à la racine du projet. Il est utilisé par `docker-compose.yml` pour configurer les services. Assurez-vous qu'il est présent et correctement configuré. Si vous n'en avez pas, vous devrez le créer en vous basant sur les besoins des services (par exemple, les clés API LiveKit `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` sont souvent définies ici).
    -   **Fichiers `.env` des services :** Certains services (comme `services/api-backend/` ou `services/livekit-agent/`) peuvent également nécessiter leurs propres fichiers `.env` ou lire des variables de l'environnement Docker. Vérifiez les `Dockerfile` ou les scripts de démarrage de chaque service pour les variables requises. Si des fichiers `.env.example` sont fournis dans les dossiers des services, copiez-les en `.env` et remplissez les valeurs.

## 🚀 Démarrage Rapide

Après avoir cloné le projet et configuré l'environnement comme décrit ci-dessus :

1.  **(Optionnel) Script de configuration initiale :**
    Si le script `scripts/setup.sh` est pertinent pour votre environnement, exécutez-le :
    ```bash
    ./scripts/setup.sh
    ```
    *Note : Vérifiez le contenu de `scripts/setup.sh` et adaptez-le à votre système si nécessaire.*

2.  **Démarrage des services Docker :**
    Pour construire les images Docker (si elles n'ont pas encore été construites) et démarrer tous les services en arrière-plan :
    ```bash
    docker-compose up -d --build
    ```
    Pour visualiser les logs de tous les services :
    ```bash
    docker-compose logs -f
    ```
    Pour visualiser les logs d'un service spécifique (par exemple, `eloquence-agent`) :
    ```bash
    docker-compose logs -f eloquence-agent
    ```
    Pour arrêter tous les services :
    ```bash
    docker-compose down
    ```

## 📚 Documentation

Voir le dossier [docs/](docs/) pour la documentation complète :
- [Architecture](docs/ARCHITECTURE.md)
- [Déploiement](docs/DEPLOYMENT.md)
- [Maintenance](docs/MAINTENANCE.md)

## 🧪 Tests

```bash
# Tests complets
./scripts/test.sh

# Tests spécifiques
cd tests/integration && python test_final_validation.py