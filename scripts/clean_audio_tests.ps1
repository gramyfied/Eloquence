#!/usr/bin/env pwsh
# Script de nettoyage des fichiers de test audio obsolètes

Write-Host "🧹 NETTOYAGE FICHIERS TEST AUDIO OBSOLÈTES" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$startTime = Get-Date

# === FICHIERS DE TEST AUDIO À SUPPRIMER ===
$audioTestFiles = @(
    # Tests Python racine
    "test_vosk_connectivity.py",
    "test_virelangue_fix.py", 
    "test_virelangue_fix_optimized.py",
    "test_connectivity_debug.py",
    "test_httpx_asyncclient_debug.py",
    "test_vosk_multipart_debug.py",
    "test_virelangue_mobile_final.py",
    "test_virelangue_tts_realistic.py",
    "test_virelangue_tts_simple.py",
    "test_vosk_correction.py",
    "test_vosk_simple.py",
    "test_vosk_final.py",
    "test_virelangue_endpoint.py",
    "test_livekit_agent.py",
    "test_livekit_tokens_pure.dart",
    "test_livekit_audio_pipeline.py",
    "test_livekit_api.py",
    "test_stt_latency_comparison.py",
    "real_conversation_launcher.py",
    
    # Tests story generation
    "test_story_elements_api.py",
    "test_story_elements_simple.py", 
    "test_story_generation_unit.py",
    "test_story_generation_clean.py",
    "test_flutter_backend_integration.py",
    "test_integration_clean.py",
    "test_story_narrative_analysis.py",
    
    # Tests Flutter
    "test_network_config.dart",
    "test_config_simple.dart",
    "test_config_final.dart",
    "test_livekit_integration.dart",
    "test_audio_diagnosis.dart",
    
    # Rapports et logs audio
    "RAPPORT_VALIDATION_AUDIO_CAPTURE.json",
    "rapport_eloquence_conversation_test_session_*.json",
    "flutter_pipeline_response.mp3",
    "test_marie_response.mp3",
    "tts_response_session_*.mp3",
    "livekit_performance_graphs_*.png",
    
    # Guides de test audio obsolètes
    "frontend/flutter_app/LIVEKIT_AUDIO_FIX_GUIDE.md",
    "frontend/flutter_app/GUIDE_TEST_AUDIO_LIVEKIT_FIX.md",
    "frontend/flutter_app/GUIDE_TEST_SOLUTION_URGENCE.md",
    "frontend/flutter_app/GUIDE_RESOLUTION_AUDIO_MODERNE_FINAL.md",
    "frontend/flutter_app/GUIDE_RESOLUTION_AUDIO_FINAL_REALISTE.md",
    "RESOLUTION_AUDIO_IA_MUETTE_SUMMARY.md",
    
    # Scripts de fix audio obsolètes
    "debug_audio_logs.ps1"
)

# === DOSSIERS DE TEST À SUPPRIMER ===
$audioTestDirs = @(
    "tests/",
    "logs/",
    "logs_pipeline_audio/",
    "frontend/flutter_app/test/root_tests/",
    "frontend/flutter_app/test/features/confidence_boost/",
    "frontend/flutter_app/test_hive/",
    "frontend/flutter_app/test_hive_memory/",
    "frontend/flutter_app/integration_test/"
)

# === FICHIERS DANS SERVICES ===
$serviceTestFiles = @(
    "services/vosk-stt-analysis/test_ffmpeg_fix.py",
    "services/eloquence-exercises-api/test_api.py",
    "services/eloquence-exercises-api/test_voice_analysis.py",
    "services/eloquence-exercises-api/test_voice_analysis_simple.py",
    "services/eloquence-exercises-api/test_websocket_realtime.py",
    "services/eloquence-exercises-api/test_websocket_simple.py",
    "services/eloquence-exercises-api/test_websocket_debug.py",
    "services/eloquence-exercises-api/test_websocket_complete.py",
    "services/eloquence-streaming-api/test_connectivity.py",
    "services/eloquence-streaming-api/test_conversation_complete.py",
    "services/eloquence-streaming-api/test_conversation_simple.py",
    "services/eloquence-streaming-api/test_audio_analysis.py",
    "services/eloquence-streaming-api/test_websocket_direct.py",
    "services/eloquence-streaming-api/test_websocket_simple.py",
    "services/eloquence-streaming-api/test_websocket_final.py",
    "services/eloquence-streaming-api/test_streaming_conversation.py",
    "services/eloquence-streaming-api/test_streaming_simple.py",
    "services/livekit-server/test_token_sdk.py",
    "services/livekit-server/test_token_simple.py",
    "services/livekit-server/test_token_flutter_format.py",
    "services/livekit-server/test_token_real_connection.py",
    "services/livekit-server/test_pipeline_complet.py",
    "services/api-backend/test_vosk_connectivity.py"
)

