@echo off
cd /d "%~dp0"
echo ================================================================
echo PREVISUALISATION VISUELLE BLENDER MCP ELOQUENCE
echo ================================================================
echo 🎨 Generation d'images et ouverture dans le navigateur
echo.

if "%~1"=="" (
    echo Usage: preview_visual.bat "votre prompt ici"
    echo.
    echo Exemples:
    echo   preview_visual.bat "Roulette des virelangues magiques"
    echo   preview_visual.bat "Cube orange qui rebondit 3 fois"
    echo   preview_visual.bat "Logo ELOQUENCE dore qui tourne"
    echo.
    echo ⚠️  Note: Blender doit etre installe pour generer les images
    echo 📱 Une page HTML s'ouvrira dans votre navigateur
    echo.
    pause
    exit /b
)

echo 🚀 Lancement de la previsualisation visuelle...
echo 📝 Prompt: "%~1"
echo.

python preview_visual.py "%~1"

echo.
echo ✅ Previsualisation terminee!
echo 🌐 La page devrait s'ouvrir automatiquement dans votre navigateur
echo.
pause