@echo off
REM Script pour tester le statut de LiveKit
REM Auteur: Cline
REM Date: 23/05/2025

echo ==========================================================
echo     TEST DU STATUT LIVEKIT
echo ==========================================================

echo [1/4] Test de connectivité sur le port 7881...
powershell -Command "try { $connection = Test-NetConnection -ComputerName localhost -Port 7881 -WarningAction SilentlyContinue; if ($connection.TcpTestSucceeded) { Write-Host 'PORT 7881: OUVERT (LiveKit accessible)' -ForegroundColor Green } else { Write-Host 'PORT 7881: FERMÉ (LiveKit non accessible)' -ForegroundColor Red } } catch { Write-Host 'PORT 7881: FERMÉ (LiveKit non accessible)' -ForegroundColor Red }"

echo.
echo [2/4] Vérification des conteneurs Docker...
docker ps --filter "name=livekit" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo [3/4] Test de connexion WebSocket...
powershell -Command "try { $ws = New-Object System.Net.WebSockets.ClientWebSocket; $uri = [System.Uri]::new('ws://localhost:7881'); $cancelToken = [System.Threading.CancellationToken]::None; $task = $ws.ConnectAsync($uri, $cancelToken); $timeout = [System.TimeSpan]::FromSeconds(5); if ($task.Wait($timeout)) { Write-Host 'WEBSOCKET: CONNEXION RÉUSSIE' -ForegroundColor Green; $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'Test', $cancelToken).Wait() } else { Write-Host 'WEBSOCKET: TIMEOUT (pas de réponse)' -ForegroundColor Red } } catch { Write-Host 'WEBSOCKET: ÉCHEC DE CONNEXION' -ForegroundColor Red }"

echo.
echo [4/4] Résumé du diagnostic...
echo.
echo Si PORT 7881 est FERMÉ:
echo   - LiveKit n'est pas démarré
echo   - Utilisez la solution alternative ci-dessous
echo.
echo Si PORT 7881 est OUVERT mais WEBSOCKET échoue:
echo   - LiveKit fonctionne mais mal configuré
echo   - Vérifiez les clés API et la configuration
echo.
echo ==========================================================
echo     SOLUTION ALTERNATIVE SIMPLE
echo ==========================================================
echo.
echo Si LiveKit ne démarre pas avec Docker, essayez:
echo.
echo 1. Démarrez avec un port différent:
echo    docker run -d --name livekit-alt -p 7881:7881 livekit/livekit-server
echo.
echo 2. Ou utilisez un serveur LiveKit en ligne (pour test):
echo    - Configurez votre backend pour utiliser wss://livekit.eloquence.com
echo    - Ou utilisez le service LiveKit Cloud temporairement
echo.
echo 3. Test rapide avec telnet:
echo    telnet localhost 7881
echo.
pause
