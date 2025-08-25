# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev.ps1
$defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1
$ifIndex = $defaultRoute.IfIndex
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $ifIndex | Where-Object { $_.IPAddress -notmatch '^169\.254\.' } | Select-Object -First 1 -ExpandProperty IPAddress)
if (-not $ip) { Write-Error "Impossible de détecter l'IP locale"; exit 1 }

$envContent = @(
    "MOBILE_HOST_IP=$ip",
    "LIVEKIT_URL=ws://$ip:8780",
    "LIVEKIT_TOKEN_URL=http://$ip:8804",
    "LLM_SERVICE_URL=http://$ip:8000",
    "WHISPER_STT_URL=http://$ip:8001",
    "TTS_SERVICE_URL=http://$ip:5002",
    "ELOQUENCE_STREAMING_API_URL=http://$ip:8005",
    "EXERCISES_API_URL=http://$ip:8005",
    "VOSK_SERVICE_URL=http://$ip:2700",
    "MISTRAL_ENABLED=false",
    "RESET_HIVE_BOXES=false",
    "CLEAN_CORRUPTED_BOXES=false"
)

$envContent | Set-Content -Path .env -Encoding utf8
Write-Host "✅ .env généré avec IP: $ip"

