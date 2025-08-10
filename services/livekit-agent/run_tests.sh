#!/bin/bash

# Script pour lancer les tests TTS de conversation IA
# Usage: ./run_tests.sh [option]

echo "======================================="
echo "🧪 TESTS TTS CONVERSATIONS IA ELOQUENCE"
echo "======================================="

# Activation de l'environnement virtuel si existant
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Menu de sélection
if [ $# -eq 0 ]; then
    echo ""
    echo "Choisissez le type de test :"
    echo "1) Validation rapide (30 secondes)"
    echo "2) Test simple (2 minutes)"
    echo "3) Test complet d'un exercice (5 minutes)"
    echo "4) Test complet tous exercices (15 minutes)"
    echo "5) Test mode debug avec logs détaillés"
    echo ""
    read -p "Votre choix (1-5): " choice
else
    choice=$1
fi

case $choice in
    1)
        echo "🔍 Lancement validation rapide..."
        python test_tts_simple.py --mode validate
        ;;
    2)
        echo "⚡ Lancement test simple..."
        python test_tts_simple.py --mode quick
        ;;
    3)
        echo "🎯 Test complet d'un exercice"
        echo "Exercices disponibles:"
        echo "  - confidence_boost"
        echo "  - tribunal_idees_impossibles" 
        echo "  - studio_situations_pro"
        read -p "Nom de l'exercice: " exercise
        python test_conversation_tts.py --exercise $exercise
        ;;
    4)
        echo "🚀 Lancement test complet tous exercices..."
        python test_conversation_tts.py --exercise all
        ;;
    5)
        echo "🐛 Mode debug activé..."
        python test_conversation_tts.py --exercise all --verbose
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "======================================="
echo "✅ Tests terminés"
echo "📁 Résultats dans: test_results/"
echo "======================================="