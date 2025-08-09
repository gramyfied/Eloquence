# Script de push du code Eloquence
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        PUSH DU CODE ELOQUENCE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Vérification du statut git..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "📦 Ajout de tous les fichiers modifiés..." -ForegroundColor Blue
git add .

Write-Host ""
Write-Host "💾 Commit des modifications..." -ForegroundColor Blue
git commit -m "Ajout des scripts de mise à jour de branche et configuration centralisée"

Write-Host ""
Write-Host "🚀 Push vers le repository distant..." -ForegroundColor Blue
git push origin feature/cleanup-livekit-config

Write-Host ""
Write-Host "✅ Code poussé avec succès !" -ForegroundColor Green
Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer..."
