# Script de nettoyage simple Eloquence
Write-Host "Demarrage nettoyage Eloquence..." -ForegroundColor Green

# Verification services critiques
$critical_services = @(
    "services/livekit-server",
    "services/livekit-agent", 
    "services/eloquence-exercises-api",
    "services/vosk-stt-analysis",
    "services/mistral-conversation"
)

foreach ($service in $critical_services) {
    if (!(Test-Path $service)) {
        Write-Host "ERREUR: $service manquant !" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "OK: $service present" -ForegroundColor Green
    }
}

# Suppression services redondants
$redundant_services = @(
    "services/api-backend",
    "services/eloquence-streaming-api",
    "services/livekit-unified-agent",
    "services/whisper-realtime",
    "services/whisper-stt"
)

foreach ($service in $redundant_services) {
    if (Test-Path $service) {
        Write-Host "Suppression $service" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $service
    }
}

# Suppression documentation obsolete
$obsolete_docs = @(
    "ARCHITECTURE_LIVEKIT_UNIVERSELLE_ELOQUENCE.md",
    "CORRECTION_DIAGNOSTIC_ARCHITECTURE_ELOQUENCE.md",
    "DIAGNOSTIC_COMPLET_AUDIO_FLUTTER_FINAL.md",
    "DIAGNOSTIC_CONVERSATION_STREAMING_LIVEKIT.md",
    "DIAGNOSTIC_FINAL_CORRECTION_AUDIO_FLUTTER_ELOQUENCE.md",
    "DIAGNOSTIC_PROBLEME_AUDIO_IA_MUETTE.md",
    "GUIDE_ARCHITECTURE_EXERCICES_VOCAUX_ELOQUENCE.md",
    "GUIDE_DEMARRAGE_RAPIDE_PORTS.md",
    "GUIDE_TEST_SOLUTION_FINALE_VIRELANGUES.md",
    "RAPPORT_CORRECTION_AUDIO_CAPTURE_FINAL.md",
    "RAPPORT_CORRECTION_PORTS.md",
    "RAPPORT_CORRECTION_PORTS_FINAL.md",
    "RAPPORT_CORRECTION_PORTS_MOBILE.md",
    "RAPPORT_FINAL_ARCHITECTURE_LIVEKIT_UNIVERSELLE_ELOQUENCE.md",
    "RAPPORT_FINAL_CORRECTION_AUDIO_CAPTURE_FLUTTER_ELOQUENCE.md",
    "RAPPORT_FINAL_CORRECTION_AUDIO_FLUTTER_ELOQUENCE.md",
    "RAPPORT_FINAL_CORRECTION_DRAGON_BREATH.md",
    "RESOLUTION_AUDIO_IA_MUETTE_SUMMARY.md",
    "SOLUTION_VIRELANGUES_AUDIO.md"
)

foreach ($doc in $obsolete_docs) {
    if (Test-Path $doc) {
        Write-Host "Suppression $doc" -ForegroundColor Yellow
        Remove-Item -Force $doc
    }
}

# Suppression dossiers temporaires
$temp_dirs = @(
    "conversation_audio",
    "logs",
    "logs_pipeline_audio",
    "eloquence-livekit-system",
    "Eloquence",
    "Blender-mcp",
    "diagnostic_reports"
)

foreach ($dir in $temp_dirs) {
    if (Test-Path $dir) {
        Write-Host "Suppression $dir/" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $dir
    }
}

# Suppression fichiers test racine
Get-ChildItem -Path "." -Name "test_*.py" | Remove-Item -Force
if (Test-Path "real_conversation_launcher.py") { Remove-Item -Force "real_conversation_launcher.py" }
if (Test-Path "debug_audio_logs.ps1") { Remove-Item -Force "debug_audio_logs.ps1" }

Write-Host "Nettoyage termine avec succes !" -ForegroundColor Green
