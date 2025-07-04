@echo off
echo.
echo ========================================
echo CORRECTION COMPLETE DU PIPELINE AUDIO
echo ========================================
echo.

echo [1/6] Redemarrage du backend avec la correction...
docker-compose restart api-backend

echo.
echo [2/6] Attente du redemarrage backend (10 secondes)...
timeout /t 10

echo.
echo [3/6] Arret de l'agent actuel...
docker-compose stop eloquence-agent-v1

echo.
echo [4/6] Copie du fichier force_audio...
docker cp services/api-backend/services/real_time_voice_agent_force_audio.py 25eloquence-finalisation-eloquence-agent-v1-1:/app/services/real_time_voice_agent_corrected.py

echo.
echo [5/6] Redemarrage de l'agent...
docker-compose start eloquence-agent-v1

echo.
echo [6/6] Attente du demarrage complet (15 secondes)...
timeout /t 15

echo.
echo ========================================
echo CORRECTIONS APPLIQUEES !
echo ========================================
echo.
echo VERIFICATIONS :
echo.
echo 1. Backend corrige pour chercher eloquence-agent-v1
echo 2. Agent avec audio force deploye
echo.
echo ACTIONS A FAIRE :
echo.
echo 1. Sur votre telephone Android :
echo    - Parametres > Applications > Eloquence
echo    - Verifier que MICROPHONE est AUTORISE
echo    - FERMER COMPLETEMENT l'app Flutter
echo    - Relancer l'application
echo.
echo 2. Surveillez les logs :
echo    docker-compose logs -f api-backend eloquence-agent-v1
echo.
echo Messages a chercher :
echo - "Agent started successfully" (backend connecte)
echo - "AUDIO FORCE:" (traitement force)
echo - "WHISPER FORCE:" (transcriptions)
echo.
pause
