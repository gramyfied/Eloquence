# === NETTOYAGE ULTRA-SÉCURISÉ ELOQUENCE ===
# Script PowerShell de refactorisation avec préservation absolue des services critiques

Write-Host "🔒 DÉMARRAGE NETTOYAGE ULTRA-SÉCURISÉ ELOQUENCE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# === VÉRIFICATION PRÉALABLE SERVICES CRITIQUES ===
Write-Host "🔍 Vérification services critiques..." -ForegroundColor Yellow

$critical_services = @(
    "services/livekit-server",
    "services/livekit-agent", 
    "services/eloquence-exercises-api",
    "services/vosk-stt-analysis",
    "services/mistral-conversation"
)

foreach ($service in $critical_services) {
    if (!(Test-Path $service)) {
        Write-Host "❌ ERREUR CRITIQUE: $service manquant !" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ $service présent" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🗑️ Suppression UNIQUEMENT services redondants validés..." -ForegroundColor Yellow

# === SUPPRESSION CIBLÉE SERVICES REDONDANTS ===
$redundant_services = @(
    "services/api-backend",
    "services/eloquence-streaming-api",
    "services/livekit-unified-agent",
    "services/whisper-realtime",
    "services/whisper-stt"
)

foreach ($service in $redundant_services) {
    if (Test-Path $service) {
        Write-Host "  - Suppression $service (redondant)" -ForegroundColor Cyan
        Remove-Item -Recurse -Force $service
    } else {
        Write-Host "  - $service déjà absent" -ForegroundColor Gray
    }
}

# === SUPPRESSION DOCUMENTATION OBSOLÈTE ===
Write-Host ""
Write-Host "📚 Nettoyage documentation obsolète..." -ForegroundColor Yellow

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
        Write-Host "  - Suppression $doc" -ForegroundColor Cyan
        Remove-Item -Force $doc
    }
}

# Supprimer dossier diagnostic_reports
if (Test-Path "diagnostic_reports") {
    Write-Host "  - Suppression diagnostic_reports/" -ForegroundColor Cyan
    Remove-Item -Recurse -Force "diagnostic_reports"
}

# === SUPPRESSION FICHIERS TEMPORAIRES ===
Write-Host ""
Write-Host "🧹 Nettoyage fichiers temporaires..." -ForegroundColor Yellow

# Supprimer dossiers temporaires
$temp_dirs = @(
    "conversation_audio",
    "logs",
    "logs_pipeline_audio",
    "eloquence-livekit-system",
    "Eloquence",
    "Blender-mcp"
)

foreach ($dir in $temp_dirs) {
    if (Test-Path $dir) {
        Write-Host "  - Suppression $dir/" -ForegroundColor Cyan
        Remove-Item -Recurse -Force $dir
    }
}

# Supprimer fichiers de test racine obsolètes
Get-ChildItem -Path "." -Name "test_*.py" | Remove-Item -Force
if (Test-Path "real_conversation_launcher.py") { Remove-Item -Force "real_conversation_launcher.py" }
if (Test-Path "debug_audio_logs.ps1") { Remove-Item -Force "debug_audio_logs.ps1" }

# === VÉRIFICATION POST-SUPPRESSION ===
Write-Host ""
Write-Host "🔍 Vérification post-suppression..." -ForegroundColor Yellow

foreach ($service in $critical_services) {
    if (!(Test-Path $service)) {
        Write-Host "❌ ERREUR CRITIQUE: $service supprimé par erreur !" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "NETTOYAGE ULTRA-SECURISE TERMINE" -ForegroundColor Green
Write-Host "Tous les services critiques preserves" -ForegroundColor Green
Write-Host "Services redondants supprimes" -ForegroundColor Green
Write-Host "Documentation obsolete nettoyee" -ForegroundColor Green
Write-Host "Fichiers temporaires nettoyes" -ForegroundColor Green
