# Script pour pousser le code vers un nouveau repository
# Usage: .\push_to_new_repo.ps1 "https://github.com/votre-username/eloquence-tts-fix-2025.git"

param(
    [Parameter(Mandatory=$true)]
    [string]$NewRepoUrl
)

Write-Host "🚀 Configuration du nouveau repository pour la réparation TTS..." -ForegroundColor Green

# Vérifier que nous sommes sur la bonne branche
$currentBranch = git branch --show-current
if ($currentBranch -ne "fix/tts-openai-confidence-boost") {
    Write-Host "❌ Erreur: Vous devez être sur la branche 'fix/tts-openai-confidence-boost'" -ForegroundColor Red
    Write-Host "Exécutez: git checkout fix/tts-openai-confidence-boost" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Branche actuelle: $currentBranch" -ForegroundColor Green

# Ajouter le nouveau remote
Write-Host "🔗 Ajout du nouveau remote..." -ForegroundColor Yellow
git remote add tts-fix $NewRepoUrl

# Pousser vers le nouveau repository
Write-Host "📤 Push vers le nouveau repository..." -ForegroundColor Yellow
git push -u tts-fix fix/tts-openai-confidence-boost

Write-Host "✅ Code poussé avec succès vers: $NewRepoUrl" -ForegroundColor Green
Write-Host "🌐 Ouvrez cette URL dans votre navigateur pour voir le repository" -ForegroundColor Cyan

# Afficher les remotes
Write-Host "📋 Remotes configurés:" -ForegroundColor Yellow
git remote -v
