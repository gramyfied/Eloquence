# Script d'Optimisation VS Code - Roocode Agent IA
# Date: 2025-07-28
# Objectif: Optimiser VS Code pour les performances et la stabilite

Write-Host "Demarrage de l'optimisation VS Code..." -ForegroundColor Green

# Fonction pour mesurer la performance actuelle
function Get-VSCodePerformance {
    Write-Host "Mesure des performances VS Code..." -ForegroundColor Yellow
    
    $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcesses) {
        $totalCPU = ($vscodeProcesses | Measure-Object CPU -Sum).Sum
        $totalMemory = ($vscodeProcesses | Measure-Object WorkingSet -Sum).Sum / 1MB
        
        Write-Host "CPU Total: $([math]::Round($totalCPU, 2))%" -ForegroundColor Cyan
        Write-Host "RAM Totale: $([math]::Round($totalMemory, 0)) MB" -ForegroundColor Cyan
        
        return @{
            CPU = $totalCPU
            Memory = $totalMemory
            ProcessCount = $vscodeProcesses.Count
        }
    }
    return $null
}

# Mesure initiale
$initialPerf = Get-VSCodePerformance

# Extensions a desactiver automatiquement
$extensionsToDisable = @(
    "ms-vscode-remote.remote-ssh",
    "ms-vscode-remote.remote-repositories", 
    "ms-vscode.azure-repos",
    "ms-vscode.cmake-tools",
    "ms-vsliveshare.vsliveshare",
    "batisteo.vscode-django",
    "docker.docker",
    "ms-azuretools.vscode-containers",
    "ms-azuretools.vscode-docker",
    "ms-dotnettools.vscode-dotnet-runtime",
    "ms-python.debugpy",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.vscode-python-envs",
    "njpwerner.autodocstring",
    "pmneo.tsimporter",
    "timonwong.shellcheck",
    "vscjava.vscode-gradle"
)

Write-Host "Desactivation des extensions non-essentielles..." -ForegroundColor Yellow

foreach ($extension in $extensionsToDisable) {
    Write-Host "   Desactivation: $extension" -ForegroundColor Gray
    & code --disable-extension $extension 2>$null
}

Write-Host "Extensions desactivees" -ForegroundColor Green

# Optimisation des parametres VS Code
Write-Host "Configuration des parametres optimises..." -ForegroundColor Yellow

$settingsPath = "$env:APPDATA\Code\User\settings.json"
$optimizedSettings = @{
    "editor.hover.enabled" = $false
    "editor.minimap.enabled" = $false
    "editor.suggest.preview" = $false
    "files.watcherExclude" = @{
        "**/.git/objects/**" = $true
        "**/node_modules/**" = $true
        "**/.dart_tool/**" = $true
        "**/build/**" = $true
        "**/.vscode/**" = $true
    }
    "search.exclude" = @{
        "**/node_modules" = $true
        "**/bower_components" = $true
        "**/.dart_tool" = $true
        "**/build" = $true
    }
    "files.exclude" = @{
        "**/.dart_tool" = $true
        "**/build" = $true
    }
    "extensions.autoUpdate" = $false
    "telemetry.telemetryLevel" = "off"
    "workbench.enableExperiments" = $false
    "workbench.settings.enableNaturalLanguageSearch" = $false
    "terminal.integrated.gpuAcceleration" = "off"
    "editor.semanticHighlighting.enabled" = $false
}

if (Test-Path $settingsPath) {
    $currentSettings = Get-Content $settingsPath | ConvertFrom-Json -AsHashtable
} else {
    $currentSettings = @{}
}

# Fusion des parametres
foreach ($key in $optimizedSettings.Keys) {
    $currentSettings[$key] = $optimizedSettings[$key]
}

$currentSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

Write-Host "Parametres optimises appliques" -ForegroundColor Green

# Nettoyage des fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Yellow

$tempPaths = @(
    "$env:APPDATA\Code\User\workspaceStorage",
    "$env:APPDATA\Code\CachedExtensions", 
    "$env:APPDATA\Code\logs"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path -Recurse | Where-Object LastWriteTime -lt (Get-Date).AddDays(-7) | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "   Nettoye: $path" -ForegroundColor Gray
    }
}

Write-Host "Nettoyage termine" -ForegroundColor Green

Write-Host "`nOptimisation terminee!" -ForegroundColor Green
Write-Host "   Redemarrez VS Code pour appliquer tous les changements." -ForegroundColor Yellow

# Rapport final
if ($initialPerf) {
    Write-Host "`nPerformance initiale:" -ForegroundColor Cyan
    Write-Host "   CPU: $([math]::Round($initialPerf.CPU, 2))%" -ForegroundColor White
    Write-Host "   RAM: $([math]::Round($initialPerf.Memory, 0)) MB" -ForegroundColor White
    Write-Host "   Processus: $($initialPerf.ProcessCount)" -ForegroundColor White
    
    Write-Host "`nAttendez le redemarrage pour mesurer l'amelioration..." -ForegroundColor Yellow
}

Write-Host "`nExecutez 'code --status' apres redemarrage pour valider." -ForegroundColor Magenta