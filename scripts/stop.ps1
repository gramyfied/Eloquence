# Script d'arrêt environnement Eloquence
Write-Host "🛑 Arrêt environnement Eloquence..." -ForegroundColor Red
docker-compose -f docker-compose-new.yml down -v
Write-Host "✅ Environnement arrêté" -ForegroundColor Green
