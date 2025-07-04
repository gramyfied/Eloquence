@echo off
echo ========================================
echo   Test Rapide Connectivité Mobile
echo ========================================
echo.

REM Obtenir l'IP locale
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4" ^| findstr /V "169.254"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :found
    )
)

:found
echo 📱 IP de cette machine: %LOCAL_IP%
echo.

echo 🔍 Test des services sur %LOCAL_IP%:
echo.

REM Test LiveKit
echo Testing LiveKit (%LOCAL_IP%:7880)...
curl -s -o nul -w "Status: %%{http_code}\n" http://%LOCAL_IP%:7880 2>nul || echo FAILED

REM Test Whisper STT
echo Testing Whisper STT (%LOCAL_IP%:8001)...
curl -s -o nul -w "Status: %%{http_code}\n" http://%LOCAL_IP%:8001 2>nul || echo FAILED

REM Test Azure TTS
echo Testing Azure TTS (%LOCAL_IP%:5002)...
curl -s -o nul -w "Status: %%{http_code}\n" http://%LOCAL_IP%:5002 2>nul || echo FAILED

echo.
echo ========================================
echo.
echo 📋 Configuration à utiliser dans Flutter:
echo.
echo   LiveKit URL: ws://%LOCAL_IP%:7880
echo   Whisper URL: http://%LOCAL_IP%:8001
echo   Azure TTS URL: http://%LOCAL_IP%:5002
echo.
echo ========================================
echo.

REM Créer un fichier de config rapide
echo // Configuration Mobile > mobile_config.txt
echo const String SERVER_IP = "%LOCAL_IP%"; >> mobile_config.txt
echo const String LIVEKIT_URL = "ws://%LOCAL_IP%:7880"; >> mobile_config.txt
echo const String WHISPER_URL = "http://%LOCAL_IP%:8001"; >> mobile_config.txt
echo const String AZURE_TTS_URL = "http://%LOCAL_IP%:5002"; >> mobile_config.txt

echo 📝 Configuration sauvegardée dans: mobile_config.txt
echo.

pause