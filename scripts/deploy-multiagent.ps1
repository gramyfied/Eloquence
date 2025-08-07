# Script de déploiement du système multi-agents Eloquence
# PowerShell script pour Windows

param(
    [Parameter(Mandatory=$false)]
    [string]$Mode = "dev",  # dev, staging, production
    
    [Parameter(Mandatory=$false)]
    [switch]$WithMonitoring = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunTests = $false
)

Write-Host "🚀 Déploiement du système multi-agents Eloquence" -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host "Monitoring: $WithMonitoring" -ForegroundColor Yellow
Write-Host "Tests: $RunTests" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

# Vérifier les prérequis
function Check-Prerequisites {
    Write-Host "`n📋 Vérification des prérequis..." -ForegroundColor Blue
    
    $missing = @()
    
    # Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missing += "Docker"
    }
    
    # Docker Compose
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        $missing += "Docker Compose"
    }
    
    # Python (pour les tests)
    if ($RunTests -and -not (Get-Command python -ErrorAction SilentlyContinue)) {
        $missing += "Python"
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "❌ Prérequis manquants: $($missing -join ', ')" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Tous les prérequis sont installés" -ForegroundColor Green
}

# Nettoyer l'environnement existant
function Clean-Environment {
    Write-Host "`n🧹 Nettoyage de l'environnement..." -ForegroundColor Blue
    
    # Arrêter les conteneurs existants
    docker-compose -f docker-compose.multiagent.yml down 2>$null
    
    # Nettoyer les volumes si en mode dev
    if ($Mode -eq "dev") {
        docker volume prune -f 2>$null
    }
    
    Write-Host "✅ Environnement nettoyé" -ForegroundColor Green
}

# Construire les images Docker
function Build-Images {
    Write-Host "`n🔨 Construction des images Docker..." -ForegroundColor Blue
    
    # Build de l'image multi-agents
    docker build -f services/livekit-agent/Dockerfile.multiagent -t eloquence/livekit-agent:multiagent ./services/livekit-agent
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de la construction de l'image" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Images construites avec succès" -ForegroundColor Green
}

# Démarrer les services
function Start-Services {
    Write-Host "`n🎯 Démarrage des services..." -ForegroundColor Blue
    
    $composeFile = "docker-compose.multiagent.yml"
    $envFile = ".env.$Mode"
    
    # Créer le fichier .env si nécessaire
    if (-not (Test-Path $envFile)) {
        Write-Host "Création du fichier $envFile..." -ForegroundColor Yellow
        @"
# Configuration $Mode
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
REDIS_URL=redis://redis:6379
OPENAI_API_KEY=$env:OPENAI_API_KEY
MISTRAL_API_KEY=$env:MISTRAL_API_KEY
LOG_LEVEL=INFO
MAX_WORKERS=4
MAX_AGENTS_PER_WORKER=10
"@ | Out-File -FilePath $envFile -Encoding UTF8
    }
    
    # Démarrer avec ou sans monitoring
    if ($WithMonitoring) {
        Write-Host "Démarrage avec monitoring..." -ForegroundColor Yellow
        docker-compose -f $composeFile --env-file $envFile up -d
    } else {
        Write-Host "Démarrage sans monitoring..." -ForegroundColor Yellow
        docker-compose -f $composeFile --env-file $envFile up -d livekit-server redis livekit-agent-1 livekit-agent-2 livekit-agent-3 livekit-agent-4 haproxy
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du démarrage des services" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Services démarrés" -ForegroundColor Green
}

# Vérifier la santé des services
function Check-Health {
    Write-Host "`n🏥 Vérification de la santé des services..." -ForegroundColor Blue
    
    Start-Sleep -Seconds 10  # Attendre que les services démarrent
    
    $services = @(
        @{Name="HAProxy"; Url="http://localhost:8080/health"},
        @{Name="LiveKit Server"; Url="http://localhost:7880/health"},
        @{Name="Prometheus"; Url="http://localhost:9090/-/healthy"},
        @{Name="Grafana"; Url="http://localhost:3000/api/health"}
    )
    
    $allHealthy = $true
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5 2>$null
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $($service.Name): OK" -ForegroundColor Green
            } else {
                Write-Host "⚠️ $($service.Name): Status $($response.StatusCode)" -ForegroundColor Yellow
                $allHealthy = $false
            }
        } catch {
            if ($WithMonitoring -or $service.Name -in @("HAProxy", "LiveKit Server")) {
                Write-Host "❌ $($service.Name): Non disponible" -ForegroundColor Red
                $allHealthy = $false
            }
        }
    }
    
    if (-not $allHealthy) {
        Write-Host "`n⚠️ Certains services ne sont pas complètement opérationnels" -ForegroundColor Yellow
        Write-Host "Vérifiez les logs avec: docker-compose -f docker-compose.multiagent.yml logs" -ForegroundColor Yellow
    } else {
        Write-Host "`n✅ Tous les services sont opérationnels" -ForegroundColor Green
    }
    
    return $allHealthy
}

# Exécuter les tests de charge
function Run-LoadTests {
    Write-Host "`n🧪 Exécution des tests de charge..." -ForegroundColor Blue
    
    # Installer les dépendances Python si nécessaire
    if (-not (Test-Path "tests/load_testing/.venv")) {
        Write-Host "Installation des dépendances Python..." -ForegroundColor Yellow
        python -m venv tests/load_testing/.venv
        & tests/load_testing/.venv/Scripts/Activate.ps1
        pip install aiohttp websockets
    } else {
        & tests/load_testing/.venv/Scripts/Activate.ps1
    }
    
    # Exécuter les tests
    python tests/load_testing/multiagent_load_test.py
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Les tests de charge ont échoué" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Tests de charge réussis" -ForegroundColor Green
    return $true
}

# Afficher les URLs d'accès
function Show-AccessUrls {
    Write-Host "`n📌 URLs d'accès:" -ForegroundColor Blue
    Write-Host "  - Application: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "  - LiveKit Server: http://localhost:7880" -ForegroundColor Cyan
    
    if ($WithMonitoring) {
        Write-Host "  - Prometheus: http://localhost:9090" -ForegroundColor Cyan
        Write-Host "  - Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor Cyan
        Write-Host "  - HAProxy Stats: http://localhost:8404/stats" -ForegroundColor Cyan
    }
    
    Write-Host "`n📝 Commandes utiles:" -ForegroundColor Blue
    Write-Host "  - Logs: docker-compose -f docker-compose.multiagent.yml logs -f" -ForegroundColor Gray
    Write-Host "  - Arrêt: docker-compose -f docker-compose.multiagent.yml down" -ForegroundColor Gray
    Write-Host "  - Restart: docker-compose -f docker-compose.multiagent.yml restart" -ForegroundColor Gray
}

# Fonction principale
function Main {
    $startTime = Get-Date
    
    Check-Prerequisites
    Clean-Environment
    Build-Images
    Start-Services
    
    $healthy = Check-Health
    
    if ($RunTests -and $healthy) {
        $testsPassed = Run-LoadTests
        if (-not $testsPassed) {
            Write-Host "`n⚠️ Déploiement réussi mais tests échoués" -ForegroundColor Yellow
        }
    }
    
    Show-AccessUrls
    
    $duration = (Get-Date) - $startTime
    Write-Host "`n⏱️ Déploiement terminé en $($duration.TotalSeconds) secondes" -ForegroundColor Green
    
    if ($healthy) {
        Write-Host "🎉 Système multi-agents opérationnel!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Déploiement partiel - vérifiez les services défaillants" -ForegroundColor Yellow
    }
}

# Exécuter le script
Main