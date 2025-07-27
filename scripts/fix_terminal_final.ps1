# Script de réparation pour le terminal VS Code
Write-Host "Réparation du terminal VS Code en cours..."

# Chemin vers les paramètres VS Code
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Créer le dossier s'il n'existe pas
$settingsDir = Split-Path $settingsPath -Parent
if (!(Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

# Sauvegarder les paramètres existants
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.backup" -Force
    Write-Host "Paramètres sauvegardés"
}

# Créer les paramètres de base
$settings = @{
    "terminal.integrated.profiles.windows" = @{
        "PowerShell" = @{
            "source" = "PowerShell"
            "args" = @()
        }
        "Command Prompt" = @{
            "path" = "C:\Windows\System32\cmd.exe"
        }
    }
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
}

# Convertir en JSON et sauvegarder
$settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8 -Force

Write-Host "Terminal configuré avec PowerShell comme défaut"
Write-Host "Redémarrez VS Code pour appliquer les changements"
