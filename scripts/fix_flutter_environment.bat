@echo off
echo ========================================
echo REPARATION ENVIRONNEMENT FLUTTER
echo ========================================

echo.
echo 1. Verification de Git...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git n'est pas installe ou pas dans le PATH
    echo.
    echo SOLUTION: Installez Git pour Windows
    echo 1. Allez sur https://git-scm.com/download/win
    echo 2. Telechargez et installez Git for Windows
    echo 3. Redemarrez votre terminal/VSCode
    echo 4. Relancez ce script
    echo.
    pause
    exit /b 1
) else (
    echo ✅ Git est installe
)

echo.
echo 2. Verification de Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas accessible
    echo Verifiez que Flutter est installe et dans le PATH
    pause
    exit /b 1
) else (
    echo ✅ Flutter est accessible
)

echo.
echo 3. Navigation vers le projet Flutter...
cd /d "%~dp0\..\frontend\flutter_app"
if not exist "pubspec.yaml" (
    echo ❌ Fichier pubspec.yaml non trouve
    echo Verifiez que vous etes dans le bon repertoire
    pause
    exit /b 1
)

echo.
echo 4. Nettoyage du cache Flutter...
flutter clean

echo.
echo 5. Recuperation des dependances...
flutter pub get

echo.
echo 6. Diagnostic Flutter...
flutter doctor

echo.
echo 7. Test de compilation...
flutter build apk --debug --verbose

echo.
echo ========================================
echo REPARATION TERMINEE
echo ========================================
echo.
echo Si tout s'est bien passe, vous pouvez maintenant executer:
echo flutter run
echo.
pause