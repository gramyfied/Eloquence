@echo off
REM Script de démarrage optimisé pour le développement sur Windows

echo 🚀 Démarrage de l'environnement de développement Eloquence
echo ==================================================

REM Vérifier Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installé ou pas dans le PATH
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas démarré ou inaccessible
    echo 💡 Assurez-vous que Docker Desktop est démarré
    pause
    exit /b 1
)

echo ✅ Docker est disponible

REM Vérifier Docker Compose
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose n'est pas disponible
    pause
    exit /b 1
)

echo ✅ Docker Compose est disponible

REM Vérifier si on est dans le bon répertoire
if not exist "docker-compose.dev.yml" (
    echo ❌ Le fichier docker-compose.dev.yml n'existe pas
    echo 💡 Assurez-vous d'être dans le répertoire racine du projet
    pause
    exit /b 1
)

REM Nettoyer si demandé
if "%1"=="--clean" (
    echo ℹ️ Nettoyage des conteneurs existants...
    docker compose -f docker-compose.dev.yml down --volumes --remove-orphans 2>nul
    docker system prune -f --volumes 2>nul
    echo ✅ Nettoyage terminé
)

REM Choisir le mode
set MODE=%1
if "%MODE%"=="" set MODE=dev
if "%MODE%"=="--clean" set MODE=dev

if "%MODE%"=="watch" (
    echo ℹ️ Démarrage en mode Docker Compose Watch ^(synchronisation ultra-rapide^)
    set COMPOSE_FILE=docker-compose.watch.yml
    set COMMAND=docker compose -f docker-compose.watch.yml up --watch
) else (
    echo ℹ️ Démarrage en mode développement standard
    set COMPOSE_FILE=docker-compose.dev.yml
    set COMMAND=docker compose -f docker-compose.dev.yml up --build
)

echo ℹ️ Fichier de configuration: %COMPOSE_FILE%

REM Vérifier que le fichier existe
if not exist "%COMPOSE_FILE%" (
    echo ❌ Le fichier %COMPOSE_FILE% n'existe pas
    pause
    exit /b 1
)

REM Construire les images
echo ℹ️ Construction des images Docker...
docker compose -f %COMPOSE_FILE% build --parallel

REM Afficher les informations
echo.
echo ✅ 🎯 Services qui vont démarrer:
echo    • API Backend ^(port 8000^) - Hot reload activé
echo    • LiveKit Server ^(port 7880^)
echo    • Redis ^(port 6379^)
echo    • Whisper STT ^(port 8001^)
echo    • Azure TTS ^(port 5002^)
echo.
echo ℹ️ 🔥 Hot-reload activé - vos modifications seront appliquées instantanément !
echo.
echo ⚠️ RECOMMANDATION: Pour de meilleures performances, déplacez votre projet dans WSL 2
echo    1. Ouvrez WSL: wsl
echo    2. Copiez le projet: cp -r /mnt/c/Users/User/Desktop/25Eloquence-Finalisation ~/projects/
echo    3. Ouvrez VS Code depuis WSL: code ~/projects/25Eloquence-Finalisation
echo.

REM Démarrer les services
%COMMAND%