@echo off
echo ========================================
echo TEST DE MIGRATION LIVEKIT V1.X
echo ========================================
echo.

REM Étape 1 : Arrêter les services existants
echo [1/6] Arret des services existants...
docker-compose down
timeout /t 3 >nul

REM Étape 2 : Construire la nouvelle image agent v1
echo [2/6] Construction de l'image agent v1.x...
docker-compose -f docker-compose.v1.yml build eloquence-agent-v1
if %errorlevel% neq 0 (
    echo ERREUR: Echec de la construction de l'image!
    exit /b 1
)

REM Étape 3 : Démarrer les services de base
echo [3/6] Demarrage des services de base...
docker-compose -f docker-compose.v1.yml up -d redis livekit whisper-stt piper-tts
timeout /t 10 >nul

REM Étape 4 : Vérifier l'état des services
echo [4/6] Verification de l'etat des services...
docker-compose -f docker-compose.v1.yml ps
echo.

REM Étape 5 : Tester l'agent v1
echo [5/6] Test de l'agent v1.x...
echo.
echo Demarrage de l'agent avec le profil agent-v1...
docker-compose -f docker-compose.v1.yml --profile agent-v1 up -d eloquence-agent-v1

REM Attendre le démarrage
timeout /t 5 >nul

REM Vérifier les logs
echo.
echo === LOGS DE L'AGENT V1 ===
docker-compose -f docker-compose.v1.yml logs --tail=50 eloquence-agent-v1

REM Étape 6 : Vérifier les versions
echo.
echo [6/6] Verification des versions installees...
docker-compose -f docker-compose.v1.yml exec eloquence-agent-v1 pip list | findstr livekit

echo.
echo ========================================
echo TEST TERMINE
echo ========================================
echo.
echo Pour voir les logs en temps reel:
echo docker-compose -f docker-compose.v1.yml logs -f eloquence-agent-v1
echo.
echo Pour arreter les services:
echo docker-compose -f docker-compose.v1.yml down
echo.
pause