# Script PowerShell pour redémarrer les services LiveKit avec les corrections
Write-Host "🔧 REDÉMARRAGE DES SERVICES LIVEKIT AVEC CORRECTIONS" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Arrêter les services existants
Write-Host "`n📛 Arrêt des services LiveKit actuels..." -ForegroundColor Yellow
docker-compose -f docker-compose-new.yml stop livekit-agents
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Pas de services à arrêter ou erreur mineure" -ForegroundColor DarkYellow
}

# Supprimer les conteneurs pour forcer la reconstruction
Write-Host "`n🗑️  Suppression des anciens conteneurs..." -ForegroundColor Yellow
docker-compose -f docker-compose-new.yml rm -f livekit-agents
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Pas de conteneurs à supprimer" -ForegroundColor DarkYellow
}

# Reconstruire avec le nouveau Dockerfile unifié
Write-Host "`n🔨 Reconstruction du service avec le routage unifié..." -ForegroundColor Green
docker-compose -f docker-compose-new.yml build livekit-agents
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la construction!" -ForegroundColor Red
    exit 1
}

# Démarrer le service
Write-Host "`n🚀 Démarrage du service LiveKit unifié..." -ForegroundColor Green
docker-compose -f docker-compose-new.yml up -d livekit-agents
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du démarrage!" -ForegroundColor Red
    exit 1
}

# Attendre que le service soit prêt
Write-Host "`nAttente du demarrage complet (15 secondes)..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Vérifier les logs
Write-Host "`n📋 Derniers logs du service unifié :" -ForegroundColor Cyan
docker-compose -f docker-compose-new.yml logs --tail=50 livekit-agents

Write-Host "`n✅ REDÉMARRAGE TERMINÉ!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📌 CORRECTIONS APPLIQUÉES :" -ForegroundColor Cyan
Write-Host "  ✓ Tribunal des idées : Agent Juge Magistrat (voix onyx)" -ForegroundColor Green
Write-Host "  ✓ Confidence Boost : Agent Thomas (voix alloy)" -ForegroundColor Green  
Write-Host "  ✓ Studio Situations Pro : Agents multi-agents dédiés" -ForegroundColor Green
Write-Host "    (Michel Dubois, Sarah Johnson, Marcus Thompson, etc.)" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 POUR TESTER :" -ForegroundColor Yellow
Write-Host "  1. Lancez l'application Flutter" -ForegroundColor White
Write-Host "  2. Testez chaque exercice pour vérifier :" -ForegroundColor White
Write-Host "     - Tribunal → Juge Magistrat répond" -ForegroundColor White
Write-Host "     - Confidence → Thomas répond" -ForegroundColor White
Write-Host "     - Studio Pro → Les agents dédiés répondent" -ForegroundColor White
Write-Host ""
Write-Host "📊 Pour voir les logs en temps réel :" -ForegroundColor Cyan
Write-Host "  docker-compose -f docker-compose-new.yml logs -f livekit-agents" -ForegroundColor White