# Script pour filtrer les logs audio LiveKit Flutter
# Usage: flutter logs | powershell -File debug_audio_logs.ps1

$input | ForEach-Object {
    if ($_ -match "🔍|🎵|🔊|🔉|Audio publication|track audio|participant|LiveKit|NOUVEAU track|démarré automatiquement") {
        Write-Host $_ -ForegroundColor Green
    }
}