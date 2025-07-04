@echo off
echo ========================================
echo Fix LiveKit Agent Startup
echo ========================================
echo.

REM Arrêter tous les services
echo [1/6] Arrêt des services...
docker-compose down
timeout /t 2 >nul

REM Nettoyer les volumes si nécessaire
echo.
echo [2/6] Nettoyage des volumes (optionnel)...
REM docker volume prune -f

REM Démarrer les services de base
echo.
echo [3/6] Démarrage des services de base...
docker-compose up -d redis livekit whisper-stt azure-tts api-backend

REM Attendre que les services soient prêts
echo.
echo [4/6] Attente que les services soient prêts...
timeout /t 10 >nul

REM Vérifier l'état des services
echo.
echo [5/6] Vérification de l'état des services...
docker-compose ps

REM Démarrer l'agent avec le profile
echo.
echo [6/6] Démarrage de l'agent LiveKit...
docker-compose --profile agent-v1 up -d eloquence-agent-v1

REM Attendre un peu
timeout /t 5 >nul

REM Afficher les logs de l'agent
echo.
echo ========================================
echo Logs de l'agent (Ctrl+C pour arrêter):
echo ========================================
docker-compose logs -f eloquence-agent-v1

pause