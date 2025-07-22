@echo off
echo === AJOUT DES REGLES PARE-FEU POUR ELOQUENCE ===
echo.
echo CE SCRIPT DOIT ETRE EXECUTE EN TANT QU'ADMINISTRATEUR
echo.
pause

echo Ajout de Eloquence-Whisper-STT...
netsh advfirewall firewall add rule name="Eloquence-Whisper-STT" dir=in action=allow protocol=TCP localport=8001
echo.
echo Ajout de Eloquence-Azure-TTS...
netsh advfirewall firewall add rule name="Eloquence-Azure-TTS" dir=in action=allow protocol=TCP localport=5002
echo.
echo Ajout de Eloquence-LiveKit...
netsh advfirewall firewall add rule name="Eloquence-LiveKit" dir=in action=allow protocol=TCP localport=7880
echo.
echo Ajout de Eloquence-LiveKit-UDP...
netsh advfirewall firewall add rule name="Eloquence-LiveKit-UDP" dir=in action=allow protocol=UDP localport=7880
echo.
echo Ajout de Eloquence-Redis...
netsh advfirewall firewall add rule name="Eloquence-Redis" dir=in action=allow protocol=TCP localport=6379
echo.
echo Ajout de Eloquence-WebRTC-UDP...
netsh advfirewall firewall add rule name="Eloquence-WebRTC-UDP" dir=in action=allow protocol=UDP localport=50000-60000
echo.

echo === REGLES AJOUTEES ===
pause
