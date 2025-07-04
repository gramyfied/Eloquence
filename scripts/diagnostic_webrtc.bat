@echo off
echo ========================================
echo DIAGNOSTIC WEBRTC LIVEKIT - %date% %time%
echo ========================================

echo.
echo [1/6] VERIFICATION SERVICES DOCKER
echo ==================================
docker-compose ps

echo.
echo [2/6] LOGS LIVEKIT (DERNIERES 50 LIGNES)
echo ========================================
docker-compose logs --tail=50 livekit

echo.
echo [3/6] TEST CONNECTIVITE RESEAU DOCKER
echo ====================================
echo Test resolution DNS livekit depuis api-backend:
docker-compose exec api-backend nslookup livekit
if %errorlevel% neq 0 echo ❌ Echec resolution DNS

echo.
echo Test connectivite TCP port 7880:
docker-compose exec api-backend nc -zv livekit 7880
if %errorlevel% neq 0 echo ❌ Echec connexion TCP 7880

echo.
echo Test connectivite TCP port 7881 (RTC):
docker-compose exec api-backend nc -zv livekit 7881
if %errorlevel% neq 0 echo ❌ Echec connexion TCP 7881

echo.
echo [4/6] VERIFICATION PORTS UDP WEBRTC
echo ==================================
echo Verification exposition ports UDP 50000-50019:
for /f "tokens=*" %%i in ('docker-compose ps -q livekit') do docker port %%i | findstr udp
if %errorlevel% neq 0 echo ❌ Aucun port UDP expose

echo.
echo [5/6] TEST DEMARRAGE AGENT AVEC DIAGNOSTIC
echo =========================================
echo Demarrage de l'agent avec logs de diagnostic...
docker-compose up -d eloquence-agent
timeout /t 5 /nobreak >nul
echo Logs de l'agent (diagnostic reseau):
docker-compose logs --tail=30 eloquence-agent

echo.
echo [6/6] RESUME DIAGNOSTIC
echo ====================
echo ✅ Services actifs:
docker-compose ps --filter "status=running"

echo.
echo ❌ Services en erreur:
docker-compose ps --filter "status=exited"

echo.
echo 🔍 Recommandations basees sur le diagnostic:
echo 1. Verifier la configuration WebRTC dans livekit.yaml
echo 2. Tester la connectivite UDP entre conteneurs
echo 3. Examiner les logs LiveKit pour erreurs ICE/WebRTC
echo 4. Valider la configuration reseau Docker

echo.
echo ========================================
echo DIAGNOSTIC TERMINE - %date% %time%
echo ========================================
pause