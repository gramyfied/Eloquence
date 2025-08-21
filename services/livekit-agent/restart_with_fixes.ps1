#!/usr/bin/env pwsh

Write-Host "🔄 Redémarrage des services avec les corrections appliquées..." -ForegroundColor Cyan

# Aller au répertoire racine du projet
Set-Location "../../"

Write-Host "📋 Affichage des services actuels..." -ForegroundColor Yellow
docker-compose ps

Write-Host "🛑 Arrêt des services LiveKit Agent..." -ForegroundColor Red
docker-compose stop livekit-agent-multiagent

Write-Host "🔄 Reconstruction de l'image avec les nouvelles corrections..." -ForegroundColor Magenta
docker-compose build livekit-agent-multiagent

Write-Host "🚀 Redémarrage du service avec les corrections..." -ForegroundColor Green
docker-compose up -d livekit-agent-multiagent

Write-Host "📊 Vérification du statut..." -ForegroundColor Blue
docker-compose ps livekit-agent-multiagent

Write-Host "📝 Affichage des derniers logs (10 dernières lignes)..." -ForegroundColor Cyan
docker-compose logs --tail=10 livekit-agent-multiagent

Write-Host "✅ Services redémarrés avec les corrections !" -ForegroundColor Green
Write-Host "🔍 Pour surveiller les logs en temps réel :" -ForegroundColor Yellow
Write-Host "   docker-compose logs -f livekit-agent-multiagent" -ForegroundColor White
