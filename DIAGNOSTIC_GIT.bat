@echo off
chcp 65001 >nul
title Diagnostic Git Eloquence

echo.
echo ========================================
echo        DIAGNOSTIC GIT ELOQUENCE
echo ========================================
echo.

echo 🔍 Vérification du statut git...
git status

echo.
echo 🌐 Vérification des remotes...
git remote -v

echo.
echo 📋 Vérification des branches locales...
git branch

echo.
echo 📥 Vérification des branches distantes...
git branch -r

echo.
echo 🔄 Vérification du dernier commit...
git log --oneline -5

echo.
echo 📊 Vérification des stashes...
git stash list

echo.
echo ========================================
echo        FIN DU DIAGNOSTIC
echo ========================================
pause
