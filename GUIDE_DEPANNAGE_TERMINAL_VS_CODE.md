# Guide de Dépannage - Terminal VS Code

## Problème Résolu
**Erreur**: "Arrêt du processus de terminal 'C:\Windows\System32\cmd.exe '/k', 'C:\Cmder\vendor\init.bat''. Code de sortie : 1."

## Cause
Le terminal VS Code est configuré pour utiliser Cmder (un terminal amélioré) mais Cmder n'est pas installé ou le chemin est incorrect.

## Solution Appliquée
✅ Configuration du terminal par défaut vers PowerShell

## Scripts de Réparation Créés

### 1. Script PowerShell (Recommandé)
```powershell
# Exécuter depuis le dossier Eloquence
powershell -ExecutionPolicy Bypass -Command "& { . .\scripts\fix_terminal_final.ps1 }"
```

### 2. Configuration Manuelle
Si le script automatique ne fonctionne pas, procédez ainsi :

#### Méthode 1: Via VS Code
1. Ouvrez VS Code
2. Appuyez sur `Ctrl+Shift+P`
3. Tapez: "Terminal: Select Default Profile"
4. Sélectionnez "PowerShell" ou "Command Prompt"

#### Méthode 2: Via les paramètres JSON
1. Appuyez sur `Ctrl+Shift+P`
2. Tapez: "Preferences: Open Settings (JSON)"
3. Remplacez ou ajoutez:
```json
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
```

## Vérification
1. Redémarrez VS Code
2. Ouvrez un nouveau terminal (`Ctrl+` ` ou `Ctrl+Shift+` `)
3. Le terminal devrait maintenant s'ouvrir avec PowerShell

## Installation de Cmder (Optionnel)
Si vous souhaitez utiliser Cmder:
1. Téléchargez depuis: https://cmder.net/
2. Installez dans `C:\Cmder`
3. Configurez VS Code pour utiliser Cmder:
```json
{
    "terminal.integrated.profiles.windows": {
        "Cmder": {
            "path": "C:\\Windows\\System32\\cmd.exe",
            "args": ["/k", "C:\\Cmder\\vendor\\init.bat"]
        }
    },
    "terminal.integrated.defaultProfile.windows": "Cmder"
}
```

## Fichiers de Réparation
- `scripts/fix_terminal_final.ps1` - Script PowerShell principal
- `scripts/fix_vscode_settings.json` - Configuration de référence
- `scripts/fix_vscode_terminal_default.bat` - Script batch alternatif

## Support
Si le problème persiste après ces étapes:
1. Vérifiez que PowerShell est bien installé
2. Essayez avec "Command Prompt" au lieu de PowerShell
3. Réinstallez VS Code si nécessaire
