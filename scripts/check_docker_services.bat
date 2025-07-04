@echo off
echo ========================================
echo    VERIFICATION SERVICES DOCKER
echo ========================================

echo.
echo [1] Verification Docker Desktop...
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Docker n'est pas installe ou n'est pas dans le PATH
    echo.
    echo Veuillez installer Docker Desktop depuis : https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [OK] Docker est installe

echo.
echo [2] Verification Docker en cours d'execution...
docker ps >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Docker n'est pas en cours d'execution
    echo.
    echo Veuillez demarrer Docker Desktop
    pause
    exit /b 1
)
echo [OK] Docker est en cours d'execution

echo.
echo [3] Verification des services Eloquence...
echo.

echo Verification Whisper STT...
docker ps --filter "name=whisper-stt" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr /C:"whisper-stt"
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Service whisper-stt non trouve
) else (
    echo [OK] Service whisper-stt detecte
)

echo.
echo Verification Azure TTS...
docker ps --filter "name=azure-tts" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr /C:"azure-tts"
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Service azure-tts non trouve
) else (
    echo [OK] Service azure-tts detecte
)

echo.
echo Verification LiveKit...
docker ps --filter "name=livekit" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr /C:"livekit"
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Service livekit non trouve
) else (
    echo [OK] Service livekit detecte
)

echo.
echo [4] Test des ports locaux...
echo.

echo Test Whisper STT sur localhost:8001...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:8001/health 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Whisper STT accessible sur localhost:8001
) else (
    echo [WARNING] Whisper STT non accessible sur localhost:8001
)

echo.
echo Test Azure TTS sur localhost:5002...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:5002/health 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Azure TTS accessible sur localhost:5002
) else (
    echo [WARNING] Azure TTS non accessible sur localhost:5002
)

echo.
echo ========================================
echo    RECOMMANDATIONS
echo ========================================
echo.

docker ps >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    docker ps --filter "name=whisper-stt" --format "{{.Names}}" | findstr /C:"whisper-stt" >nul
    if %ERRORLEVEL% NEQ 0 (
        echo 1. Demarrer les services Docker :
        echo    docker-compose up -d
        echo.
    )
)

echo 2. Pour le diagnostic local, utilisez les URLs localhost :
echo    - WHISPER_STT_URL=http://localhost:8001
echo    - AZURE_TTS_URL=http://localhost:5002
echo.
echo 3. Pour utiliser l'agent corrige dans Docker :
echo    docker-compose build eloquence-agent-v1
echo    docker-compose up -d eloquence-agent-v1
echo.

pause
