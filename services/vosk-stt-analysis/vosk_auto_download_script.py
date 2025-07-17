import argparse
import os
import requests
from tqdm import tqdm
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def download_file(url, destination):
    """Télécharge un fichier avec une barre de progression."""
    logging.info(f"Téléchargement de {url} vers {destination}")
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Lève une exception pour les codes d'état HTTP d'erreur

        total_size = int(response.headers.get('content-length', 0))
        block_size = 1024  # 1 Kibibyte
        tqdm_bar = tqdm(total=total_size, unit='iB', unit_scale=True, desc=url.split('/')[-1])

        with open(destination, 'wb') as f:
            for chunk in response.iter_content(chunk_size=block_size):
                if chunk:
                    f.write(chunk)
                    tqdm_bar.update(len(chunk))
        tqdm_bar.close()
        logging.info(f"Téléchargement terminé : {destination}")
        return True
    except requests.exceptions.RequestException as e:
        logging.error(f"Erreur lors du téléchargement de {url}: {e}")
        return False
    except Exception as e:
        logging.error(f"Une erreur inattendue est survenue lors du téléchargement: {e}")
        return False

def get_model_info(environment):
    """Retourne l'URL et le nom du modèle en fonction de l'environnement."""
    models = {
        "production": {
            "name": "vosk-model-fr-0.22",
            "url": "https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip"
        },
        "development": {
            "name": "vosk-model-small-fr-0.22",
            "url": "https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip"
        },
        "multilingual": {
            "name": "vosk-model-en-us-0.22", # Exemple, à adapter si un modèle multilingue spécifique est requis
            "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip"
        }
    }
    return models.get(environment, models["production"]) # Par défaut production

def main():
    parser = argparse.ArgumentParser(description="Télécharge les modèles Vosk.")
    parser.add_argument("--environment", type=str, default="production",
                        help="Environnement (production, development, multilingual)")
    parser.add_argument("--models-dir", type=str, default="/app/models",
                        help="Répertoire de destination des modèles")
    args = parser.parse_args()

    model_info = get_model_info(args.environment)
    model_name = model_info["name"]
    model_url = model_info["url"]
    
    model_zip_path = os.path.join(args.models_dir, f"{model_name}.zip")
    model_extracted_path = os.path.join(args.models_dir, model_name)

    if os.path.exists(model_extracted_path) and os.listdir(model_extracted_path):
        logging.info(f"Modèle {model_name} déjà présent dans {model_extracted_path}. Pas de téléchargement nécessaire.")
        return

    os.makedirs(args.models_dir, exist_ok=True)

    if download_file(model_url, model_zip_path):
        logging.info(f"Décompression de {model_zip_path}...")
        try:
            import zipfile
            with zipfile.ZipFile(model_zip_path, 'r') as zip_ref:
                zip_ref.extractall(args.models_dir)
            logging.info(f"Modèle décompressé avec succès dans {args.models_dir}")
            os.remove(model_zip_path) # Supprimer le fichier zip après décompression
        except zipfile.BadZipFile:
            logging.error(f"Le fichier téléchargé {model_zip_path} n'est pas un fichier zip valide.")
            if os.path.exists(model_zip_path):
                os.remove(model_zip_path)
            exit(1)
        except Exception as e:
            logging.error(f"Erreur lors de la décompression: {e}")
            exit(1)
    else:
        logging.error("Échec du téléchargement du modèle.")
        exit(1)

if __name__ == "__main__":
    main()
