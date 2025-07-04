@echo off
echo ========================================
echo   Diagnostic Mobile Connectivity
echo ========================================
echo.

REM Vérifier si Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Python n'est pas installé ou n'est pas dans le PATH
    echo Veuillez installer Python depuis https://www.python.org/
    pause
    exit /b 1
)

REM Vérifier si Docker est en cours d'exécution
docker ps >nul 2>&1
if errorlevel 1 (
    echo [AVERTISSEMENT] Docker n'est pas en cours d'exécution ou n'est pas installé
    echo Les tests de services Docker seront ignorés
    echo.
)

REM Installer les dépendances si nécessaire
echo Vérification des dépendances Python...
pip show httpx >nul 2>&1
if errorlevel 1 (
    echo Installation de httpx...
    pip install httpx
)

echo.
echo Lancement du diagnostic...
echo.

REM Exécuter le script de diagnostic
python scripts\diagnostic_mobile_connectivity.py

echo.
echo ========================================
echo   Diagnostic terminé
echo ========================================
echo.
echo Fichiers générés:
echo - frontend/flutter_app/lib/core/config/app_config.dart
echo - frontend/flutter_app/.env.mobile
echo - diagnostic_mobile_*.json
echo.
pause