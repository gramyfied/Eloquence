#!/bin/bash

echo "========================================"
echo "DIAGNOSTIC WEBRTC LIVEKIT - $(date)"
echo "========================================"

echo ""
echo "[1/6] VÉRIFICATION SERVICES DOCKER"
echo "=================================="
docker-compose ps

echo ""
echo "[2/6] LOGS LIVEKIT (DERNIÈRES 50 LIGNES)"
echo "========================================"
docker-compose logs --tail=50 livekit

echo ""
echo "[3/6] TEST CONNECTIVITÉ RÉSEAU DOCKER"
echo "===================================="
echo "Test résolution DNS livekit depuis api-backend:"
docker-compose exec api-backend nslookup livekit || echo "❌ Échec résolution DNS"

echo ""
echo "Test connectivité TCP port 7880:"
docker-compose exec api-backend nc -zv livekit 7880 || echo "❌ Échec connexion TCP 7880"

echo ""
echo "Test connectivité TCP port 7881 (RTC):"
docker-compose exec api-backend nc -zv livekit 7881 || echo "❌ Échec connexion TCP 7881"

echo ""
echo "[4/6] VÉRIFICATION PORTS UDP WEBRTC"
echo "=================================="
echo "Vérification exposition ports UDP 50000-50019:"
docker port $(docker-compose ps -q livekit) | grep udp || echo "❌ Aucun port UDP exposé"

echo ""
echo "[5/6] TEST DÉMARRAGE AGENT AVEC DIAGNOSTIC"
echo "========================================="
echo "Démarrage de l'agent avec logs de diagnostic..."
docker-compose up -d eloquence-agent
sleep 5
echo "Logs de l'agent (diagnostic réseau):"
docker-compose logs --tail=30 eloquence-agent

echo ""
echo "[6/6] RÉSUMÉ DIAGNOSTIC"
echo "===================="
echo "✅ Services actifs:"
docker-compose ps --filter "status=running" --format "table {{.Service}}\t{{.Status}}"

echo ""
echo "❌ Services en erreur:"
docker-compose ps --filter "status=exited" --format "table {{.Service}}\t{{.Status}}"

echo ""
echo "🔍 Recommandations basées sur le diagnostic:"
echo "1. Vérifier la configuration WebRTC dans livekit.yaml"
echo "2. Tester la connectivité UDP entre conteneurs"
echo "3. Examiner les logs LiveKit pour erreurs ICE/WebRTC"
echo "4. Valider la configuration réseau Docker"

echo ""
echo "========================================"
echo "DIAGNOSTIC TERMINÉ - $(date)"
echo "========================================"