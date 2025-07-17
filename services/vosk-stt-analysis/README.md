# Service d'analyse STT Vosk

Ce service utilise les modèles de reconnaissance vocale de Vosk pour fonctionner. Pour que le service puisse démarrer correctement, les modèles requis doivent être téléchargés et placés dans le volume Docker `vosk-models`.

## Instructions d'installation des modèles

1.  **Créez le répertoire local pour les modèles :**
    Si ce n'est pas déjà fait, Docker créera un répertoire pour le volume `vosk-models`. Pour trouver son emplacement, vous pouvez exécuter :
    ```bash
    docker volume inspect eloquence_vosk-models
    ```
    Cherchez la valeur de `Mountpoint`. C'est là que vous devrez placer les fichiers de modèle.

2.  **Téléchargez les modèles Vosk requis :**
    Le service est configuré pour utiliser les modèles suivants. Téléchargez-les depuis le [site officiel de Vosk](https://alphacephei.com/vosk/models) :

    *   **Français (Large)**: [vosk-model-fr-large-0.22](https://alphacephei.com/vosk/models/vosk-model-fr-large-0.22.zip)
    *   **Français (Small)**: [vosk-model-fr-small-0.22](https://alphacephei.com/vosk/models/vosk-model-fr-small-0.22.zip)
    *   **Anglais (Large)**: [vosk-model-en-large-0.22](https://alphacephei.com/vosk/models/vosk-model-en-large-0.22.zip)
    *   **Identification du locuteur**: [vosk-model-spk-0.4](https://alphacephei.com/vosk/models/vosk-model-spk-0.4.zip)

3.  **Décompressez et placez les modèles :**
    Pour chaque fichier `.zip` téléchargé, décompressez-le. Vous obtiendrez un répertoire (par exemple, `vosk-model-fr-large-0.22`).

    Copiez chacun de ces répertoires dans le `Mountpoint` du volume `vosk-models` que vous avez identifié à l'étape 1. La structure finale devrait ressembler à ceci :

    ```
    /path/to/docker/volumes/eloquence_vosk-models/_data/
    ├── vosk-model-en-large-0.22/
    │   ├── ... (fichiers du modèle)
    ├── vosk-model-fr-large-0.22/
    │   ├── ... (fichiers du modèle)
    ├── vosk-model-fr-small-0.22/
    │   ├── ... (fichiers du modèle)
    └── vosk-model-spk-0.4/
        └── ... (fichiers du modèle)
    ```

4.  **Redémarrez le service :**
    Une fois les modèles en place, redémarrez uniquement le service `vosk-stt-analysis` pour qu'il les charge :
    ```bash
    docker-compose restart vosk-stt-analysis
    ```

    Vous pouvez ensuite vérifier les logs pour vous assurer que les modèles sont chargés sans erreur :
    ```bash
    docker-compose logs vosk-stt-analysis