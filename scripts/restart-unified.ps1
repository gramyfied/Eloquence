# Script de redémarrage unifié pour Eloquence
Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host "  ELOQUENCE - Redémarrage Unifié`n" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# Arrêt des services existants
Write-Host "[1/4] Arrêt des services existants..." -ForegroundColor Yellow
docker-compose -f docker-compose-unified.yml down

# Nettoyage
Write-Host "[2/4] Nettoyage des conteneurs orphelins..." -ForegroundColor Yellow
docker container prune -f | Out-Null

# Reconstruction
Write-Host "[3/4] Reconstruction de livekit-agent..." -ForegroundColor Yellow
docker-compose -f docker-compose-unified.yml build livekit-agent

# Démarrage
Write-Host "[4/4] Démarrage des services..." -ForegroundColor Green
docker-compose -f docker-compose-unified.yml up -d

# Attente
Write-Host "Attente de stabilisation (30s)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# État des services
Write-Host "État des services:" -ForegroundColor Cyan
docker-compose -f docker-compose-unified.yml ps

Write-Host "`n==========================================`n" -ForegroundColor Green
Write-Host "  Redémarrage terminé!`n" -ForegroundColor Green
Write-Host "==========================================`n" -ForegroundColor Green