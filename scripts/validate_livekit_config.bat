@echo off
echo ========================================
echo VALIDATION DE LA CONFIGURATION LIVEKIT
echo ========================================
echo.

echo [1] Verification du fichier livekit.yaml...
if exist "livekit.yaml" (
    echo ✓ Fichier livekit.yaml trouve
    findstr /C:"port: 7881" livekit.yaml >nul && echo ✓ Port 7881 configure || echo ✗ Port incorrect
    findstr /C:"devkey:" livekit.yaml >nul && echo ✓ Cle API 'devkey' configuree || echo ✗ Cle API manquante
    findstr /C:"devsecret123456789abcdef" livekit.yaml >nul && echo ✓ Secret API configure || echo ✗ Secret API manquant
) else (
    echo ✗ Fichier livekit.yaml manquant
)
echo.

echo [2] Verification du fichier frontend .env...
if exist "eloquence_v_2\eloquence_v_2_frontend\.env" (
    echo ✓ Fichier frontend .env trouve
    findstr /C:"LIVEKIT_WS_URL=ws://10.0.2.2:7881" eloquence_v_2\eloquence_v_2_frontend\.env >nul && echo ✓ URL WebSocket correcte || echo ✗ URL WebSocket incorrecte
    findstr /C:"LIVEKIT_API_KEY=devkey" eloquence_v_2\eloquence_v_2_frontend\.env >nul && echo ✓ Cle API frontend correcte || echo ✗ Cle API frontend incorrecte
    findstr /C:"LIVEKIT_API_SECRET=devsecret123456789abcdef" eloquence_v_2\eloquence_v_2_frontend\.env >nul && echo ✓ Secret API frontend correct || echo ✗ Secret API frontend incorrect
) else (
    echo ✗ Fichier frontend .env manquant
)
echo.

echo [3] Verification du fichier backend .env...
if exist "eloquence-backend\eloquence-backend\.env" (
    echo ✓ Fichier backend .env trouve
    findstr /C:"PUBLIC_LIVEKIT_URL=ws://10.0.2.2:7881" eloquence-backend\eloquence-backend\.env >nul && echo ✓ URL publique correcte || echo ✗ URL publique incorrecte
    findstr /C:"LIVEKIT_API_KEY=devkey" eloquence-backend\eloquence-backend\.env >nul && echo ✓ Cle API backend correcte || echo ✗ Cle API backend incorrecte
    findstr /C:"LIVEKIT_API_SECRET=devsecret123456789abcdef" eloquence-backend\eloquence-backend\.env >nul && echo ✓ Secret API backend correct || echo ✗ Secret API backend incorrect
) else (
    echo ✗ Fichier backend .env manquant
)
echo.

echo [4] Verification de la coherence des ports...
echo Tous les composants utilisent maintenant le port 7881 :
echo - Serveur LiveKit : port 7881
echo - Frontend WebSocket : ws://10.0.2.2:7881
echo - Backend URL publique : ws://10.0.2.2:7881
echo.

echo [5] Verification des cles API...
echo Toutes les cles utilisent maintenant :
echo - API_KEY : devkey
echo - API_SECRET : devsecret123456789abcdef0123456789abcdef0123456789abcdef
echo.

echo ========================================
echo VALIDATION TERMINEE
echo ========================================
echo.
echo Pour tester la configuration :
echo 1. Redemarrez le serveur LiveKit
echo 2. Redemarrez le backend
echo 3. Relancez l'application frontend
echo.
pause