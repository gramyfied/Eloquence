@echo off
echo ==========================================
echo   ELOQUENCE - Redemarrage Unifie
echo ==========================================
echo.

echo [1/4] Arret des services existants...
docker-compose -f docker-compose-unified.yml down

echo.
echo [2/4] Nettoyage des conteneurs orphelins...
docker container prune -f

echo.
echo [3/4] Reconstruction de livekit-agent...
docker-compose -f docker-compose-unified.yml build livekit-agent

echo.
echo [4/4] Demarrage des services...
docker-compose -f docker-compose-unified.yml up -d

echo.
echo Attente de stabilisation (30s)...
timeout /t 30 /nobreak > nul

echo.
echo Etat des services:
docker-compose -f docker-compose-unified.yml ps

echo.
echo ==========================================
echo   Redemarrage termine!
echo ==========================================
echo.
echo Pour voir les logs:
echo docker-compose -f docker-compose-unified.yml logs -f livekit-agent
echo.
pause