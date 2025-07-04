#!/bin/bash
# Tests complets Eloquence

echo "🧪 Lancement tests Eloquence..."

# Tests Flutter
echo "📱 Tests Flutter..."
cd frontend/flutter_app
flutter test
cd ../..

# Tests Backend
echo "🐍 Tests Backend..."
cd services/api-backend
python -m pytest tests/ -v
cd ../..

# Tests d'intégration
echo "🔗 Tests d'intégration..."
cd tests/integration
python test_final_validation.py
cd ../..

echo "✅ Tous les tests terminés !"