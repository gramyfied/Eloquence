@echo off
cd /d "%~dp0"
echo ======================================================
echo OUTIL DE PREVISUALISATION BLENDER MCP ELOQUENCE
echo ======================================================
echo.

if "%~1"=="" (
    echo Usage: preview.bat "votre prompt ici"
    echo.
    echo Exemples:
    echo   preview.bat "Roulette des virelangues magiques"
    echo   preview.bat "Cube orange qui rebondit 3 fois"
    echo   preview.bat "Logo ELOQUENCE dore qui tourne"
    echo.
    echo Mode interactif:
    echo   preview.bat interactive
    echo.
    pause
    exit /b
)

if "%~1"=="interactive" (
    python preview_simple.py
) else (
    python preview_simple.py "%~1"
)

pause