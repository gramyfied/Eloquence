# Script de réparation simple pour le terminal VS Code
Write-Host "========================================" -ForegroundColor Green
Write-Host "Réparation du terminal VS Code" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

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
    Write-Host "✓ Paramètres sauvegardés dans $settingsPath.backup" -ForegroundColor Yellow
}

# Créer de nouveaux paramètres avec PowerShell comme terminal par défaut
$newSettings = @"
{
    "terminal.integrated.profiles.windows": {
        "PowerShell": {
            "source": "PowerShell",
            "args": []
        },
        "Command Prompt": {
            "path": "C:\\Windows\\System32\\cmd.exe"
        }
    },
    "terminal.integrated.defaultProfile.windows": "PowerShell"
}
"@

# Écrire les nouveaux paramètres
$newSettings | Out-File -FilePath $settingsPath -Encoding UTF8 -Force
Write-Host "✓ Paramètres VS Code mis à jour avec PowerShell comme terminal par défaut" -ForegroundColor Green

Write-Host ""
Write-Host "Solutions rapides:" -ForegroundColor Cyan
Write-Host "1. Redémarrez VS Code" -ForegroundColor White
Write-Host "2. Ou utilisez Ctrl+Shift+P → 'Terminal: Select Default Profile'" -ForegroundColor White
Write-Host "3. Sélectionnez 'PowerShell' ou 'Command Prompt'" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Réparation terminée!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
