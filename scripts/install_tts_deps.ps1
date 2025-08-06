# Installation des dépendances TTS pour les tests d'intégration (Windows)

Write-Host "🔊 Installation des dépendances TTS..." -ForegroundColor Cyan

# Vérifier Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python trouvé: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python non trouvé! Installez Python depuis python.org" -ForegroundColor Red
    exit 1
}

# Installer pyttsx3 (TTS local)
Write-Host "📦 Installation pyttsx3 (TTS local)..." -ForegroundColor Yellow
try {
    pip install pyttsx3
    Write-Host "✅ pyttsx3 installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur installation pyttsx3" -ForegroundColor Red
}

# Installer gTTS (TTS internet, fallback)  
Write-Host "📦 Installation gTTS (TTS internet)..." -ForegroundColor Yellow
try {
    pip install gtts
    Write-Host "✅ gTTS installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur installation gTTS" -ForegroundColor Red
}

# Installer aiohttp pour les tests API
Write-Host "📦 Installation aiohttp..." -ForegroundColor Yellow
try {
    pip install aiohttp
    Write-Host "✅ aiohttp installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur installation aiohttp" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Installation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Pour lancer les tests:" -ForegroundColor Cyan
Write-Host "   python test_livekit_ia_integration.py" -ForegroundColor White
Write-Host ""
Write-Host "📋 Prérequis:" -ForegroundColor Cyan
Write-Host "   - Services Docker en cours: docker-compose up -d" -ForegroundColor White
Write-Host "   - Vosk STT disponible sur port 8002" -ForegroundColor White
Write-Host "   - Mistral IA disponible sur port 8001" -ForegroundColor White