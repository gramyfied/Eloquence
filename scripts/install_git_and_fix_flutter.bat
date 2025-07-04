@echo off
echo ========================================
echo INSTALLATION GIT + REPARATION FLUTTER
echo ========================================

echo.
echo Ce script va:
echo 1. Tenter d'installer Git automatiquement
echo 2. Reparer l'environnement Flutter
echo 3. Corriger les dependances
echo.

echo Verification de Git...
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Git est deja installe
    goto :flutter_fix
)

echo ❌ Git n'est pas installe
echo.

echo OPTION 1: Installation automatique de Git
echo.
set /p auto_install="Voulez-vous installer Git automatiquement ? (o/n): "

if /i "%auto_install%"=="o" (
    echo.
    echo Telechargement de Git...
    
    REM Créer un dossier temporaire
    if not exist "%TEMP%\git_installer" mkdir "%TEMP%\git_installer"
    cd /d "%TEMP%\git_installer"
    
    echo Telechargement en cours... (cela peut prendre quelques minutes)
    
    REM Utiliser PowerShell pour télécharger Git
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe' -OutFile 'git-installer.exe'}"
    
    if exist "git-installer.exe" (
        echo ✅ Telechargement reussi
        echo.
        echo Installation de Git...
        echo IMPORTANT: Pendant l'installation, assurez-vous de cocher "Add Git to PATH"
        echo.
        pause
        
        REM Lancer l'installateur Git
        start /wait git-installer.exe
        
        echo.
        echo Installation terminee. Verification...
        
        REM Actualiser les variables d'environnement
        call refreshenv >nul 2>&1
        
        REM Tester Git
        git --version >nul 2>&1
        if %errorlevel% equ 0 (
            echo ✅ Git installe avec succes !
            goto :flutter_fix
        ) else (
            echo ❌ Git n'est pas encore accessible
            echo.
            echo SOLUTION:
            echo 1. Redemarrez votre terminal/VSCode
            echo 2. Relancez ce script
            echo 3. Ou ajoutez manuellement Git au PATH
            pause
            exit /b 1
        )
    ) else (
        echo ❌ Echec du telechargement
        goto :manual_install
    )
) else (
    goto :manual_install
)

:manual_install
echo.
echo OPTION 2: Installation manuelle
echo.
echo 1. Allez sur: https://git-scm.com/download/win
echo 2. Telechargez Git for Windows
echo 3. Installez-le (cochez "Add Git to PATH")
echo 4. Redemarrez votre terminal/VSCode
echo 5. Relancez ce script
echo.
echo OPTION 3: Solution temporaire (limitee)
echo.
set /p temp_solution="Essayer une solution temporaire sans Git ? (o/n): "

if /i "%temp_solution%"=="o" (
    goto :temp_solution
) else (
    echo Operation annulee.
    pause
    exit /b 1
)

:temp_solution
echo.
echo ⚠️ SOLUTION TEMPORAIRE (LIMITEE)
echo Cette solution desactive les fonctionnalites LiveKit
echo.

cd /d "%~dp0\..\frontend\flutter_app"

echo Sauvegarde...
copy pubspec.yaml pubspec.yaml.backup >nul 2>&1

echo Creation d'une version minimale...
(
echo name: eloquence_2_0
echo description: Application de coaching vocal pour améliorer l'expression orale
echo publish_to: 'none'
echo version: 1.0.0+1
echo.
echo environment:
echo   sdk: '>=3.0.0 <4.0.0'
echo.
echo dependencies:
echo   flutter:
echo     sdk: flutter
echo   cupertino_icons: ^1.0.2
echo   flutter_riverpod: ^2.3.6
echo   provider: ^6.0.0
echo   dartz: ^0.10.1
echo   equatable: ^2.0.5
echo   path_provider: ^2.0.15
echo   http: ^1.0.0
echo   intl: ^0.18.1
echo   flutter_animate: ^4.1.1+1
echo   flutter_svg: ^2.0.5
echo   cached_network_image: ^3.2.3
echo   shimmer: ^3.0.0
echo   lottie: ^2.4.0
echo   go_router: ^10.0.0
echo   logger: ^2.0.2
echo   flutter_dotenv: ^5.1.0
echo   # LiveKit desactive temporairement - necessite Git
echo.
echo dev_dependencies:
echo   flutter_test:
echo     sdk: flutter
echo   flutter_lints: ^2.0.1
echo.
echo flutter:
echo   uses-material-design: true
echo   assets:
echo     - assets/images/
echo     - assets/animations/
echo     - assets/audio/
echo     - .env
) > pubspec_minimal.yaml

copy pubspec_minimal.yaml pubspec.yaml

echo Nettoyage...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool >nul 2>&1

echo Tentative de recuperation des dependances...
flutter pub get

if %errorlevel% equ 0 (
    echo ✅ Version minimale fonctionnelle !
    echo.
    echo ⚠️ LIMITATIONS:
    echo - Pas de LiveKit (audio en temps reel)
    echo - Pas de WebRTC
    echo - Fonctionnalites audio limitees
    echo.
    echo Pour la version complete, installez Git et relancez le script.
) else (
    echo ❌ Echec meme avec la version minimale
    copy pubspec.yaml.backup pubspec.yaml
)

goto :end

:flutter_fix
echo.
echo ========================================
echo REPARATION FLUTTER AVEC GIT
echo ========================================

cd /d "%~dp0\..\frontend\flutter_app"

echo Sauvegarde...
copy pubspec.yaml pubspec.yaml.backup >nul 2>&1

echo Remplacement par la version corrigee...
copy pubspec_fixed.yaml pubspec.yaml

echo Nettoyage...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool >nul 2>&1
if exist "build" rmdir /s /q build >nul 2>&1

echo Nettoyage Flutter...
flutter clean

echo Recuperation des dependances...
flutter pub get

if %errorlevel% equ 0 (
    echo ✅ Reparation reussie !
    echo.
    echo Test de l'environnement...
    flutter doctor
    echo.
    echo ✅ Flutter est pret !
    echo Vous pouvez maintenant executer: flutter run
) else (
    echo ❌ Echec de la reparation
    echo Restauration...
    copy pubspec.yaml.backup pubspec.yaml
)

:end
echo.
echo ========================================
echo SCRIPT TERMINE
echo ========================================
pause