# Script de démarrage Eloquence pour Windows PowerShell
Write-Host "🚀 DÉMARRAGE ELOQUENCE - CONFIGURATION SIMPLE" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Vérifier que .env existe
if (-not (Test-Path ".env")) {
    Write-Host "❌ Fichier .env manquant" -ForegroundColor Red
    Write-Host "Copiez env_template.txt vers .env et configurez OPENAI_API_KEY" -ForegroundColor Yellow
    exit 1
}

# Vérifier que OPENAI_API_KEY est configurée
$envContent = Get-Content ".env"
if (-not ($envContent | Select-String "OPENAI_API_KEY=sk-")) {
    Write-Host "❌ OPENAI_API_KEY non configurée dans .env" -ForegroundColor Red
    Write-Host "Ajoutez votre vraie clé OpenAI dans le fichier .env" -ForegroundColor Yellow
    exit 1
}

# Arrêter les services existants
Write-Host "🛑 Arrêt des services existants..." -ForegroundColor Yellow
docker-compose down

# Nettoyer les images orphelines
Write-Host "🧹 Nettoyage des images orphelines..." -ForegroundColor Yellow
docker system prune -f

# Construire et démarrer les services
Write-Host "🔨 Construction et démarrage des services..." -ForegroundColor Yellow
docker-compose up --build -d

# Attendre que les services soient prêts
Write-Host "⏳ Attente du démarrage des services..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Vérifier le statut des services
Write-Host "📊 Statut des services:" -ForegroundColor Cyan
docker-compose ps

# Tester la connectivité
Write-Host "🧪 Test de connectivité:" -ForegroundColor Cyan
try {
    $redisTest = Invoke-WebRequest -Uri "http://localhost:6379" -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host "  Redis: ✅ OK" -ForegroundColor Green
} catch {
    Write-Host "  Redis: ❌ ÉCHEC" -ForegroundColor Red
}

try {
    $livekitTest = Invoke-WebRequest -Uri "http://localhost:7880" -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host "  LiveKit: ✅ OK" -ForegroundColor Green
} catch {
    Write-Host "  LiveKit: ❌ ÉCHEC" -ForegroundColor Red
}

try {
    $agentTest = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host "  Agent: ✅ OK" -ForegroundColor Green
} catch {
    Write-Host "  Agent: ❌ ÉCHEC" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 ELOQUENCE DÉMARRÉ AVEC SUCCÈS !" -ForegroundColor Green
Write-Host "📱 Vous pouvez maintenant tester vos exercices" -ForegroundColor Cyan
Write-Host "🔗 URLs importantes:" -ForegroundColor Cyan
Write-Host "   - LiveKit: ws://localhost:7880" -ForegroundColor White
Write-Host "   - Agent: http://localhost:8080" -ForegroundColor White
Write-Host "   - API: http://localhost:8003" -ForegroundColor White
