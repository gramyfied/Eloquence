#!/usr/bin/env bash
set -euo pipefail

echo "🎭 VALIDATION SYSTÈME DE NATURALITÉ"
echo "=================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Tests unitaires
echo "📋 Lancement des tests unitaires..."
python test_naturalness_system.py | cat

echo "✅ Tests unitaires RÉUSSIS"

# Test d'intégration minimal
echo "🔗 Test d'intégration..."
python - <<'PY'
from multi_agent_manager import MultiAgentManager
from multi_agent_config import ExerciseTemplates

config = ExerciseTemplates.studio_debate_tv()
manager = MultiAgentManager(config)

# Test détection interpellation
result = manager.address_detector.detect_direct_addresses(
    'Sarah, que pensez-vous de cette idée ?',
    {'sarah': type('Agent', (), {'name': 'Sarah Johnson'})()}
)
assert 'sarah' in result
print('✅ Détection interpellation OK')

# Test prévention auto-dialogue
assert manager.dialogue_prevention.can_agent_respond('sarah', 'test')
manager.dialogue_prevention.register_speaker('sarah')
assert not manager.dialogue_prevention.can_agent_respond('sarah', 'test')
print('✅ Prévention auto-dialogue OK')

print('🎉 INTÉGRATION COMPLÈTE VALIDÉE')
PY

echo "🎭 SYSTÈME DE NATURALITÉ PRÊT !"


