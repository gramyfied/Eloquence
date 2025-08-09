@echo off
chcp 65001 >nul
title Force Push Git Eloquence

echo.
echo ========================================
echo        FORCE PUSH GIT ELOQUENCE
echo ========================================
echo.

echo ⚠️  ATTENTION: Ce script va forcer le push !
echo.

echo 🔍 Vérification du statut git...
git status

echo.
echo 📦 Ajout de tous les fichiers...
git add .

echo.
echo 💾 Commit des modifications...
git commit -m "Configuration centralisée et scripts de mise à jour - $(date /t)"

echo.
echo 🚀 Force push vers le repository distant...
git push --force-with-lease origin feature/cleanup-livekit-config

echo.
echo ✅ Force push terminé !
echo.
pause
