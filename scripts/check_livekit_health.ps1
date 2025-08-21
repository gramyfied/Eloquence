# Script de diagnostic pour vérifier l'état de santé du système LiveKit
Write-Host "🔍 === DIAGNOSTIC SYSTÈME LIVEKIT ===" -ForegroundColor Cyan

# Vérifier les conteneurs Docker
Write-Host "`n📦 Vérification des conteneurs Docker..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String "eloquence"

# Vérifier les logs du serveur LiveKit
Write-Host "`n🔗 Vérification des logs LiveKit Server..." -ForegroundColor Yellow
docker logs eloquence-livekit-server-1 --tail 10

# Vérifier les logs de l'agent
Write-Host "`n🤖 Vérification des logs Agent Multi-Agent..." -ForegroundColor Yellow
docker logs eloquence-multiagent --tail 10

# Vérifier la connectivité réseau
Write-Host "`n🌐 Test de connectivité..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8780" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ LiveKit Server accessible sur le port 8780" -ForegroundColor Green
} catch {
    Write-Host "❌ LiveKit Server non accessible sur le port 8780" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Agent Multi-Agent accessible sur le port 8080" -ForegroundColor Green
} catch {
    Write-Host "❌ Agent Multi-Agent non accessible sur le port 8080" -ForegroundColor Red
}

# Vérifier les services Redis et Mistral
Write-Host "`n🔧 Vérification des services de support..." -ForegroundColor Yellow
docker logs eloquence-redis-1 --tail 5
docker logs eloquence-mistral-conversation-1 --tail 5

Write-Host "`n✅ Diagnostic terminé" -ForegroundColor Green