# === SCRIPTS DE FIX OBSOLÈTES ===
$fixScripts = @(
    "scripts/check_docker_services.bat",
    "scripts/check_livekit_compatibility.py",
    "scripts/configure_firewall_mobile.bat",
    "scripts/diagnostic_mobile.bat",
    "scripts/diagnostic_webrtc.bat",
    "scripts/diagnostic_webrtc.sh",
    "scripts/fix_complete_pipeline.bat",
    "scripts/fix_flutter_dependencies.bat",
    "scripts/fix_flutter_environment.bat",
    "scripts/fix_flutter_quick.bat",
    "scripts/fix_livekit_agent_startup.bat",
    "scripts/fix_loggers.ps1",
    "scripts/fix_terminal_direct.bat",
    "scripts/fix_terminal_final.ps1",
    "scripts/fix_terminal_simple.ps1",
    "scripts/fix_vscode_terminal_default.bat",
    "scripts/fix_vscode_terminal_flutter.bat",
    "scripts/install_git_and_fix_flutter.bat",
    "scripts/push_to_github.bat",
    "scripts/test.sh",
    "scripts/test_livekit_status.bat",
    "scripts/test_migration_v1.bat",
    "scripts/test_mobile_connectivity.bat",
    "scripts/validate_livekit_config.bat",
    "scripts/validate_ports_configuration.py"
)

$deletedFiles = 0
$deletedDirs = 0
$errors = @()

Write-Host "🗂️ Suppression des fichiers de test audio..." -ForegroundColor Yellow

# Supprimer les fichiers individuels
foreach ($file in $audioTestFiles + $serviceTestFiles + $fixScripts) {
    if (Test-Path $file) {
        try {
            Remove-Item $file -Force
            Write-Host "✅ Supprimé: $file" -ForegroundColor Green
            $deletedFiles++
        }
        catch {
            $errors += "❌ Erreur suppression $file : $_"
            Write-Host "❌ Erreur: $file" -ForegroundColor Red
        }
    }
}

Write-Host "`n📁 Suppression des dossiers de test..." -ForegroundColor Yellow

# Supprimer les dossiers
foreach ($dir in $audioTestDirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item $dir -Recurse -Force
            Write-Host "✅ Dossier supprimé: $dir" -ForegroundColor Green
            $deletedDirs++
        }
        catch {
            $errors += "❌ Erreur suppression dossier $dir : $_"
            Write-Host "❌ Erreur dossier: $dir" -ForegroundColor Red
        }
    }
}

Write-Host "`n🧹 Nettoyage fichiers temporaires audio..." -ForegroundColor Yellow

# Nettoyer fichiers temporaires audio
$tempPatterns = @("*.wav", "*.mp3", "*.m4a", "*.aac", "test_audio*", "*_audio_test*")
foreach ($pattern in $tempPatterns) {
    $tempFiles = Get-ChildItem -Path . -Name $pattern -Recurse -ErrorAction SilentlyContinue
    foreach ($tempFile in $tempFiles) {
        if ($tempFile -notlike "*assets*" -and $tempFile -notlike "*resources*") {
            try {
                Remove-Item $tempFile -Force
                Write-Host "✅ Temp supprimé: $tempFile" -ForegroundColor Green
                $deletedFiles++
            }
            catch {
                $errors += "❌ Erreur temp $tempFile : $_"
            }
        }
    }
}

Write-Host "`n🔍 Nettoyage fichiers de debug Flutter..." -ForegroundColor Yellow

# Nettoyer fichiers debug Flutter spécifiques
$flutterDebugFiles = @(
    "frontend/flutter_app/lib/debug/audio_diagnostic.dart",
    "frontend/flutter_app/analyze_results.txt",
    "frontend/flutter_app/test_results_initial.txt",
    "frontend/flutter_app/test_connection.bat"
)

foreach ($file in $flutterDebugFiles) {
    if (Test-Path $file) {
        try {
            Remove-Item $file -Force
            Write-Host "✅ Debug Flutter supprimé: $file" -ForegroundColor Green
            $deletedFiles++
        }
        catch {
            $errors += "❌ Erreur debug Flutter $file : $_"
        }
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" -NoNewline
Write-Host "🎉 NETTOYAGE TERMINÉ !" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host "📊 Fichiers supprimés: $deletedFiles" -ForegroundColor Cyan
Write-Host "📁 Dossiers supprimés: $deletedDirs" -ForegroundColor Cyan
Write-Host "⏱️ Durée: $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Cyan

if ($errors.Count -gt 0) {
    Write-Host "`n⚠️ ERREURS RENCONTRÉES:" -ForegroundColor Yellow
    foreach ($errorMsg in $errors) {
        Write-Host $errorMsg -ForegroundColor Red
    }
}

Write-Host "`n✨ Base de code nettoyée des tests audio obsolètes !" -ForegroundColor Green
Write-Host "🚀 Prêt pour la nouvelle architecture unifiée !" -ForegroundColor Magenta
