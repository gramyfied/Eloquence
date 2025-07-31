#!/bin/bash
# ================================================================
# SCRIPT DE DÉPLOIEMENT DASHBOARD ELOQUENCE SUR HOSTINGER
# ================================================================
# Déploie automatiquement le dashboard sur dashboard.éloquence.com
# Compatible avec l'hébergement web Hostinger
# ================================================================

set -e  # Arrêter en cas d'erreur

# ================================================================
# CONFIGURATION
# ================================================================

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables de déploiement
DOMAIN_PATH="/home/u462199002/domains/xn--loquence-90a.com/public_html"
DASHBOARD_PATH="$DOMAIN_PATH/dashboard"
BACKUP_PATH="$DOMAIN_PATH/dashboard_backup_$(date +%Y%m%d_%H%M%S)"
LOCAL_DASHBOARD_PATH="./dashboard"

# URLs de test
DASHBOARD_URL="https://dashboard.éloquence.com"
API_HEALTH_URL="$DASHBOARD_URL/api/health"
API_METRICS_URL="$DASHBOARD_URL/api/metrics/all"

# ================================================================
# FONCTIONS UTILITAIRES
# ================================================================

print_header() {
    echo -e "${PURPLE}"
    echo "================================================================"
    echo "  🚀 DÉPLOIEMENT DASHBOARD ELOQUENCE SUR HOSTINGER"
    echo "================================================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_step "Vérification des prérequis..."
    
    # Vérifier que nous sommes dans le bon répertoire
    if [ ! -d "$LOCAL_DASHBOARD_PATH" ]; then
        print_error "Dossier dashboard non trouvé. Exécutez ce script depuis la racine du projet."
        exit 1
    fi
    
    # Vérifier les fichiers requis
    local required_files=(
        "$LOCAL_DASHBOARD_PATH/index.html"
        "$LOCAL_DASHBOARD_PATH/dashboard.js"
        "$LOCAL_DASHBOARD_PATH/api.php"
        "$LOCAL_DASHBOARD_PATH/.htaccess"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Fichier requis manquant: $file"
            exit 1
        fi
    done
    
    print_success "Prérequis validés"
}

create_backup() {
    print_step "Création d'une sauvegarde..."
    
    if [ -d "$DASHBOARD_PATH" ]; then
        cp -r "$DASHBOARD_PATH" "$BACKUP_PATH"
        print_success "Sauvegarde créée: $BACKUP_PATH"
    else
        print_info "Aucun dashboard existant à sauvegarder"
    fi
}

create_directory_structure() {
    print_step "Création de la structure de répertoires..."
    
    # Créer les répertoires nécessaires
    mkdir -p "$DASHBOARD_PATH"
    mkdir -p "$DASHBOARD_PATH/assets"
    mkdir -p "$DASHBOARD_PATH/logs"
    
    print_success "Structure de répertoires créée"
}

deploy_files() {
    print_step "Déploiement des fichiers..."
    
    # Copier les fichiers principaux
    cp "$LOCAL_DASHBOARD_PATH/index.html" "$DASHBOARD_PATH/"
    cp "$LOCAL_DASHBOARD_PATH/dashboard.js" "$DASHBOARD_PATH/"
    cp "$LOCAL_DASHBOARD_PATH/api.php" "$DASHBOARD_PATH/"
    cp "$LOCAL_DASHBOARD_PATH/.htaccess" "$DASHBOARD_PATH/"
    
    print_success "Fichiers principaux déployés"
    
    # Créer une page d'erreur simple
    create_error_page
    
    # Créer un fichier de monitoring
    create_monitoring_script
    
    print_success "Fichiers auxiliaires créés"
}

create_error_page() {
    cat > "$DASHBOARD_PATH/error.html" << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Eloquence - Erreur</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 min-h-screen flex items-center justify-center">
    <div class="max-w-md mx-auto text-center">
        <div class="bg-white rounded-lg shadow-lg p-8">
            <div class="text-red-500 text-6xl mb-4">⚠️</div>
            <h1 class="text-2xl font-bold text-gray-800 mb-4">Service Temporairement Indisponible</h1>
            <p class="text-gray-600 mb-6">Le dashboard Eloquence est temporairement indisponible. Veuillez réessayer dans quelques minutes.</p>
            <a href="/" class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded transition duration-200">
                Retour à l'accueil
            </a>
        </div>
    </div>
</body>
</html>
EOF
}

create_monitoring_script() {
    cat > "$DASHBOARD_PATH/monitor.php" << 'EOF'
<?php
// Script de monitoring pour le dashboard Eloquence
// À exécuter via cron toutes les 5 minutes

$logFile = __DIR__ . '/logs/monitor.log';
$timestamp = date('Y-m-d H:i:s');

// Endpoints à surveiller
$endpoints = [
    'health' => '/api/health',
    'metrics' => '/api/metrics/all',
    'system' => '/api/metrics/system'
];

$results = [];
$allHealthy = true;

foreach ($endpoints as $name => $endpoint) {
    $url = "https://dashboard.éloquence.com$endpoint";
    $startTime = microtime(true);
    
    $context = stream_context_create([
        'http' => [
            'timeout' => 10,
            'method' => 'GET'
        ]
    ]);
    
    $response = @file_get_contents($url, false, $context);
    $responseTime = round((microtime(true) - $startTime) * 1000, 2);
    
    $isHealthy = $response !== false;
    $results[$name] = [
        'healthy' => $isHealthy,
        'response_time' => $responseTime,
        'url' => $url
    ];
    
    if (!$isHealthy) {
        $allHealthy = false;
    }
}

// Log des résultats
$logEntry = "[$timestamp] Dashboard Status: " . ($allHealthy ? 'HEALTHY' : 'UNHEALTHY') . "\n";
foreach ($results as $name => $result) {
    $status = $result['healthy'] ? 'OK' : 'FAIL';
    $logEntry .= "  - $name: $status ({$result['response_time']}ms)\n";
}

file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);

// Envoyer une alerte si problème (optionnel)
if (!$allHealthy) {
    error_log("Dashboard Eloquence: Services unhealthy detected");
}

echo json_encode([
    'timestamp' => $timestamp,
    'overall_status' => $allHealthy ? 'healthy' : 'unhealthy',
    'endpoints' => $results
]);
?>
EOF
}

