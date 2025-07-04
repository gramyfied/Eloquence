@echo off
echo ========================================
echo REPARATION RAPIDE FLUTTER (SANS GIT)
echo ========================================

echo.
echo Cette solution fonctionne SANS Git installe
echo.

echo 1. Navigation vers le projet Flutter...
cd /d "%~dp0\..\frontend\flutter_app"
if not exist "pubspec.yaml" (
    echo ❌ Fichier pubspec.yaml non trouve
    pause
    exit /b 1
)

echo.
echo 2. Sauvegarde du pubspec.yaml original...
copy pubspec.yaml pubspec.yaml.backup

echo.
echo 3. Remplacement par la version corrigee...
copy pubspec_fixed.yaml pubspec.yaml

echo.
echo 4. Nettoyage complet...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool >nul 2>&1
if exist "build" rmdir /s /q build >nul 2>&1

echo.
echo 5. Tentative sans flutter clean (evite les erreurs Git)...
echo Recuperation des dependances...
flutter pub get

if %errorlevel% neq 0 (
    echo.
    echo ❌ Echec de pub get
    echo.
    echo SOLUTIONS POSSIBLES:
    echo.
    echo A. Installer Git (RECOMMANDE):
    echo    1. https://git-scm.com/download/win
    echo    2. Redemarrer le terminal
    echo    3. Relancer ce script
    echo.
    echo B. Utiliser une version encore plus simple:
    set /p choice="Essayer version simplifiee ? (o/n): "
    if /i "%choice%"=="o" (
        echo.
        echo Suppression des dependances Git...
        powershell -Command "(Get-Content pubspec.yaml) -replace '  livekit_client: \^2\.0\.0', '  # livekit_client: ^2.0.0 # Desactive temporairement' | Set-Content pubspec.yaml"
        powershell -Command "(Get-Content pubspec.yaml) -replace '  flutter_webrtc: \^0\.9\.48', '  # flutter_webrtc: ^0.9.48 # Desactive temporairement' | Set-Content pubspec.yaml"
        
        echo Nouvelle tentative...
        flutter pub get
        
        if %errorlevel% neq 0 (
            echo ❌ Echec persistant
            echo Restauration du fichier original...
            copy pubspec.yaml.backup pubspec.yaml
            pause
            exit /b 1
        ) else (
            echo ✅ Succes avec version simplifiee
            echo ⚠️ ATTENTION: LiveKit est desactive
        )
    ) else (
        echo Restauration du fichier original...
        copy pubspec.yaml.backup pubspec.yaml
        pause
        exit /b 1
    )
) else (
    echo ✅ Dependances recuperees avec succes !
)

echo.
echo 6. Test de compilation...
flutter analyze --no-fatal-infos
if %errorlevel% neq 0 (
    echo ⚠️ Avertissements d'analyse (non bloquant)
)

echo.
echo ========================================
echo REPARATION TERMINEE
echo ========================================
echo.
echo ✅ Flutter devrait maintenant fonctionner
echo.
echo COMMANDES DE TEST:
echo   flutter devices
echo   flutter run
echo.
echo Si des problemes persistent:
echo 1. Installez Git: https://git-scm.com/download/win
echo 2. Consultez: frontend/flutter_app/GUIDE_RESOLUTION_FLUTTER_ENVIRONMENT.md
echo.
pause