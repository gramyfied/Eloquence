@echo off
chcp 65001 >nul
title Push du code Eloquence

echo.
echo ========================================
echo        PUSH DU CODE ELOQUENCE
echo ========================================
echo.

echo 🔍 Vérification du statut git...
git status

echo.
echo 📦 Ajout de tous les fichiers modifiés...
git add .

echo.
echo 💾 Commit des modifications...
git commit -m "Ajout des scripts de mise à jour de branche et configuration centralisée"

echo.
echo 🚀 Push vers le repository distant...
git push origin feature/cleanup-livekit-config

echo.
echo ✅ Code poussé avec succès !
echo.
pause