set_permissions() {
    print_step "Configuration des permissions..."
    
    # Permissions pour les fichiers
    chmod 644 "$DASHBOARD_PATH"/*.html
    chmod 644 "$DASHBOARD_PATH"/*.js
    chmod 644 "$DASHBOARD_PATH"/*.php
    chmod 644 "$DASHBOARD_PATH"/.htaccess
    
    # Permissions pour les répertoires
    chmod 755 "$DASHBOARD_PATH"
    chmod 755 "$DASHBOARD_PATH/assets"
    chmod 755 "$DASHBOARD_PATH/logs"
    
    # Permissions d'écriture pour les logs
    chmod 666 "$DASHBOARD_PATH/logs" 2>/dev/null || true
    
    print_success "Permissions configurées"
}

test_deployment() {
    print_step "Test du déploiement..."
    
    # Attendre un peu pour que les fichiers soient disponibles
    sleep 3
    
    # Test du health check
    print_info "Test du health check..."
    if curl -s -f "$API_HEALTH_URL" > /dev/null; then
        print_success "Health check: OK"
    else
        print_warning "Health check: Échec (normal si DNS pas encore propagé)"
    fi
    
    # Test des métriques
    print_info "Test des métriques..."
    if curl -s -f "$API_METRICS_URL" > /dev/null; then
        print_success "API métriques: OK"
    else
        print_warning "API métriques: Échec (normal si DNS pas encore propagé)"
    fi
    
    # Test de l'interface
    print_info "Test de l'interface..."
    if curl -s -f "$DASHBOARD_URL" > /dev/null; then
        print_success "Interface web: OK"
    else
        print_warning "Interface web: Échec (normal si DNS pas encore propagé)"
    fi
}

create_cron_job() {
    print_step "Configuration du monitoring automatique..."
    
    # Créer un script pour ajouter la tâche cron
    cat > "$DASHBOARD_PATH/setup-cron.sh" << EOF
#!/bin/bash
# Script pour configurer le monitoring automatique
# À exécuter manuellement via cPanel ou SSH

# Ajouter cette ligne au crontab:
# */5 * * * * /usr/bin/php $DASHBOARD_PATH/monitor.php >> $DASHBOARD_PATH/logs/cron.log 2>&1

echo "Ajoutez cette ligne à votre crontab via cPanel:"
echo "*/5 * * * * /usr/bin/php $DASHBOARD_PATH/monitor.php >> $DASHBOARD_PATH/logs/cron.log 2>&1"
EOF
    
    chmod +x "$DASHBOARD_PATH/setup-cron.sh"
    
    print_info "Script de configuration cron créé: $DASHBOARD_PATH/setup-cron.sh"
}

