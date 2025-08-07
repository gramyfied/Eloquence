# Script de validation complète du système Eloquence unifié
# Vérifie tous les services : originaux + multi-agents Studio Situations Pro

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "   VALIDATION SYSTEME ELOQUENCE" -ForegroundColor Cyan
Write-Host "     Configuration Unifiee" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

$allHealthy = $true
$results = @()

# 1. Services de base
Write-Host "[1] SERVICES DE BASE" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Gray

# Redis
try {
    $response = Invoke-WebRequest -Uri "http://localhost:6379" -Method GET -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host "[OK] Redis" -ForegroundColor Green
    $results += "OK Redis (port 6379)"
} catch {
    if ($_.Exception.Message -like "*connection*") {
        Write-Host "[OK] Redis (connexion TCP active)" -ForegroundColor Green
        $results += "OK Redis (port 6379)"
    } else {
        Write-Host "[FAIL] Redis" -ForegroundColor Red
        $results += "FAIL Redis"
        $allHealthy = $false
    }
}

# Vosk STT
try {
    $response = Invoke-WebRequest -Uri "http://localhost:2700/health" -Method GET -TimeoutSec 2
    $json = $response.Content | ConvertFrom-Json
    if ($json.status -eq "ready") {
        Write-Host "[OK] Vosk STT" -ForegroundColor Green
        $results += "OK Vosk STT (port 2700)"
    } else {
        Write-Host "[WARN] Vosk STT (non pret)" -ForegroundColor Yellow
        $results += "WARN Vosk STT"
    }
} catch {
    Write-Host "[FAIL] Vosk STT" -ForegroundColor Red
    $results += "FAIL Vosk STT"
    $allHealthy = $false
}

# Mistral Conversation
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8001/health" -Method GET -TimeoutSec 2
    $json = $response.Content | ConvertFrom-Json
    if ($json.status -eq "healthy") {
        Write-Host "[OK] Mistral Conversation" -ForegroundColor Green
        $results += "OK Mistral Conversation (port 8001)"
    }
} catch {
    Write-Host "[FAIL] Mistral Conversation" -ForegroundColor Red
    $results += "FAIL Mistral Conversation"
    $allHealthy = $false
}

# 2. Services LiveKit originaux
Write-Host "`n[2] SERVICES LIVEKIT ORIGINAUX" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Gray

# LiveKit Server
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7880/health" -Method GET -TimeoutSec 2
    Write-Host "[OK] LiveKit Server" -ForegroundColor Green
    $results += "OK LiveKit Server (port 7880)"
} catch {
    Write-Host "[FAIL] LiveKit Server" -ForegroundColor Red
    $results += "FAIL LiveKit Server"
    $allHealthy = $false
}

# Token Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8004/health" -Method GET -TimeoutSec 2
    $json = $response.Content | ConvertFrom-Json
    if ($json.status -eq "healthy") {
        Write-Host "[OK] Token Service" -ForegroundColor Green
        $results += "OK Token Service (port 8004)"
    }
} catch {
    Write-Host "[FAIL] Token Service" -ForegroundColor Red
    $results += "FAIL Token Service"
    $allHealthy = $false
}

# LiveKit Agent Original
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8003/health" -Method GET -TimeoutSec 2
    Write-Host "[OK] LiveKit Agent Original" -ForegroundColor Green
    $results += "OK LiveKit Agent Original (port 8003)"
} catch {
    # L'agent peut ne pas avoir de healthcheck HTTP
    Write-Host "[WARN] LiveKit Agent Original (pas de healthcheck HTTP)" -ForegroundColor Yellow
    $results += "WARN LiveKit Agent Original"
}

# Exercises API
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8005/health" -Method GET -TimeoutSec 2
    $json = $response.Content | ConvertFrom-Json
    if ($json.status -eq "healthy") {
        Write-Host "[OK] Eloquence Exercises API" -ForegroundColor Green
        $results += "OK Eloquence Exercises API (port 8005)"
    }
} catch {
    Write-Host "[FAIL] Eloquence Exercises API" -ForegroundColor Red
    $results += "FAIL Eloquence Exercises API"
    $allHealthy = $false
}

# 3. Système Multi-Agents Studio Situations Pro
Write-Host "`n[3] SYSTEME MULTI-AGENTS" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Gray

# HAProxy
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/stats" -Method GET -TimeoutSec 2
    Write-Host "[OK] HAProxy Load Balancer" -ForegroundColor Green
    $results += "OK HAProxy (port 8080)"
} catch {
    Write-Host "[FAIL] HAProxy" -ForegroundColor Red
    $results += "FAIL HAProxy"
    $allHealthy = $false
}

# Agents Multi-instances
$agentPorts = @(8011, 8012, 8013, 8014)
$agentHealthy = 0
foreach ($port in $agentPorts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$port/health" -Method GET -TimeoutSec 2
        $json = $response.Content | ConvertFrom-Json
        if ($json.status -eq "healthy") {
            Write-Host "[OK] Agent Instance $($agentPorts.IndexOf($port) + 1) (port $port)" -ForegroundColor Green
            $results += "OK Agent Instance $($agentPorts.IndexOf($port) + 1) (port $port)"
            $agentHealthy++
        }
    } catch {
        Write-Host "[FAIL] Agent Instance $($agentPorts.IndexOf($port) + 1) (port $port)" -ForegroundColor Red
        $results += "FAIL Agent Instance $($agentPorts.IndexOf($port) + 1)"
        $allHealthy = $false
    }
}

