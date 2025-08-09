# Script de démarrage des services Eloquence modernes
# Utilise les dernières versions et configurations optimisées

param(
    [switch]$Force,
    [switch]$Clean,
    [switch]$Monitor,
    [string]$ConfigFile = "docker-compose.modern.yml"
)

# Configuration des couleurs
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

# Vérification de Docker
function Test-DockerAvailability {
    Write-ColorOutput "🔍 Vérification de Docker..." "Info"
    
    try {
        $dockerVersion = docker --version
        Write-ColorOutput "   ✅ Docker disponible: $dockerVersion" "Success"
        
        $dockerComposeVersion = docker-compose --version
        Write-ColorOutput "   ✅ Docker Compose disponible: $dockerComposeVersion" "Success"
        
        return $true
    }
    catch {
        Write-ColorOutput "   ❌ Docker non disponible" "Error"
        Write-Host "      Veuillez installer Docker Desktop et redémarrer" -ForegroundColor Red
        return $false
    }
}

# Vérification des fichiers de configuration
function Test-ConfigurationFiles {
    Write-ColorOutput "📋 Vérification des fichiers de configuration..." "Info"
    
    $requiredFiles = @(
        $ConfigFile,
        "livekit.modern.yaml",
        "services/livekit-server/Dockerfile",
        "services/eloquence-exercises-api/Dockerfile"
    )
    
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-ColorOutput "   ✅ $file" "Success"
        } else {
            Write-ColorOutput "   ❌ $file manquant" "Error"
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-ColorOutput "   ⚠️  Fichiers manquants détectés" "Warning"
        return $false
    }
    
    return $true
}

# Nettoyage des services existants
function Stop-ExistingServices {
    Write-ColorOutput "🧹 Arrêt des services existants..." "Info"
    
    try {
        # Arrêt des services existants
        docker-compose down --remove-orphans
        Write-ColorOutput "   ✅ Services existants arrêtés" "Success"
        
        if ($Clean) {
            Write-ColorOutput "   🗑️  Nettoyage des volumes et images..." "Info"
            docker system prune -f
            docker volume prune -f
            Write-ColorOutput "   ✅ Nettoyage terminé" "Success"
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "   ⚠️  Erreur lors de l'arrêt des services" "Warning"
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Yellow
        return $true # Continue malgré l'erreur
    }
}

# Démarrage des services modernes
function Start-ModernServices {
    Write-ColorOutput "🚀 Démarrage des services modernes..." "Info"
    
    try {
        # Construction et démarrage des services
        Write-ColorOutput "   🔨 Construction des images..." "Info"
        docker-compose -f $ConfigFile build --no-cache
        
        Write-ColorOutput "   🚀 Démarrage des services..." "Info"
        docker-compose -f $ConfigFile up -d
        
        Write-ColorOutput "   ✅ Services démarrés avec succès" "Success"
        return $true
    }
    catch {
        Write-ColorOutput "   ❌ Erreur lors du démarrage des services" "Error"
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Vérification de la santé des services
function Test-ServicesHealth {
    Write-ColorOutput "🏥 Vérification de la santé des services..." "Info"
    
    $services = @(
        @{Name="Redis"; Port=6379},
        @{Name="LiveKit Server"; Port=7880},
        @{Name="Token Service"; Port=8004},
        @{Name="Exercises API"; Port=8005},
        @{Name="Mistral Conversation"; Port=8001},
        @{Name="Vosk STT"; Port=8002},
        @{Name="HAProxy"; Port=8080}
    )
    
    $healthyServices = 0
    $totalServices = $services.Count
    
    foreach ($service in $services) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect("localhost", $service.Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                Write-ColorOutput "   ✅ $($service.Name) (Port $($service.Port))" "Success"
                $healthyServices++
                $tcpClient.Close()
            } else {
                Write-ColorOutput "   ❌ $($service.Name) (Port $($service.Port))" "Error"
            }
        }
        catch {
            Write-ColorOutput "   ❌ $($service.Name) (Port $($service.Port))" "Error"
        }
    }
    
    Write-Host ""
    Write-ColorOutput "📊 Résumé de la santé des services:" "Header"
    Write-ColorOutput "   Services sains: $healthyServices/$totalServices" "Info"
    
    if ($healthyServices -eq $totalServices) {
        Write-ColorOutput "   🎉 Tous les services sont opérationnels !" "Success"
        return $true
    } elseif ($healthyServices -gt ($totalServices / 2)) {
        Write-ColorOutput "   ⚠️  La plupart des services fonctionnent" "Warning"
        return $true
    } else {
        Write-ColorOutput "   🚨 Problèmes majeurs détectés" "Error"
        return $false
    }
}

# Affichage des informations de connexion
function Show-ConnectionInfo {
    Write-ColorOutput "🔗 Informations de connexion:" "Header"
    Write-Host ""
    
    Write-ColorOutput "Services principaux:" "Info"
    Write-Host "   • LiveKit Server: ws://localhost:7880" -ForegroundColor Gray
    Write-Host "   • Token Service: http://localhost:8004" -ForegroundColor Gray
    Write-Host "   • Exercises API: http://localhost:8005" -ForegroundColor Gray
    Write-Host "   • Mistral Conversation: http://localhost:8001" -ForegroundColor Gray
    Write-Host "   • Vosk STT: http://localhost:8002" -ForegroundColor Gray
    Write-Host "   • HAProxy: http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorOutput "Agents LiveKit:" "Info"
    Write-Host "   • Agent 1: http://localhost:8011" -ForegroundColor Gray
    Write-Host "   • Agent 2: http://localhost:8012" -ForegroundColor Gray
    Write-Host "   • Agent 3: http://localhost:8013" -ForegroundColor Gray
    Write-Host "   • Agent 4: http://localhost:8014" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorOutput "Monitoring:" "Info"
    Write-Host "   • Prometheus: http://localhost:9090" -ForegroundColor Gray
    Write-Host "   • Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorOutput "Configuration Flutter:" "Info"
    Write-Host "   • Mettez à jour network_config.dart avec votre IP réseau" -ForegroundColor Gray
    Write-Host "   • Utilisez 'ipconfig' pour vérifier votre IP" -ForegroundColor Gray
}

# Surveillance continue des services
function Start-ServiceMonitoring {
    Write-ColorOutput "📊 Démarrage de la surveillance des services..." "Info"
    Write-Host "   Appuyez sur Ctrl+C pour arrêter la surveillance" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        Clear-Host
        Write-ColorOutput "📊 État des services Eloquence - $(Get-Date)" "Header"
        Write-Host ""
        
        docker-compose -f $ConfigFile ps
        
        Write-Host ""
        Write-ColorOutput "Logs en temps réel (dernières 10 lignes):" "Info"
        docker-compose -f $ConfigFile logs --tail=10
        
        Start-Sleep -Seconds 10
    }
}

