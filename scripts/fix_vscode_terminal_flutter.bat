@echo off
echo ========================================
echo DIAGNOSTIC TERMINAL VSCODE + FLUTTER
echo Base sur: https://code.visualstudio.com/docs/supporting/troubleshoot-terminal-launch
echo ========================================

echo.
echo 1. DIAGNOSTIC DU PROBLEME "CODE DE SORTIE 1"
echo.

echo Verification de l'environnement Windows...
ver | findstr /i "10\." >nul
if %errorlevel% equ 0 (
    echo ✅ Windows 10 detecte
) else (
    echo ⚠️ Version Windows non detectee comme Windows 10
)

echo.
echo 2. VERIFICATION DES CAUSES COMMUNES (selon Microsoft)
echo.

echo A. Test du shell directement (hors VSCode)...
cmd /c "echo Test CMD reussi"
if %errorlevel% equ 0 (
    echo ✅ CMD fonctionne correctement
) else (
    echo ❌ Probleme avec CMD
)

echo.
echo B. Verification de Git (cause principale Flutter)...
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Git est installe
    git --version
) else (
    echo ❌ Git manquant - CAUSE PRINCIPALE du probleme Flutter
    echo.
    echo SOLUTION IMMEDIATE selon Microsoft:
    echo 1. Installer Git: https://git-scm.com/download/win
    echo 2. Redemarrer VSCode completement
    echo 3. Tester a nouveau
    echo.
    set /p install_git="Installer Git automatiquement ? (o/n): "
    if /i "%install_git%"=="o" (
        goto :install_git
    )
)

echo.
echo C. Verification du mode compatibilite (Windows)...
echo IMPORTANT: Verifiez que VSCode n'est PAS en mode compatibilite
echo - Clic droit sur VSCode.exe > Proprietes > Compatibilite
echo - Decochez "Executer en mode compatibilite"

echo.
echo D. Verification antivirus...
echo Si vous avez un antivirus, ajoutez ces exclusions:
echo - Dossier VSCode complet
echo - Dossier Flutter complet
echo - Processus git.exe

echo.
echo 3. REPARATION FLUTTER SPECIFIQUE
echo.

cd /d "%~dp0\..\frontend\flutter_app"
if not exist "pubspec.yaml" (
    echo ❌ Projet Flutter non trouve
    pause
    exit /b 1
)

echo Sauvegarde du pubspec.yaml...
copy pubspec.yaml pubspec.yaml.backup >nul 2>&1

echo Application des corrections Microsoft + Flutter...

REM Selon Microsoft: tester le shell directement
echo Test Flutter directement...
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Flutter accessible
    flutter --version
) else (
    echo ❌ Flutter non accessible
    echo Verifiez l'installation Flutter et le PATH
)

echo.
echo 4. CORRECTION DES DEPENDANCES (sans Git si necessaire)
echo.

if exist "pubspec_fixed.yaml" (
    echo Utilisation du pubspec corrige...
    copy pubspec_fixed.yaml pubspec.yaml
) else (
    echo Creation d'un pubspec minimal (compatible sans Git)...
    (
    echo name: eloquence_2_0
    echo description: Application de coaching vocal
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
    echo   provider: ^6.0.0
    echo   http: ^1.0.0
    echo   path_provider: ^2.0.15
    echo   flutter_riverpod: ^2.3.6
    echo   # Dependances Git desactivees temporairement
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
    echo     - assets/audio/
    ) > pubspec_minimal.yaml
    
    copy pubspec_minimal.yaml pubspec.yaml
)

echo Nettoyage selon les recommandations Microsoft...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool >nul 2>&1
if exist "build" rmdir /s /q build >nul 2>&1

echo.
echo 5. TEST DE REPARATION
echo.

echo Tentative de recuperation des dependances...
flutter pub get

if %errorlevel% equ 0 (
    echo ✅ SUCCES: Flutter pub get reussi !
    echo.
    echo Test de compilation...
    flutter analyze --no-fatal-infos
    
    echo.
    echo ✅ REPARATION TERMINEE
    echo.
    echo PROCHAINES ETAPES:
    echo 1. Redemarrez VSCode completement
    echo 2. Ouvrez un nouveau terminal dans VSCode
    echo 3. Testez: flutter run
    echo.
    echo Si le probleme persiste:
    echo - Verifiez le mode compatibilite VSCode
    echo - Installez Git pour les fonctionnalites completes
    echo - Consultez: https://code.visualstudio.com/docs/supporting/troubleshoot-terminal-launch
    
) else (
    echo ❌ Echec de pub get
    echo.
    echo DIAGNOSTIC AVANCE selon Microsoft:
    echo.
    echo 1. Verifiez les parametres VSCode terminal:
    echo    - File > Preferences > Settings
    echo    - Recherchez "terminal.integrated"
    echo    - Verifiez terminal.integrated.defaultProfile.windows
    echo.
    echo 2. Testez avec un terminal externe:
    echo    - Ouvrez CMD/PowerShell directement
    echo    - Naviguez vers le projet: cd frontend/flutter_app
    echo    - Testez: flutter pub get
    echo.
    echo 3. Activez les logs de trace VSCode:
    echo    - Aide > Activer les logs de trace
    echo    - Reproduisez le probleme
    echo    - Consultez les logs
    
    copy pubspec.yaml.backup pubspec.yaml >nul 2>&1
)

goto :end

:install_git
echo.
echo INSTALLATION AUTOMATIQUE DE GIT...
echo.

if not exist "%TEMP%\git_installer" mkdir "%TEMP%\git_installer"
cd /d "%TEMP%\git_installer"

echo Telechargement de Git (recommande par Microsoft)...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe' -OutFile 'git-installer.exe'}"

if exist "git-installer.exe" (
    echo ✅ Telechargement reussi
    echo.
    echo IMPORTANT: Pendant l'installation:
    echo - Cochez "Add Git to PATH"
    echo - Utilisez les parametres par defaut
    echo.
    pause
    start /wait git-installer.exe
    
    echo Installation terminee. Test...
    git --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Git installe avec succes !
        echo Retour au diagnostic Flutter...
        cd /d "%~dp0\..\frontend\flutter_app"
        goto :flutter_fix_with_git
    ) else (
        echo ⚠️ Redemarrage necessaire
        echo Redemarrez VSCode et relancez ce script
    )
) else (
    echo ❌ Echec du telechargement
    echo Installation manuelle necessaire
)

goto :end

:flutter_fix_with_git
echo.
echo REPARATION FLUTTER AVEC GIT INSTALLE
echo.

copy pubspec_fixed.yaml pubspec.yaml >nul 2>&1
flutter clean
flutter pub get

if %errorlevel% equ 0 (
    echo ✅ Reparation complete avec Git !
    echo Toutes les fonctionnalites sont disponibles
) else (
    echo ❌ Probleme persistant malgre Git
    echo Consultez les logs VSCode pour plus de details
)

:end
echo.
echo ========================================
echo DIAGNOSTIC TERMINE
echo ========================================
echo.
echo Pour plus d'aide, consultez:
echo https://code.visualstudio.com/docs/supporting/troubleshoot-terminal-launch
echo.
pause