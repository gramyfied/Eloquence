# Script PowerShell de test des ports de connexion pour Confidence Boost
# Vérifie la connectivité de tous les services LiveKit nécessaires

param(
    [string]$HostIP = "192.168.1.44"
)

function Test-PortConnectivity {
    param(
        [string]$HostName,
        [int]$Port,
        [string]$ServiceName
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-Host "✅ $ServiceName ($Host`:$Port) - CONNECTÉ" -ForegroundColor Green
            return $true
        } else {
            $tcpClient.Close()
            Write-Host "❌ $ServiceName ($Host`:$Port) - DÉCONNECTÉ (timeout)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ $ServiceName ($Host`:$Port) - ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-HttpEndpoint {
    param(
        [string]$Url,
        [string]$ServiceName
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $ServiceName ($Url) - HTTP 200 OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️ $ServiceName ($Url) - HTTP $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        if ($_.Exception.Message -like "*Connection refused*" -or $_.Exception.Message -like "*Unable to connect*") {
            Write-Host "❌ $ServiceName ($Url) - CONNEXION REFUSÉE" -ForegroundColor Red
        } else {
            Write-Host "❌ $ServiceName ($Url) - ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

function Test-LiveKitTokenGeneration {
    param(
        [string]$HostName,
        [int]$Port
    )
    
    try {
        $healthUrl = "http://$Host`:$Port/health"
        $response = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Service LiveKit Token ($Host`:$Port) - HEALTH CHECK OK" -ForegroundColor Green
            
            # Test de génération de token
            $tokenUrl = "http://$Host`:$Port/generate-token"
            $tokenPayload = @{
                room_name = "test_confidence_boost"
                participant_name = "test_user"
                grants = @{
                    roomJoin = $true
                    canPublish = $true
                    canSubscribe = $true
                    canPublishData = $true
                }
                metadata = @{
                    exercise_type = "confidence_boost"
                    scenario_id = "test_scenario"
                }
            }
            
            $jsonPayload = $tokenPayload | ConvertTo-Json -Depth 3
            $tokenResponse = Invoke-WebRequest -Uri $tokenUrl -Method POST -Body $jsonPayload -ContentType "application/json" -TimeoutSec 15 -ErrorAction Stop
            
            if ($tokenResponse.StatusCode -eq 200) {
                $tokenData = $tokenResponse.Content | ConvertFrom-Json
                Write-Host "✅ Génération de token réussie - Room: $($tokenData.room_name)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Échec génération token - HTTP $($tokenResponse.StatusCode): $($tokenResponse.Content)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "⚠️ Service LiveKit Token ($Host`:$Port) - HEALTH CHECK ÉCHEC: HTTP $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
        
    } catch {
        Write-Host "❌ Service LiveKit Token ($Host`:$Port) - ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main script
Write-Host "🔍 TEST DES PORTS DE CONNEXION - CONFIDENCE BOOST" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "⏰ Début du test: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# Configuration des services à tester
$localhost = "localhost"

$servicesToTest = @(
    @{Host = $HostIP; Port = 7880; ServiceName = "LiveKit WebSocket (7880)"},
    @{Host = $HostIP; Port = 7881; ServiceName = "LiveKit TCP (7881)"},
    @{Host = $HostIP; Port = 8004; ServiceName = "LiveKit Token API (8004)"},
    @{Host = $HostIP; Port = 8005; ServiceName = "Eloquence Exercises API (8005)"},
    @{Host = $HostIP; Port = 8001; ServiceName = "Mistral Conversation (8001)"},
    @{Host = $HostIP; Port = 8002; ServiceName = "Vosk STT (8002)"},
    @{Host = $HostIP; Port = 6379; ServiceName = "Redis (6379)"},
    @{Host = $localhost; Port = 7880; ServiceName = "LiveKit WebSocket localhost (7880)"},
    @{Host = $localhost; Port = 8004; ServiceName = "LiveKit Token API localhost (8004)"}
)

Write-Host "📡 TEST DE CONNECTIVITÉ DES PORTS:" -ForegroundColor Yellow
Write-Host "-" * 40 -ForegroundColor Yellow

$portResults = @{}
foreach ($service in $servicesToTest) {
    $result = Test-PortConnectivity -Host $service.Host -Port $service.Port -ServiceName $service.ServiceName
    $portResults["$($service.Host):$($service.Port)"] = $result
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "🌐 TEST DES ENDPOINTS HTTP:" -ForegroundColor Yellow
Write-Host "-" * 40 -ForegroundColor Yellow

$httpEndpoints = @(
    @{Url = "http://$HostIP`:8004/health"; ServiceName = "LiveKit Token Service Health"},
    @{Url = "http://$HostIP`:8005/health"; ServiceName = "Eloquence Exercises API Health"},
    @{Url = "http://$HostIP`:8001/health"; ServiceName = "Mistral Conversation Health"},
    @{Url = "http://$HostIP`:8002/health"; ServiceName = "Vosk STT Health"}
)

$httpResults = @{}
foreach ($endpoint in $httpEndpoints) {
    $result = Test-HttpEndpoint -Url $endpoint.Url -ServiceName $endpoint.ServiceName
    $httpResults[$endpoint.Url] = $result
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "🎯 TEST SPÉCIAL - GÉNÉRATION DE TOKEN LIVEKIT:" -ForegroundColor Yellow
Write-Host "-" * 40 -ForegroundColor Yellow

$tokenResult = Test-LiveKitTokenGeneration -Host $HostIP -Port 8004

Write-Host ""
Write-Host "📊 RÉSUMÉ DES TESTS:" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Résumé des ports
$connectedPorts = ($portResults.Values | Where-Object { $_ -eq $true }).Count
$totalPorts = $portResults.Count
Write-Host "🔌 Ports connectés: $connectedPorts/$totalPorts" -ForegroundColor White

# Résumé HTTP
$workingHttp = ($httpResults.Values | Where-Object { $_ -eq $true }).Count
$totalHttp = $httpEndpoints.Count
Write-Host "🌐 Endpoints HTTP: $workingHttp/$totalHttp" -ForegroundColor White

# Résumé token
$tokenStatus = if ($tokenResult) { "✅ OK" } else { "❌ ÉCHEC" }
Write-Host "🎫 Génération token: $tokenStatus" -ForegroundColor White

Write-Host ""
Write-Host "🚨 PROBLÈMES IDENTIFIÉS:" -ForegroundColor Red
Write-Host "-" * 40 -ForegroundColor Red

if (-not $portResults["$HostIP`:8004"]) {
    Write-Host "❌ PORT 8004 BLOQUÉ: Le service de génération de tokens LiveKit n'est pas accessible" -ForegroundColor Red
    Write-Host "   → Vérifiez que le port 8004 est exposé dans docker-compose.yml" -ForegroundColor Yellow
    Write-Host "   → Redémarrez les services Docker" -ForegroundColor Yellow
}

if (-not $portResults["$HostIP`:7880"]) {
    Write-Host "❌ PORT 7880 BLOQUÉ: Le serveur LiveKit WebSocket n'est pas accessible" -ForegroundColor Red
    Write-Host "   → Vérifiez que le service livekit-server est démarré" -ForegroundColor Yellow
}

if (-not $tokenResult) {
    Write-Host "❌ GÉNÉRATION DE TOKEN: Impossible de générer un token LiveKit" -ForegroundColor Red
    Write-Host "   → Vérifiez la configuration des clés API LiveKit" -ForegroundColor Yellow
    Write-Host "   → Vérifiez les logs du service livekit-server" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 SOLUTIONS RECOMMANDÉES:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Green

if (-not $portResults["$HostIP`:8004"]) {
    Write-Host "1. Ajouter le port 8004 dans docker-compose.yml:" -ForegroundColor White
    Write-Host "   ports:" -ForegroundColor Gray
    Write-Host "     - '8004:8004'  # Port API de génération de tokens" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Redémarrer les services:" -ForegroundColor White
    Write-Host "   docker-compose down && docker-compose up -d" -ForegroundColor Gray
}

if (-not $portResults["$HostIP`:7880"]) {
    Write-Host "3. Vérifier que le service livekit-server est démarré:" -ForegroundColor White
    Write-Host "   docker-compose ps livekit-server" -ForegroundColor Gray
    Write-Host "   docker-compose logs livekit-server" -ForegroundColor Gray
}

Write-Host ""
Write-Host "⏰ Fin du test: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
