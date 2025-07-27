@echo off
echo ========================================
echo Réparation du terminal VS Code
echo ========================================
echo.

echo 1. Configuration du terminal par défaut de Windows...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DontUsePowerShellOnWinX /t REG_DWORD /d 0 /f >nul 2>&1

echo 2. Réinitialisation des paramètres VS Code...
if exist "%APPDATA%\Code\User\settings.json" (
    echo Sauvegarde des paramètres actuels...
    copy "%APPDATA%\Code\User\settings.json" "%APPDATA%\Code\User\settings.json.backup" >nul 2>&1
    
    echo Configuration du terminal par défaut...
    powershell -Command ^
    "$settings = Get-Content '%APPDATA%\Code\User\settings.json' -Raw | ConvertFrom-Json; ^
    if ($settings.PSObject.Properties.Name -contains 'terminal.integrated.profiles.windows') { ^
        $settings.'terminal.integrated.profiles.windows'.Remove('Cmder'); ^
    } ^
    $settings | ConvertTo-Json -Depth 10 | Set-Content '%APPDATA%\Code\User\settings.json'"
)

echo 3. Vérification de l'installation de Cmder...
if exist "C:\Cmder\vendor\init.bat" (
    echo Cmder trouvé à C:\Cmder
) else if exist "%USERPROFILE%\Cmder\vendor\init.bat" (
    echo Cmder trouvé à %USERPROFILE%\Cmder
) else (
    echo Cmder non trouvé. Installation recommandée depuis: https://cmder.net/
)

echo.
echo Solutions disponibles:
echo A. Utiliser PowerShell comme terminal par défaut
echo B. Utiliser CMD comme terminal par défaut
echo C. Réinstaller Cmder
echo.

echo Pour configurer manuellement dans VS Code:
echo 1. Ctrl+Shift+P → "Preferences: Open Settings (JSON)"
echo 2. Remplacer le profil Cmder par "PowerShell" ou "Command Prompt"

echo.
echo ========================================
echo Réparation terminée!
echo ========================================
pause
