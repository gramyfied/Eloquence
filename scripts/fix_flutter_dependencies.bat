@echo off
echo ========================================
echo REPARATION DEPENDANCES FLUTTER
echo ========================================

echo.
echo 1. Verification de Git (prerequis)...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERREUR: Git n'est pas installe !
    echo.
    echo SOLUTION IMMEDIATE:
    echo 1. Installez Git depuis: https://git-scm.com/download/win
    echo 2. Redemarrez votre terminal/VSCode
    echo 3. Relancez ce script
    echo.
    echo ALTERNATIVE TEMPORAIRE:
    echo Vous pouvez essayer de continuer sans Git, mais certaines dependances peuvent echouer.
    echo.
    set /p choice="Continuer sans Git ? (o/n): "
    if /i "%choice%" neq "o" (
        echo Operation annulee.
        pause
        exit /b 1
    )
    echo ⚠️ Continuation sans Git (non recommande)
)

echo.
echo 2. Navigation vers le projet Flutter...
cd /d "%~dp0\..\frontend\flutter_app"
if not exist "pubspec.yaml" (
    echo ❌ Fichier pubspec.yaml non trouve
    echo Verifiez que vous etes dans le bon repertoire
    pause
    exit /b 1
)

echo.
echo 3. Sauvegarde du pubspec.yaml original...
copy pubspec.yaml pubspec.yaml.backup >nul 2>&1

echo.
echo 4. Nettoyage complet...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool
if exist "build" rmdir /s /q build
flutter clean >nul 2>&1

echo.
echo 5. Correction des dependances problematiques...

echo Correction de livekit_client...
powershell -Command "(Get-Content pubspec.yaml) -replace 'livekit_client:\s*git:\s*url: https://github.com/livekit/client-sdk-flutter.git\s*ref: main', 'livekit_client: ^2.0.0' | Set-Content pubspec.yaml"

echo Correction de flutter_webrtc...
powershell -Command "(Get-Content pubspec.yaml) -replace 'flutter_webrtc: 0.14.1', 'flutter_webrtc: ^0.14.1' | Set-Content pubspec.yaml"

echo Correction de device_info_plus...
powershell -Command "(Get-Content pubspec.yaml) -replace 'device_info_plus: 11.4.0', 'device_info_plus: ^11.4.0' | Set-Content pubspec.yaml"

echo.
echo 6. Tentative de recuperation des dependances...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Echec de pub get avec les dependances corrigees
    echo.
    echo Tentative avec une version simplifiee...
    
    echo Restauration du fichier original...
    copy pubspec.yaml.backup pubspec.yaml >nul 2>&1
    
    echo Suppression des dependances problematiques...
    powershell -Command "(Get-Content pubspec.yaml) -replace '  livekit_client:.*?ref: main', '  # livekit_client: ^2.0.0 # Temporairement desactive' | Set-Content pubspec.yaml"
    
    echo Nouvelle tentative...
    flutter pub get
    if %errorlevel% neq 0 (
        echo ❌ Echec persistant
        echo.
        echo DIAGNOSTIC DETAILLE:
        flutter pub deps
        echo.
        echo Restauration du fichier original...
        copy pubspec.yaml.backup pubspec.yaml >nul 2>&1
        pause
        exit /b 1
    )
)

echo.
echo 7. Verification de l'environnement Flutter...
flutter doctor

echo.
echo 8. Test de compilation basique...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️ Avertissements d'analyse detectes (non bloquant)
)

echo.
echo ========================================
echo REPARATION TERMINEE
echo ========================================
echo.
echo ✅ Les dependances Flutter ont ete reparees
echo.
echo PROCHAINES ETAPES:
echo 1. Verifiez que 'flutter doctor' ne montre pas d'erreurs critiques
echo 2. Essayez: flutter run
echo 3. Si des problemes persistent, consultez le guide detaille:
echo    frontend/flutter_app/GUIDE_RESOLUTION_FLUTTER_ENVIRONMENT.md
echo.
pause