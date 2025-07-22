@echo off
echo ========================================
echo Fix Terminal VS Code - Solution Directe
echo ========================================

:: Créer le dossier de configuration s'il n'existe pas
if not exist "%APPDATA%\Code\User" mkdir "%APPDATA%\Code\User"

:: Sauvegarder les paramètres existants
if exist "%APPDATA%\Code\User\settings.json" (
    copy "%APPDATA%\Code\User\settings.json" "%APPDATA%\Code\User\settings.json.backup"
    echo Sauvegarde créée: settings.json.backup
)

:: Créer un fichier settings.json simple avec PowerShell comme terminal par défaut
echo { > "%APPDATA%\Code\User\settings.json"
echo   "terminal.integrated.profiles.windows": { >> "%APPDATA%\Code\User\settings.json"
echo     "PowerShell": { >> "%APPDATA%\Code\User\settings.json"
echo       "source": "PowerShell", >> "%APPDATA%\Code\User\settings.json"
echo       "args": [] >> "%APPDATA%\Code\User\settings.json"
echo     }, >> "%APPDATA%\Code\User\settings.json"
echo     "Command Prompt": { >> "%APPDATA%\Code\User\settings.json"
echo       "path": "C:\\Windows\\System32\\cmd.exe" >> "%APPDATA%\Code\User\settings.json"
echo     } >> "%APPDATA%\Code\User\settings.json"
echo   }, >> "%APPDATA%\Code\User\settings.json"
echo   "terminal.integrated.defaultProfile.windows": "PowerShell" >> "%APPDATA%\Code\User\settings.json"
echo } >> "%APPDATA%\Code\User\settings.json"

echo.
echo ✅ Configuration VS Code mise à jour avec PowerShell
echo 📁 Fichier: %APPDATA%\Code\User\settings.json
echo.
echo 🔧 Étapes suivantes:
echo 1. Redémarrez VS Code
echo 2. Testez le terminal avec Ctrl+`
echo.
pause
