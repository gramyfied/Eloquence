@echo off
echo === TEST DE CONNEXION LIVEKIT ===
echo.
echo 1. Test de connectivite reseau...
ping -n 1 192.168.1.44 > nul
if %errorlevel% == 0 (
    echo [OK] Serveur accessible
) else (
    echo [ERREUR] Serveur inaccessible
    exit /b 1
)

echo.
echo 2. Test du port LiveKit...
powershell -Command "Test-NetConnection -ComputerName 192.168.1.44 -Port 7880 -InformationLevel Quiet" > nul
if %errorlevel% == 0 (
    echo [OK] Port 7880 ouvert
) else (
    echo [ERREUR] Port 7880 ferme
    exit /b 1
)

echo.
echo 3. Verification du service Docker...
docker ps | findstr livekit > nul
if %errorlevel% == 0 (
    echo [OK] Service LiveKit en cours d'execution
) else (
    echo [ERREUR] Service LiveKit non demarre
    exit /b 1
)

echo.
echo === TOUS LES TESTS SONT PASSES ===
echo.
echo Vous pouvez maintenant lancer l'application Flutter avec:
echo   cd frontend/flutter_app
echo   flutter run
echo.
echo Pour utiliser l'ecran de diagnostic, ajoutez cette route dans votre app:
echo   '/diagnostic': (context) =^> const DiagnosticScreen(),
echo.
pause