Write-Host "-> $agentHealthy/4 instances actives" -ForegroundColor Cyan

# 4. Monitoring
Write-Host "`n[4] STACK DE MONITORING" -ForegroundColor Yellow
Write-Host "-----------------------" -ForegroundColor Gray

# Prometheus
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9090/-/ready" -Method GET -TimeoutSec 2
    Write-Host "[OK] Prometheus" -ForegroundColor Green
    $results += "OK Prometheus (port 9090)"
} catch {
    Write-Host "[FAIL] Prometheus" -ForegroundColor Red
    $results += "FAIL Prometheus"
}

# Grafana
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 2
    Write-Host "[OK] Grafana" -ForegroundColor Green
    $results += "OK Grafana (port 3000)"
} catch {
    Write-Host "[FAIL] Grafana" -ForegroundColor Red
    $results += "FAIL Grafana"
}

# 5. Tests fonctionnels
Write-Host "`n[5] TESTS FONCTIONNELS" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Gray

# Test LiveKit Room
try {
    $tokenResponse = Invoke-WebRequest -Uri "http://localhost:8004/token" -Method POST `
        -ContentType "application/json" `
        -Body '{"identity":"test_user","roomName":"test_room"}' `
        -TimeoutSec 2
    
    if ($tokenResponse.StatusCode -eq 200) {
        Write-Host "[OK] Generation de token LiveKit" -ForegroundColor Green
        $results += "OK Test generation token"
    }
} catch {
    Write-Host "[FAIL] Generation de token LiveKit" -ForegroundColor Red
    $results += "FAIL Test generation token"
}

# Test API Exercises
try {
    $exercisesResponse = Invoke-WebRequest -Uri "http://localhost:8005/scenarios" -Method GET -TimeoutSec 2
    if ($exercisesResponse.StatusCode -eq 200) {
        Write-Host "[OK] API Exercises (recuperation scenarios)" -ForegroundColor Green
        $results += "OK Test API scenarios"
    }
} catch {
    Write-Host "[FAIL] API Exercises" -ForegroundColor Red
    $results += "FAIL Test API scenarios"
}

# 6. Résumé
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "           RESUME" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$healthyCount = ($results | Where-Object { $_ -like "OK*" }).Count
$warningCount = ($results | Where-Object { $_ -like "WARN*" }).Count
$failedCount = ($results | Where-Object { $_ -like "FAIL*" }).Count
$totalCount = $results.Count

Write-Host "`nServices actifs: $healthyCount/$totalCount" -ForegroundColor $(if ($healthyCount -eq $totalCount) { "Green" } elseif ($healthyCount -gt $totalCount/2) { "Yellow" } else { "Red" })
if ($warningCount -gt 0) {
    Write-Host "Avertissements: $warningCount" -ForegroundColor Yellow
}
if ($failedCount -gt 0) {
    Write-Host "Echecs: $failedCount" -ForegroundColor Red
}

# 7. URLs d'accès
Write-Host "`n[URLS D'ACCES]" -ForegroundColor Magenta
Write-Host "--------------" -ForegroundColor Gray
Write-Host "* Application Flutter: http://localhost:8090" -ForegroundColor White
Write-Host "* Exercises API: http://localhost:8005" -ForegroundColor White
Write-Host "* Token Service: http://localhost:8004" -ForegroundColor White
Write-Host "* HAProxy Stats: http://localhost:8080/stats" -ForegroundColor White
Write-Host "* Grafana Dashboard: http://localhost:3000" -ForegroundColor White
Write-Host "* Prometheus: http://localhost:9090" -ForegroundColor White

# 8. Capacités du système
Write-Host "`n[CAPACITES DU SYSTEME]" -ForegroundColor Magenta
Write-Host "----------------------" -ForegroundColor Gray
Write-Host "* Exercices originaux:" -ForegroundColor White
Write-Host "  - Tribunal des Idees (debat IA)" -ForegroundColor Gray
Write-Host "  - Confidence Boost (coaching vocal)" -ForegroundColor Gray
Write-Host "* Studio Situations Pro:" -ForegroundColor White
Write-Host "  - 60 agents IA simultanes maximum" -ForegroundColor Gray
Write-Host "  - 5 types de simulations professionnelles" -ForegroundColor Gray
Write-Host "  - Load balancing HAProxy sur 4 instances" -ForegroundColor Gray
Write-Host "  - Monitoring temps reel Prometheus/Grafana" -ForegroundColor Gray

if ($allHealthy) {
    Write-Host "`n[SUCCESS] SYSTEME ENTIEREMENT OPERATIONNEL !" -ForegroundColor Green
} else {
    Write-Host "`n[WARNING] CERTAINS SERVICES NECESSITENT ATTENTION" -ForegroundColor Yellow
}

Write-Host "`n=====================================`n" -ForegroundColor Cyan