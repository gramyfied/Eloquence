# Script de diagnostic Git Eloquence
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        DIAGNOSTIC GIT ELOQUENCE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Vérification du statut git..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "🌐 Vérification des remotes..." -ForegroundColor Blue
git remote -v

Write-Host ""
Write-Host "📋 Vérification des branches locales..." -ForegroundColor Blue
git branch

Write-Host ""
Write-Host "📥 Vérification des branches distantes..." -ForegroundColor Blue
git branch -r

Write-Host ""
Write-Host "🔄 Vérification du dernier commit..." -ForegroundColor Blue
git log --oneline -5

Write-Host ""
Write-Host "📊 Vérification des stashes..." -ForegroundColor Blue
git stash list

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        FIN DU DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer..."
