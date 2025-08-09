# Script de mise à jour de la branche
Write-Host "🔄 Mise à jour de la branche..." -ForegroundColor Yellow

# Sauvegarde des modifications actuelles
Write-Host "💾 Sauvegarde des modifications..." -ForegroundColor Blue
git stash push -m "Sauvegarde avant mise à jour avec cursor/fix-livekit-bidirectional-ai-connection-cf4b"

# Récupération de la nouvelle branche
Write-Host "📥 Récupération de la branche cursor/fix-livekit-bidirectional-ai-connection-cf4b..." -ForegroundColor Blue
git fetch origin
git checkout -b cursor/fix-livekit-bidirectional-ai-connection-cf4b origin/cursor/fix-livekit-bidirectional-ai-connection-cf4b

Write-Host "✅ Mise à jour terminée !" -ForegroundColor Green
Write-Host "📋 Pour récupérer vos modifications: git stash pop" -ForegroundColor Cyan
