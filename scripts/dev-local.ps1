#!/usr/bin/env pwsh

# Script de démarrage pour configuration locale Eloquence (192.168.1.44)
# Utilise docker-compose.local.yml avec tous les services sur l'IP locale

Write-Host "🏠 Démarrage d'Eloquence en configuration LOCALE (192.168.1.44)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan

# Vérifier que Docker est en cours d'exécution
Write-Host "🔍 Vérification de Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✅ Docker est opérationnel" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker n'est pas démarré. Veuillez démarrer Docker Desktop." -ForegroundColor Red
    exit 1
}

# Arrêter les services existants
Write-Host "🛑 Arrêt des services existants..." -ForegroundColor Yellow
docker-compose down 2>$null

# Démarrer avec la configuration locale
Write-Host "🚀 Démarrage des services avec docker-compose.local.yml..." -ForegroundColor Yellow
docker-compose -f docker-compose.local.yml up -d

# Attendre que les services démarrent
Write-Host "⏳ Attente du démarrage des services..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Vérifier l'état des services
Write-Host "📊 État des services:" -ForegroundColor Cyan
docker-compose -f docker-compose.local.yml ps

Write-Host ""
Write-Host "🎯 SERVICES DISPONIBLES SUR 192.168.1.44:" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "✅ API Principale:        http://192.168.1.44:8080" -ForegroundColor White
Write-Host "✅ Mistral Conversation:  http://192.168.1.44:8001" -ForegroundColor White  
Write-Host "✅ Vosk STT:             http://192.168.1.44:8002" -ForegroundColor White
Write-Host "✅ LiveKit Server:        ws://192.168.1.44:7880" -ForegroundColor White
Write-Host "✅ Redis:                 192.168.1.44:6379" -ForegroundColor White

Write-Host ""
Write-Host "📱 L'application Flutter est configurée pour utiliser ces endpoints par défaut." -ForegroundColor Green
Write-Host "🔄 Pour revenir au serveur distant, utilisez le toggle dans l'app ou modifiez api_config.dart" -ForegroundColor Yellow

Write-Host ""
Write-Host "📋 Commandes utiles:" -ForegroundColor Cyan
Write-Host "  - Logs:    docker-compose -f docker-compose.local.yml logs -f" -ForegroundColor White
Write-Host "  - Stop:    docker-compose -f docker-compose.local.yml down" -ForegroundColor White
Write-Host "  - Status:  docker-compose -f docker-compose.local.yml ps" -ForegroundColor White

Write-Host ""
Write-Host "🎉 Configuration locale prête ! Tous les services sont sur 192.168.1.44" -ForegroundColor Green
