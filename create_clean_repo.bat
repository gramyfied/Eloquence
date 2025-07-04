@echo off
echo 🚀 CREATION D'UN REPOSITORY ELOQUENCE PROPRE
echo ============================================

echo.
echo 📊 Problème identifié:
echo - Repository actuel: 3.01 GiB (trop volumineux pour GitHub)
echo - Fichiers de build Flutter: ~1 GB
echo - Git pack: 3.23 GB
echo - Solution: Nouveau repository propre sans historique lourd
echo.

set /p confirm="Voulez-vous créer un repository propre ? (o/n): "
if /i not "%confirm%"=="o" goto end

echo.
echo 📁 Création du dossier propre...
cd ..
if exist "Eloquence-Clean" rmdir /s /q "Eloquence-Clean"
mkdir "Eloquence-Clean"
cd "Eloquence-Clean"

echo.
echo 📋 Copie des fichiers essentiels...

REM Copier la structure principale
xcopy "..\25Eloquence-Finalisation\services" "services\" /E /I /Q /EXCLUDE:..\25Eloquence-Finalisation\exclude_list.txt
xcopy "..\25Eloquence-Finalisation\frontend\flutter_app\lib" "frontend\flutter_app\lib\" /E /I /Q
xcopy "..\25Eloquence-Finalisation\frontend\flutter_app\android\app\src" "frontend\flutter_app\android\app\src\" /E /I /Q
xcopy "..\25Eloquence-Finalisation\docs" "docs\" /E /I /Q

REM Copier les fichiers de configuration
copy "..\25Eloquence-Finalisation\docker-compose.yml" .
copy "..\25Eloquence-Finalisation\.env.example" .
copy "..\25Eloquence-Finalisation\.gitignore" .
copy "..\25Eloquence-Finalisation\.gitattributes" .
copy "..\25Eloquence-Finalisation\.dockerignore" .
copy "..\25Eloquence-Finalisation\README.md" .
copy "..\25Eloquence-Finalisation\GUIDE_DEMARRAGE_ELOQUENCE.md" .
copy "..\25Eloquence-Finalisation\ARCHITECTURE_PROJET_ELOQUENCE.md" .

REM Copier les fichiers Flutter essentiels
copy "..\25Eloquence-Finalisation\frontend\flutter_app\pubspec.yaml" "frontend\flutter_app\"
copy "..\25Eloquence-Finalisation\frontend\flutter_app\analysis_options.yaml" "frontend\flutter_app\"
copy "..\25Eloquence-Finalisation\frontend\flutter_app\android\build.gradle.kts" "frontend\flutter_app\android\"
copy "..\25Eloquence-Finalisation\frontend\flutter_app\android\settings.gradle.kts" "frontend\flutter_app\android\"
copy "..\25Eloquence-Finalisation\frontend\flutter_app\android\gradle.properties" "frontend\flutter_app\android\"
copy "..\25Eloquence-Finalisation\frontend\flutter_app\android\app\build.gradle.kts" "frontend\flutter_app\android\app\"

echo.
echo 🗑️ Suppression des fichiers volumineux...
REM Supprimer les dossiers de build
if exist "frontend\flutter_app\build" rmdir /s /q "frontend\flutter_app\build"
if exist "frontend\flutter_app\.dart_tool" rmdir /s /q "frontend\flutter_app\.dart_tool"
if exist "frontend\flutter_app\android\.gradle" rmdir /s /q "frontend\flutter_app\android\.gradle"

REM Supprimer les caches et fichiers temporaires
if exist "services\api-backend\.local" rmdir /s /q "services\api-backend\.local"
if exist "services\whisper-stt\.cache" rmdir /s /q "services\whisper-stt\.cache"

REM Supprimer les fichiers de logs
del /s /q *.log 2>nul

echo.
echo 🔧 Initialisation Git...
git init
git add .
git commit -m "🎯 Initial commit: Projet Eloquence propre

✅ Fonctionnalités:
- Architecture microservices complète
- Application Flutter mobile
- Agent IA conversationnel temps réel
- Pipeline audio STT/TTS
- Documentation complète

🔒 Sécurité:
- Fichiers sensibles exclus
- Configuration via .env.example
- .gitignore optimisé

📊 Taille optimisée: ~50MB (vs 3GB précédent)"

echo.
echo 🌐 Configuration du remote GitHub...
git remote add origin https://github.com/gramyfied/Eloquence.git

echo.
echo 🚀 Tentative de push...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ✅ SUCCESS! Repository propre créé et poussé sur GitHub
    echo 📁 Dossier: %cd%
    echo 🌐 URL: https://github.com/gramyfied/Eloquence
    echo.
    echo 📋 Prochaines étapes:
    echo 1. Vérifier le repository sur GitHub
    echo 2. Cloner le repository propre pour développement
    echo 3. Configurer les variables d'environnement (.env)
    echo 4. Lancer avec: docker-compose up
) else (
    echo.
    echo ❌ Erreur lors du push
    echo 💡 Solutions alternatives:
    echo 1. Créer un nouveau repository sur GitHub
    echo 2. Utiliser GitHub Desktop pour le push
    echo 3. Compresser et uploader manuellement
)

:end
echo.
pause