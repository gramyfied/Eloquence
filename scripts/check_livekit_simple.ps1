# Script de diagnostic simple pour LiveKit
Write-Host "=== DIAGNOSTIC SYSTÈME LIVEKIT ===" -ForegroundColor Cyan

# Vérifier les conteneurs Docker
Write-Host "`nVérification des conteneurs Docker..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String "eloquence"

# Vérifier les logs du serveur LiveKit
Write-Host "`nLogs LiveKit Server (dernières 5 lignes):" -ForegroundColor Yellow
docker logs eloquence-livekit-server-1 --tail 5

# Vérifier les logs de l'agent
Write-Host "`nLogs Agent Multi-Agent (dernières 5 lignes):" -ForegroundColor Yellow
docker logs eloquence-multiagent --tail 5

# Vérifier la connectivité réseau
Write-Host "`nTest de connectivité..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8780" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "SUCCESS: LiveKit Server accessible sur le port 8780" -ForegroundColor Green
} catch {
    Write-Host "ERROR: LiveKit Server non accessible sur le port 8780" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "SUCCESS: Agent Multi-Agent accessible sur le port 8080" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Agent Multi-Agent non accessible sur le port 8080" -ForegroundColor Red
}

Write-Host "`nDiagnostic terminé" -ForegroundColor Green
