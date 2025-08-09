# Script de diagnostic moderne pour Eloquence
# Vérifie la connectivité de tous les services avec retry et fallback

param(
    [string]$BaseUrl = "localhost",
    [int]$Timeout = 10,
    [int]$MaxRetries = 3
)

# Configuration des couleurs pour une meilleure lisibilité
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Header = "Magenta"
}

# Fonction pour afficher des messages colorés
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

# Fonction pour tester la connectivité avec retry
function Test-ServiceConnectivity {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxRetries = 3
    )
    
    Write-ColorOutput "🔍 Test de connectivité: $ServiceName" "Info"
    Write-Host "   URL: $Url" -ForegroundColor Gray
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec $Timeout -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-ColorOutput "   ✅ $ServiceName - Connecté (Tentative $i/$MaxRetries)" "Success"
                return $true
            }
        }
        catch {
            if ($i -eq $MaxRetries) {
                Write-ColorOutput "   ❌ $ServiceName - Échec après $MaxRetries tentatives" "Error"
                Write-Host "      Erreur: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            } else {
                Write-Host "   ⚠️  Tentative $i/$MaxRetries échouée, nouvelle tentative..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    return $false
}

# Fonction pour tester la génération de tokens
function Test-TokenGeneration {
    param(
        [string]$BaseUrl
    )
    
    Write-ColorOutput "🎫 Test de génération de tokens" "Info"
    $tokenUrl = "http://$BaseUrl`:8004/token"
    
    try {
        $body = @{
            room = "test-room-connectivity"
            identity = "test-user-connectivity"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri $tokenUrl -Method POST -Body $body -ContentType "application/json" -TimeoutSec $Timeout -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            $tokenData = $response.Content | ConvertFrom-Json
            if ($tokenData.token) {
                Write-ColorOutput "   ✅ Génération de token réussie" "Success"
                Write-Host "      Token: $($tokenData.token.Substring(0, 50))..." -ForegroundColor Gray
                return $true
            }
        }
    }
    catch {
        Write-ColorOutput "   ❌ Échec de génération de token" "Error"
        Write-Host "      Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $false
}

# Fonction pour tester la connectivité WebSocket LiveKit
function Test-LiveKitWebSocket {
    param(
        [string]$BaseUrl
    )
    
    Write-ColorOutput "🔌 Test de connectivité WebSocket LiveKit" "Info"
    $wsUrl = "ws://$BaseUrl`:7880"
    
    try {
        # Test simple de connectivité HTTP d'abord
        $httpUrl = "http://$BaseUrl`:7880"
        $response = Invoke-WebRequest -Uri $httpUrl -Method GET -TimeoutSec $Timeout -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-ColorOutput "   ✅ Serveur LiveKit accessible via HTTP" "Success"
            Write-ColorOutput "   ℹ️  WebSocket devrait fonctionner sur $wsUrl" "Info"
            return $true
        }
    }
    catch {
        Write-ColorOutput "   ❌ Serveur LiveKit inaccessible" "Error"
        Write-Host "      Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $false
}

# Fonction pour vérifier les ports ouverts
function Test-PortConnectivity {
    param(
        [string]$Host = "localhost",
        [int[]]$Ports = @(7880, 8004, 8005, 8001, 8002, 8080)
    )
    
    Write-ColorOutput "🔌 Test de connectivité des ports" "Info"
    
    foreach ($port in $Ports) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($Host, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne($Timeout * 1000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                Write-ColorOutput "   ✅ Port $port - Ouvert" "Success"
                $tcpClient.Close()
            } else {
                Write-ColorOutput "   ❌ Port $port - Fermé ou bloqué" "Error"
            }
        }
        catch {
            Write-ColorOutput "   ❌ Port $port - Erreur de connexion" "Error"
        }
    }
}

# Fonction pour afficher le résumé
function Show-ConnectivitySummary {
    param(
        [hashtable]$Results
    )
    
    Write-ColorOutput "📊 Résumé de la connectivité" "Header"
    Write-Host ""
    
    $totalServices = $Results.Count
    $connectedServices = ($Results.Values | Where-Object { $_ -eq $true }).Count
    
    Write-ColorOutput "Services testés: $totalServices" "Info"
    Write-ColorOutput "Services connectés: $connectedServices" "Success"
    Write-ColorOutput "Services défaillants: $($totalServices - $connectedServices)" "Error"
    
    if ($connectedServices -eq $totalServices) {
        Write-ColorOutput "🎉 Tous les services sont opérationnels !" "Success"
    } elseif ($connectedServices -gt ($totalServices / 2)) {
        Write-ColorOutput "⚠️  La plupart des services fonctionnent, quelques problèmes détectés" "Warning"
    } else {
        Write-ColorOutput "🚨 Problèmes majeurs de connectivité détectés" "Error"
    }
}

# Configuration des services à tester
$Services = @{
    "LiveKit Server" = "http://$BaseUrl`:7880"
    "Token Service" = "http://$BaseUrl`:8004/health"
    "Exercises API" = "http://$BaseUrl`:8005/health"
    "Mistral Conversation" = "http://$BaseUrl`:8001/health"
    "Vosk STT" = "http://$BaseUrl`:8002/health"
    "HAProxy" = "http://$BaseUrl`:8080/stats"
}

# Début du diagnostic
Write-ColorOutput "🚀 Diagnostic de connectivité Eloquence - Version Moderne" "Header"
Write-Host "Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "Timeout: ${Timeout}s, Max Retries: $MaxRetries" -ForegroundColor Gray
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Test de connectivité des services
$Results = @{}
foreach ($service in $Services.GetEnumerator()) {
    $Results[$service.Key] = Test-ServiceConnectivity -ServiceName $service.Key -Url $service.Value -MaxRetries $MaxRetries
    Write-Host ""
}

# Test spécial de génération de tokens
Write-Host ""
$tokenResult = Test-TokenGeneration -BaseUrl $BaseUrl
$Results["Token Generation"] = $tokenResult

# Test de connectivité WebSocket
Write-Host ""
$wsResult = Test-LiveKitWebSocket -BaseUrl $BaseUrl
$Results["LiveKit WebSocket"] = $wsResult

# Test des ports
Write-Host ""
Test-PortConnectivity -Host $BaseUrl

# Affichage du résumé
Write-Host ""
Show-ConnectivitySummary -Results $Results

# Recommandations
Write-Host ""
Write-ColorOutput "💡 Recommandations" "Header"

if ($Results["Token Service"] -eq $false) {
    Write-ColorOutput "   • Vérifiez que le service livekit-token-service est démarré" "Warning"
    Write-ColorOutput "   • Vérifiez les logs: docker logs eloquence-livekit-token-service-1" "Warning"
}

if ($Results["LiveKit Server"] -eq $false) {
    Write-ColorOutput "   • Vérifiez que le serveur LiveKit est démarré" "Warning"
    Write-ColorOutput "   • Vérifiez la configuration livekit.yaml" "Warning"
}

if ($tokenResult -eq $false) {
    Write-ColorOutput "   • Problème de génération de tokens - vérifiez les clés API" "Warning"
}

Write-ColorOutput "   • Utilisez 'docker-compose -f docker-compose.modern.yml up -d' pour démarrer les services modernes" "Info"
Write-ColorOutput "   • Vérifiez votre IP réseau avec 'ipconfig'" "Info"

Write-Host ""
Write-ColorOutput "✅ Diagnostic terminé" "Success"
