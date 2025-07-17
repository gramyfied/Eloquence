@echo off
setlocal

echo #################################################################
echo # Script de telechargement des modeles Vosk pour Eloquence      #
echo #################################################################
echo.
echo Ce script va telecharger les 4 modeles necessaires au service d'analyse vocale.
echo Assurez-vous d'avoir 'curl' et 'unzip' installes et accessibles dans votre PATH.
echo (Git for Windows inclut generalement ces outils).
echo.

REM Creation d'un repertoire pour les telechargements
set "DOWNLOAD_DIR=vosk_models_temp"
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)
cd "%DOWNLOAD_DIR%"

REM URLs des modeles
set "URL_FR_LARGE=https://alphacephei.com/vosk/models/vosk-model-fr-large-0.22.zip"
set "URL_FR_SMALL=https://alphacephei.com/vosk/models/vosk-model-fr-small-0.22.zip"
set "URL_EN_LARGE=https://alphacephei.com/vosk/models/vosk-model-en-large-0.22.zip"
set "URL_SPK=https://alphacephei.com/vosk/models/vosk-model-spk-0.4.zip"

REM Telechargement
echo --- Telechargement du modele fr-large...
curl -k -L -o vosk-model-fr-large-0.22.zip "%URL_FR_LARGE%"
echo --- Telechargement du modele fr-small...
curl -k -L -o vosk-model-fr-small-0.22.zip "%URL_FR_SMALL%"
echo --- Telechargement du modele en-large...
curl -k -L -o vosk-model-en-large-0.22.zip "%URL_EN_LARGE%"
echo --- Telechargement du modele spk...
curl -k -L -o vosk-model-spk-0.4.zip "%URL_SPK%"

echo.
echo --- Telechargement termine. Decompression en cours...
echo.

REM Decompression (utilisation de tar, generalement inclus avec Git for Windows)
tar -xf vosk-model-fr-large-0.22.zip
tar -xf vosk-model-fr-small-0.22.zip
tar -xf vosk-model-en-large-0.22.zip
tar -xf vosk-model-spk-0.4.zip

echo.
echo --- Decompression terminee.
echo.
echo #################################################################
echo # ACTION MANUELLE REQUISE                                       #
echo #################################################################
echo.
echo 1. Executez la commande suivante pour trouver le dossier de votre volume Docker:
echo    docker volume inspect eloquence_vosk-models
echo.
echo 2. Cherchez la ligne "Mountpoint". Ce sera un chemin comme "/var/lib/docker/volumes/eloquence_vosk-models/_data".
echo.
echo 3. Copiez les 4 repertoires de modeles decompressés:
echo    - vosk-model-fr-large-0.22
echo    - vosk-model-fr-small-0.22
echo    - vosk-model-en-large-0.22
echo    - vosk-model-spk-0.4
echo.
echo    qui se trouvent dans le dossier '%DOWNLOAD_DIR%' de ce projet,
echo    vers le dossier "Mountpoint" que vous avez trouve.
echo.
echo 4. Une fois les fichiers copies, redemarrez le service:
echo    docker-compose restart vosk-stt-analysis
echo.

cd ..
endlocal