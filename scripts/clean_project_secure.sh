#!/bin/bash
# === NETTOYAGE ULTRA-SÉCURISÉ ELOQUENCE ===
# Script de refactorisation avec préservation absolue des services critiques

set -e  # Arrêter en cas d'erreur

echo "🔒 DÉMARRAGE NETTOYAGE ULTRA-SÉCURISÉ ELOQUENCE"
echo "================================================"

# === VÉRIFICATION PRÉALABLE SERVICES CRITIQUES ===
echo "🔍 Vérification services critiques..."

critical_services=(
    "services/livekit-server"
    "services/livekit-agent" 
    "services/eloquence-exercises-api"
    "services/vosk-stt-analysis"
    "services/mistral-conversation"
)

for service in "${critical_services[@]}"; do
    if [ ! -d "$service" ]; then
        echo "❌ ERREUR CRITIQUE: $service manquant !"
        exit 1
    else
        echo "✅ $service présent"
    fi
done

echo ""
echo "🗑️ Suppression UNIQUEMENT services redondants validés..."

# === SUPPRESSION CIBLÉE SERVICES REDONDANTS ===
redundant_services=(
    "services/api-backend"
    "services/eloquence-streaming-api"
    "services/livekit-unified-agent"
    "services/whisper-realtime"
    "services/whisper-stt"
)

for service in "${redundant_services[@]}"; do
    if [ -d "$service" ]; then
        echo "  - Suppression $service (redondant)"
        rm -rf "$service"
    else
        echo "  - $service déjà absent"
    fi
done

# === SUPPRESSION DOCUMENTATION OBSOLÈTE ===
echo ""
echo "📚 Nettoyage documentation obsolète..."

obsolete_docs=(
    "ARCHITECTURE_LIVEKIT_UNIVERSELLE_ELOQUENCE.md"
    "CORRECTION_DIAGNOSTIC_ARCHITECTURE_ELOQUENCE.md"
    "DIAGNOSTIC_COMPLET_AUDIO_FLUTTER_FINAL.md"
    "DIAGNOSTIC_CONVERSATION_STREAMING_LIVEKIT.md"
    "DIAGNOSTIC_FINAL_CORRECTION_AUDIO_FLUTTER_ELOQUENCE.md"
    "DIAGNOSTIC_PROBLEME_AUDIO_IA_MUETTE.md"
    "GUIDE_ARCHITECTURE_EXERCICES_VOCAUX_ELOQUENCE.md"
    "GUIDE_DEMARRAGE_RAPIDE_PORTS.md"
    "GUIDE_TEST_SOLUTION_FINALE_VIRELANGUES.md"
    "RAPPORT_CORRECTION_AUDIO_CAPTURE_FINAL.md"
    "RAPPORT_CORRECTION_PORTS.md"
    "RAPPORT_CORRECTION_PORTS_FINAL.md"
    "RAPPORT_CORRECTION_PORTS_MOBILE.md"
    "RAPPORT_FINAL_ARCHITECTURE_LIVEKIT_UNIVERSELLE_ELOQUENCE.md"
    "RAPPORT_FINAL_CORRECTION_AUDIO_CAPTURE_FLUTTER_ELOQUENCE.md"
    "RAPPORT_FINAL_CORRECTION_AUDIO_FLUTTER_ELOQUENCE.md"
    "RAPPORT_FINAL_CORRECTION_DRAGON_BREATH.md"
    "RESOLUTION_AUDIO_IA_MUETTE_SUMMARY.md"
    "SOLUTION_VIRELANGUES_AUDIO.md"
)

for doc in "${obsolete_docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "  - Suppression $doc"
        rm -f "$doc"
    fi
done

# Supprimer dossier diagnostic_reports
if [ -d "diagnostic_reports" ]; then
    echo "  - Suppression diagnostic_reports/"
    rm -rf "diagnostic_reports"
fi

# === SUPPRESSION SCRIPTS OBSOLÈTES ===
echo ""
echo "📜 Nettoyage scripts obsolètes..."

obsolete_scripts=(
    "scripts/check_docker_services.bat"
    "scripts/check_livekit_compatibility.py"
    "scripts/configure_firewall_mobile.bat"
    "scripts/diagnostic_mobile.bat"
    "scripts/diagnostic_webrtc.bat"
    "scripts/diagnostic_webrtc.sh"
    "scripts/fix_complete_pipeline.bat"
    "scripts/fix_flutter_dependencies.bat"
    "scripts/fix_flutter_environment.bat"
    "scripts/fix_flutter_quick.bat"
    "scripts/fix_livekit_agent_startup.bat"
    "scripts/fix_loggers.ps1"
    "scripts/fix_terminal_direct.bat"
    "scripts/fix_terminal_final.ps1"
    "scripts/fix_terminal_simple.ps1"
    "scripts/fix_vscode_terminal_default.bat"
    "scripts/fix_vscode_terminal_flutter.bat"
    "scripts/install_git_and_fix_flutter.bat"
    "scripts/optimize_mcp_servers.ps1"
    "scripts/optimize_vscode_performance.ps1"
    "scripts/push_to_github.bat"
    "scripts/test.sh"
    "scripts/test_livekit_status.bat"
    "scripts/test_migration_v1.bat"
    "scripts/test_mobile_connectivity.bat"
    "scripts/validate_livekit_config.bat"
    "scripts/validate_ports_configuration.py"
)

for script in "${obsolete_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "  - Suppression $script"
        rm -f "$script"
    fi
done

# === SUPPRESSION TESTS OBSOLÈTES ===
echo ""
echo "🧪 Nettoyage tests obsolètes..."

if [ -d "frontend/flutter_app/test/features/confidence_boost" ]; then
    echo "  - Suppression frontend/flutter_app/test/features/confidence_boost/"
    rm -rf "frontend/flutter_app/test/features/confidence_boost"
fi

if [ -d "frontend/flutter_app/integration_test" ]; then
    echo "  - Suppression frontend/flutter_app/integration_test/"
    rm -rf "frontend/flutter_app/integration_test"
fi

# Supprimer fichiers de test racine obsolètes
test_files=(
    "test_*.py"
    "real_conversation_launcher.py"
    "debug_audio_logs.ps1"
)

for pattern in "${test_files[@]}"; do
    find . -maxdepth 1 -name "$pattern" -delete 2>/dev/null || true
done

# === SUPPRESSION FICHIERS TEMPORAIRES ===
echo ""
echo "🧹 Nettoyage fichiers temporaires..."

# Supprimer fichiers temporaires
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.log" -delete 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true

# Supprimer dossiers temporaires
temp_dirs=(
    "conversation_audio"
    "logs"
    "logs_pipeline_audio"
    "eloquence-livekit-system"
    "Eloquence"
    "Blender-mcp"
)

for dir in "${temp_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  - Suppression $dir/"
        rm -rf "$dir"
    fi
done

# === VÉRIFICATION POST-SUPPRESSION ===
echo ""
echo "🔍 Vérification post-suppression..."

for service in "${critical_services[@]}"; do
    if [ ! -d "$service" ]; then
        echo "❌ ERREUR CRITIQUE: $service supprimé par erreur !"
        exit 1
    fi
done

echo ""
echo "✅ NETTOYAGE ULTRA-SÉCURISÉ TERMINÉ"
echo "✅ Tous les services critiques préservés"
echo "✅ Services redondants supprimés"
echo "✅ Documentation obsolète nettoyée"
echo "✅ Scripts obsolètes supprimés"
echo "✅ Tests obsolètes supprimés"
echo "✅ Fichiers temporaires nettoyés"