# Fonction principale
function Main {
    Write-ColorOutput "🚀 Démarrage des services Eloquence modernes" "Header"
    Write-Host "Configuration: $ConfigFile" -ForegroundColor Gray
    Write-Host "Force: $Force, Clean: $Clean, Monitor: $Monitor" -ForegroundColor Gray
    Write-Host ""
    
    # Vérifications préliminaires
    if (-not (Test-DockerAvailability)) {
        exit 1
    }
    
    if (-not (Test-ConfigurationFiles)) {
        Write-ColorOutput "❌ Configuration incomplète, arrêt du script" "Error"
        exit 1
    }
    
    # Arrêt des services existants
    if (-not (Stop-ExistingServices)) {
        Write-ColorOutput "❌ Impossible d'arrêter les services existants" "Error"
        exit 1
    }
    
    # Démarrage des services modernes
    if (-not (Start-ModernServices)) {
        Write-ColorOutput "❌ Échec du démarrage des services" "Error"
        exit 1
    }
    
    # Attente du démarrage
    Write-ColorOutput "⏳ Attente du démarrage des services..." "Info"
    Start-Sleep -Seconds 30
    
    # Vérification de la santé
    if (-not (Test-ServicesHealth)) {
        Write-ColorOutput "⚠️  Problèmes détectés, vérifiez les logs" "Warning"
    }
    
    # Affichage des informations de connexion
    Write-Host ""
    Show-ConnectionInfo
    
    # Surveillance si demandée
    if ($Monitor) {
        Write-Host ""
        Start-ServiceMonitoring
    }
    
    Write-ColorOutput "✅ Script de démarrage terminé" "Success"
}

# Exécution du script principal
try {
    Main
}
catch {
    Write-ColorOutput "❌ Erreur fatale: $($_.Exception.Message)" "Error"
    exit 1
}
