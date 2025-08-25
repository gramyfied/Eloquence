# Script de redémarrage corrigé pour Eloquence
Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host "  ELOQUENCE - Redémarrage Corrigé`n" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# Arrêt des services existants
Write-Host "[1/4] Arrêt des services existants..." -ForegroundColor Yellow
docker-compose down

# Nettoyage
Write-Host "[2/4] Nettoyage des conteneurs orphelins..." -ForegroundColor Yellow
docker container prune -f | Out-Null

# Reconstruction du livekit-agent avec les nouveaux prompts
Write-Host "[3/4] Reconstruction de livekit-agent avec prompts optimisés..." -ForegroundColor Yellow
docker-compose build livekit-agent-multiagent

# Démarrage
Write-Host "[4/4] Démarrage des services..." -ForegroundColor Green
docker-compose up -d

# Attente
Write-Host "Attente de stabilisation (30s)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# État des services
Write-Host "État des services:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n==========================================`n" -ForegroundColor Green
Write-Host "  Redémarrage terminé avec prompts révolutionnaires!`n" -ForegroundColor Green
Write-Host "==========================================`n" -ForegroundColor Green
