# Script de visualisation des logs Eloquence
param(
    [string]$Service = ""
)

if ($Service -eq "") {
    Write-Host "📋 Logs de tous les services:" -ForegroundColor Cyan
    docker-compose -f docker-compose-new.yml logs -f
} else {
    Write-Host "📋 Logs du service ${Service}:" -ForegroundColor Cyan
    docker-compose -f docker-compose-new.yml logs -f $Service
}
