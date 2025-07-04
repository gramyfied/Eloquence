import os
import subprocess
import logging
from faster_whisper import WhisperModel
from huggingface_hub import snapshot_download
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration Whisper
MODEL_SIZE = os.getenv('WHISPER_MODEL_SIZE', 'medium') # Changed from 'base' to 'medium' for consistency with previous attempts
DEVICE = os.getenv('WHISPER_DEVICE', 'cpu')
COMPUTE_TYPE = os.getenv('WHISPER_COMPUTE_TYPE', 'int8')

# Définir le chemin où les modèles seront stockés
MODELS_DIR = os.path.join(os.path.expanduser("~"), ".cache", "faster_whisper")

def check_and_download_whisper_model():
    model_path = os.path.join(MODELS_DIR, MODEL_SIZE)

    if not os.path.exists(model_path):
        logger.info(f"Modèle Whisper '{MODEL_SIZE}' non trouvé localement. Démarrage du téléchargement...")
        try:
            # Utiliser huggingface_hub.snapshot_download pour télécharger le modèle
            # en spécifiant local_dir pour le mettre dans le dossier attendu par faster-whisper
            download_dir = snapshot_download(
                repo_id=f"Systran/faster-whisper-{MODEL_SIZE}",
                allow_patterns=["*"],
                local_dir=model_path,
                local_dir_use_symlinks=False,
            )
            logger.info(f"Modèle Whisper '{MODEL_SIZE}' téléchargé avec succès vers: {download_dir}")
        except Exception as e:
            logger.error(f"Erreur lors du téléchargement du modèle Whisper '{MODEL_SIZE}': {e}")
            logger.info("Réessayez dans 5 secondes...")
            time.sleep(5)
            # Re-tentative simple
            download_dir = snapshot_download(
                repo_id=f"Systran/faster-whisper-{MODEL_SIZE}",
                allow_patterns=["*"],
                local_dir=model_path,
                local_dir_use_symlinks=False,
            )
            logger.info(f"Modèle Whisper '{MODEL_SIZE}' téléchargé avec succès vers: {download_dir} après re-tentative.")
    else:
        logger.info(f"Modèle Whisper '{MODEL_SIZE}' déjà présent localement: {model_path}")

if __name__ == "__main__":
    check_and_download_whisper_model()
    logger.info("Démarrage du service ASR Whisper...")
    # Lancer le service ASR Whisper après le téléchargement
    subprocess.run(["python", "whisper_asr_service.py"])