# Script de demarrage environnement de developpement Eloquence
Write-Host "Demarrage environnement de developpement Eloquence" -ForegroundColor Green

# Verifier Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker non installe" -ForegroundColor Red
    exit 1
}

# Nettoyer environnement precedent
Write-Host "Nettoyage environnement..." -ForegroundColor Yellow
docker-compose -f docker-compose-new.yml down -v 2>$null

# Construire et demarrer services
Write-Host "Construction des services..." -ForegroundColor Blue
docker-compose -f docker-compose-new.yml build

Write-Host "Demarrage des services..." -ForegroundColor Blue
docker-compose -f docker-compose-new.yml up -d

# Attendre que les services soient prets
Write-Host "Attente des services..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verifier sante des services
Write-Host "Verification sante des services..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
    Write-Host "API principale accessible" -ForegroundColor Green
} catch {
    Write-Host "API principale non accessible" -ForegroundColor Yellow
}

try {
    Invoke-RestMethod -Uri "http://localhost:8002/health" -Method Get
    Write-Host "Vosk STT accessible" -ForegroundColor Green
} catch {
    Write-Host "Vosk STT non accessible" -ForegroundColor Yellow
}

try {
    Invoke-RestMethod -Uri "http://localhost:8001/health" -Method Get
    Write-Host "Mistral accessible" -ForegroundColor Green
} catch {
    Write-Host "Mistral non accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Environnement de developpement pret !" -ForegroundColor Green
Write-Host "API principale: http://localhost:8080" -ForegroundColor White
Write-Host "Vosk STT: http://localhost:8002" -ForegroundColor White
Write-Host "Mistral: http://localhost:8001" -ForegroundColor White
Write-Host "Redis: localhost:6379" -ForegroundColor White
Write-Host "LiveKit: ws://localhost:7880" -ForegroundColor White
Write-Host ""
Write-Host "Commandes utiles:" -ForegroundColor Cyan
Write-Host "  .\scripts\logs.ps1          - Voir tous les logs" -ForegroundColor White
Write-Host "  .\scripts\logs.ps1 [service] - Logs d'un service" -ForegroundColor White
Write-Host "  .\scripts\stop.ps1          - Arreter l'environnement" -ForegroundColor White