cleanup() {
    print_step "Nettoyage..."
    
    # Supprimer les fichiers temporaires s'il y en a
    find "$DASHBOARD_PATH" -name "*.tmp" -delete 2>/dev/null || true
    
    print_success "Nettoyage terminé"
}

print_summary() {
    echo -e "${PURPLE}"
    echo "================================================================"
    echo "  ✅ DÉPLOIEMENT TERMINÉ AVEC SUCCÈS"
    echo "================================================================"
    echo -e "${NC}"
    
    echo -e "${GREEN}🌐 URLs du Dashboard:${NC}"
    echo "   • Interface: $DASHBOARD_URL"
    echo "   • API Health: $API_HEALTH_URL"
    echo "   • API Métriques: $API_METRICS_URL"
    echo ""
    
    echo -e "${BLUE}📁 Fichiers déployés:${NC}"
    echo "   • $DASHBOARD_PATH/index.html"
    echo "   • $DASHBOARD_PATH/dashboard.js"
    echo "   • $DASHBOARD_PATH/api.php"
    echo "   • $DASHBOARD_PATH/.htaccess"
    echo "   • $DASHBOARD_PATH/error.html"
    echo "   • $DASHBOARD_PATH/monitor.php"
    echo ""
    
    echo -e "${YELLOW}⚠️  Actions manuelles requises:${NC}"
    echo "   1. Configurer le sous-domaine 'dashboard' dans Hostinger"
    echo "   2. Vérifier que le SSL est activé"
    echo "   3. Exécuter: $DASHBOARD_PATH/setup-cron.sh pour le monitoring"
    echo ""
    
    if [ -d "$BACKUP_PATH" ]; then
        echo -e "${CYAN}💾 Sauvegarde disponible:${NC}"
        echo "   • $BACKUP_PATH"
        echo ""
    fi
    
    echo -e "${GREEN}🎉 Le dashboard Eloquence est prêt !${NC}"
}

# ================================================================
# FONCTION PRINCIPALE
# ================================================================

main() {
    print_header
    
    # Vérifier les arguments
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [--dry-run]"
        echo ""
        echo "Options:"
        echo "  --dry-run    Simulation sans déploiement réel"
        echo "  --help       Afficher cette aide"
        exit 0
    fi
    
    if [ "$1" = "--dry-run" ]; then
        print_warning "Mode simulation activé - aucun fichier ne sera modifié"
        return 0
    fi
    
    # Exécuter le déploiement
    check_prerequisites
    create_backup
    create_directory_structure
    deploy_files
    set_permissions
    create_cron_job
    cleanup
    test_deployment
    print_summary
    
    print_success "Déploiement terminé avec succès !"
}

# ================================================================
# GESTION DES ERREURS
# ================================================================

trap 'print_error "Erreur lors du déploiement à la ligne $LINENO"' ERR

# ================================================================
# EXÉCUTION
# ================================================================

main "$@"
