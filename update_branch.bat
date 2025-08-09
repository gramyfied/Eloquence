@echo off
chcp 65001 >nul
title Mise à jour de la branche Eloquence

echo.
echo ========================================
echo   MISE À JOUR DE LA BRANCHE ELOQUENCE
echo ========================================
echo.

echo 🔄 Sauvegarde des modifications actuelles...
git stash push -m "Sauvegarde avant mise à jour avec cursor/fix-livekit-bidirectional-ai-connection-cf4b"
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la sauvegarde
    pause
    exit /b 1
)

echo.
echo 📥 Récupération des dernières modifications...
git fetch origin
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la récupération
    pause
    exit /b 1
)

echo.
echo 🔀 Changement vers la nouvelle branche...
git checkout -b cursor/fix-livekit-bidirectional-ai-connection-cf4b origin/cursor/fix-livekit-bidirectional-ai-connection-cf4b
if %errorlevel% neq 0 (
    echo ❌ Erreur lors du changement de branche
    pause
    exit /b 1
)

echo.
echo ✅ Mise à jour terminée avec succès !
echo.
echo 📋 Informations utiles :
echo    - Pour voir le statut : git status
echo    - Pour voir les branches : git branch
echo    - Pour récupérer vos modifications : git stash pop
echo.
pause
