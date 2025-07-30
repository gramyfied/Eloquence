@echo off
echo Configuration du pare-feu Windows pour l'accès mobile...

REM Autoriser les ports pour les services Eloquence
netsh advfirewall firewall add rule name="Eloquence API Backend" dir=in action=allow protocol=TCP localport=8000
netsh advfirewall firewall add rule name="Eloquence Mistral LLM" dir=in action=allow protocol=TCP localport=8001
netsh advfirewall firewall add rule name="Eloquence Vosk STT" dir=in action=allow protocol=TCP localport=2700
netsh advfirewall firewall add rule name="Eloquence LiveKit" dir=in action=allow protocol=TCP localport=7880

echo Règles de pare-feu ajoutées avec succès !
echo.
echo Vérification des règles créées :
netsh advfirewall firewall show rule name="Eloquence API Backend"
netsh advfirewall firewall show rule name="Eloquence Mistral LLM"
netsh advfirewall firewall show rule name="Eloquence Vosk STT"
netsh advfirewall firewall show rule name="Eloquence LiveKit"

pause
