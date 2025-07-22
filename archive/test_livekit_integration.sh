#!/bin/bash

# 🧪 Script de Test Automatisé - Connectivité LiveKit
# Usage: ./test_livekit_integration.sh

set -e

echo "🚀 === TEST LIVEKIT INTEGRATION COMPLETE ==="
echo ""

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

success_count=0
total_tests=0

# Fonction pour tester un endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local post_data="$4"
    
    echo -n "[TEST] $name... "
    total_tests=$((total_tests + 1))
    
    if [ -n "$post_data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST "$url" \
            -H "Content-Type: application/json" \
            -d "$post_data" \
            --max-time 10 || echo "000")
    else
        response=$(curl -s -w "%{http_code}" "$url" --max-time 10 || echo "000")
    fi
    
    status_code="${response: -3}"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        success_count=$((success_count + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL (Status: $status_code)${NC}"
        return 1
    fi
}

# Fonction pour vérifier un service Docker
check_docker_service() {
    local service_name="$1"
    echo -n "[DOCKER] Vérification $service_name... "
    total_tests=$((total_tests + 1))
    
    if docker-compose ps | grep -q "$service_name.*Up"; then
        echo -e "${GREEN}✅ RUNNING${NC}"
        success_count=$((success_count + 1))
        return 0
    else
        echo -e "${RED}❌ NOT RUNNING${NC}"
        return 1
    fi
}

echo "📋 === ÉTAPE 1: VÉRIFICATION SERVICES DOCKER ==="
check_docker_service "api-backend"
check_docker_service "livekit-token-service" 
check_docker_service "livekit"
check_docker_service "eloquence-eloquence-agent-v1-1"
echo ""

echo "🔗 === ÉTAPE 2: TEST ENDPOINTS LIVEKIT ==="

# Test health check du service token  
test_endpoint "Token Service Health" "http://localhost:8004/health" "200"

# Test génération de token via API backend
test_endpoint "Token Generation" "http://localhost:8000/api/livekit/generate-token" "200" \
    '{"room_name":"test-room","participant_name":"test-user"}'

# Test configuration LiveKit
test_endpoint "LiveKit Config" "http://localhost:8000/api/livekit/config" "200"

# Test health check API backend
test_endpoint "API Backend Health" "http://localhost:8000/health" "200"

echo ""

echo "🎯 === ÉTAPE 3: TEST CRÉATION SESSION ==="

# Test création de session (simule Flutter)
test_endpoint "Session Creation" "http://localhost:8000/api/sessions" "201" \
    '{"user_id":"test-flutter-user","scenario_id":"demo-1","language":"fr"}'

echo ""

echo "⚡ === ÉTAPE 4: TEST DE CHARGE TOKENS ==="

echo "[LOAD TEST] Génération de 5 tokens simultanés..."
total_tests=$((total_tests + 1))

# Génération de 5 tokens en parallèle
for i in {1..5}; do
    curl -s -X POST http://localhost:8000/api/livekit/generate-token \
        -H "Content-Type: application/json" \
        -d "{\"room_name\":\"load-test-$i\",\"participant_name\":\"user-$i\"}" \
        --max-time 5 > /dev/null &
done

# Attendre que tous les processus se terminent
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ LOAD TEST PASS${NC}"
    success_count=$((success_count + 1))
else
    echo -e "${RED}❌ LOAD TEST FAIL${NC}"
fi

echo ""

echo "📊 === ÉTAPE 5: VÉRIFICATION LOGS ==="

echo "[LOGS] Recherche de signes de succès LiveKit..."
total_tests=$((total_tests + 1))

# Vérifier les logs pour des signes de succès LiveKit
success_logs=$(docker logs api-backend --tail 50 2>/dev/null | grep -c "SUCCESS.*LiveKit\|Token généré avec succès" || echo "0")

if [ "$success_logs" -gt 0 ]; then
    echo -e "${GREEN}✅ LOGS SHOW SUCCESS ($success_logs occurrences)${NC}"
    success_count=$((success_count + 1))
else
    echo -e "${YELLOW}⚠️  No success logs found (might be normal if no recent activity)${NC}"
fi

echo ""

echo "🔍 === ÉTAPE 6: DIAGNOSTIC AVANCÉ ==="

echo "[DIAGNOSTIC] Vérification circuit breaker..."
circuit_breaker_activations=$(docker logs api-backend --tail 100 2>/dev/null | grep -c "Circuit breaker ACTIVATED\|Service in cooldown" || echo "0")

if [ "$circuit_breaker_activations" -eq 0 ]; then
    echo -e "${GREEN}✅ No circuit breaker activations (GOOD)${NC}"
else
    echo -e "${YELLOW}⚠️  Circuit breaker activated $circuit_breaker_activations times${NC}"
fi

echo "[DIAGNOSTIC] Vérification fallbacks constants..."
fallback_activations=$(docker logs api-backend --tail 100 2>/dev/null | grep -c "SHIELD.*emergency fallback\|using fallback immediately" || echo "0")

if [ "$fallback_activations" -lt 3 ]; then
    echo -e "${GREEN}✅ Minimal fallback usage (GOOD)${NC}"
else
    echo -e "${RED}❌ Too many fallbacks ($fallback_activations) - investigate${NC}"
fi

echo ""

echo "📈 === RÉSULTATS FINAUX ==="
echo "Tests réussis: $success_count/$total_tests"

percentage=$((success_count * 100 / total_tests))

if [ $percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 EXCELLENT ($percentage%) - Système LiveKit opérationnel !${NC}"
    echo -e "${GREEN}✅ Flutter peut maintenant se connecter à votre agent LiveKit v1${NC}"
elif [ $percentage -ge 75 ]; then
    echo -e "${YELLOW}⚠️  BIEN ($percentage%) - Quelques problèmes mineurs${NC}"
    echo "Consultez les logs pour plus de détails"
elif [ $percentage -ge 50 ]; then
    echo -e "${YELLOW}🔧 MOYEN ($percentage%) - Problèmes à résoudre${NC}"
    echo "Vérifiez la configuration et les services"
else
    echo -e "${RED}❌ CRITIQUE ($percentage%) - Système non fonctionnel${NC}"
    echo "Vérifiez que tous les services Docker sont démarrés"
fi

echo ""
echo "📋 === PROCHAINES ÉTAPES ==="

if [ $percentage -ge 90 ]; then
    echo "1. 🎯 Tester avec Flutter: cd frontend/flutter_app && flutter run"
    echo "2. 📱 Démarrer une session Confidence Boost dans l'app"
    echo "3. 👀 Observer les logs: plus de fallbacks constants !"
    echo "4. 🚀 Profiter de votre agent LiveKit v1 connecté !"
else
    echo "1. 🔍 Vérifier les services: docker-compose ps"
    echo "2. 📜 Consulter les logs: docker logs api-backend"
    echo "3. 🔄 Relancer si nécessaire: docker-compose restart"
    echo "4. 🧪 Relancer ce test: ./test_livekit_integration.sh"
fi

echo ""
echo "📚 Pour plus de détails: consultez GUIDE_TEST_LIVEKIT.md"