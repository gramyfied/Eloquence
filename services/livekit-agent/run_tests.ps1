# Script PowerShell pour lancer les tests TTS de conversation IA
# Usage: .\run_tests.ps1 [option]

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "🧪 TESTS TTS CONVERSATIONS IA ELOQUENCE" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Cyan

# Activation de l'environnement virtuel si existant
if (Test-Path "venv") {
    & ".\venv\Scripts\Activate.ps1"
}

# Menu de sélection
if ($args.Count -eq 0) {
    Write-Host ""
    Write-Host "Choisissez le type de test :" -ForegroundColor Green
    Write-Host "1) Validation rapide (30 secondes)" -ForegroundColor White
    Write-Host "2) Test simple (2 minutes)" -ForegroundColor White
    Write-Host "3) Test complet d'un exercice (5 minutes)" -ForegroundColor White
    Write-Host "4) Test complet tous exercices (15 minutes)" -ForegroundColor White
    Write-Host "5) Test mode debug avec logs détaillés" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "Votre choix (1-5)"
} else {
    $choice = $args[0]
}

switch ($choice) {
    "1" {
        Write-Host "🔍 Lancement validation rapide..." -ForegroundColor Yellow
        python test_tts_simple.py --mode validate
    }
    "2" {
        Write-Host "⚡ Lancement test simple..." -ForegroundColor Yellow
        python test_tts_simple.py --mode quick
    }
    "3" {
        Write-Host "🎯 Test complet d'un exercice" -ForegroundColor Yellow
        Write-Host "Exercices disponibles:" -ForegroundColor Cyan
        Write-Host "  - confidence_boost"
        Write-Host "  - tribunal_idees_impossibles"
        Write-Host "  - studio_situations_pro"
        $exercise = Read-Host "Nom de l'exercice"
        python test_conversation_tts.py --exercise $exercise
    }
    "4" {
        Write-Host "🚀 Lancement test complet tous exercices..." -ForegroundColor Yellow
        python test_conversation_tts.py --exercise all
    }
    "5" {
        Write-Host "🐛 Mode debug activé..." -ForegroundColor Yellow
        python test_conversation_tts.py --exercise all --verbose
    }
    default {
        Write-Host "❌ Choix invalide" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "✅ Tests terminés" -ForegroundColor Green
Write-Host "📁 Résultats dans: test_results/" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan