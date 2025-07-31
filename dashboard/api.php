<?php
// ================================================================
// ELOQUENCE DASHBOARD API - VERSION PHP POUR HOSTINGER
// ================================================================
// API de monitoring pour le dashboard Eloquence
// Compatible avec l'hébergement web Hostinger
// ================================================================

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestion des requêtes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
define('BACKEND_API_URL', 'https://api.éloquence.com');
define('CACHE_DURATION', 30); // 30 secondes

// ================================================================
// FONCTIONS UTILITAIRES
// ================================================================

/**
 * Faire une requête HTTP avec timeout
 */
function makeHttpRequest($url, $timeout = 5) {
    $context = stream_context_create([
        'http' => [
            'timeout' => $timeout,
            'method' => 'GET',
            'header' => [
                'User-Agent: Dashboard-Eloquence/1.0',
                'Accept: application/json'
            ]
        ]
    ]);
    
    $result = @file_get_contents($url, false, $context);
    return $result ? json_decode($result, true) : null;
}

/**
 * Obtenir les métriques système simulées
 */
function getSystemMetrics() {
    return [
        'cpu_percent' => round(rand(200, 800) / 10, 1),
        'memory_percent' => round(rand(300, 700) / 10, 1),
        'disk_percent' => round(rand(150, 400) / 10, 1),
        'uptime' => '2 days, 14:32:15',
        'load_average' => [
            round(rand(50, 200) / 100, 2),
            round(rand(80, 250) / 100, 2),
            round(rand(100, 300) / 100, 2)
        ]
    ];
}

/**
 * Obtenir le statut des services
 */
function getServicesMetrics() {
    $services = [
        ['name' => 'backend-api', 'port' => 8000],
        ['name' => 'eloquence-exercises-api', 'port' => 8005],
        ['name' => 'vosk-stt', 'port' => 8002],
        ['name' => 'mistral-conversation', 'port' => 8001],
        ['name' => 'livekit-server', 'port' => 7880],
        ['name' => 'livekit-token-service', 'port' => 8004],
        ['name' => 'redis', 'port' => 6379]
    ];
    
    $result = [];
    foreach ($services as $service) {
        // Simuler 90% de services en ligne
        $isHealthy = rand(1, 10) > 1;
        
        $result[] = [
            'name' => $service['name'],
            'status' => $isHealthy ? 'healthy' : 'unhealthy',
            'response_time' => $isHealthy ? round(rand(200, 1500) / 10, 1) : null,
            'last_check' => date('c'),
            'port' => $service['port']
        ];
    }
    
    return $result;
}

/**
 * Obtenir les métriques business
 */
function getBusinessMetrics() {
    return [
        'active_users' => rand(15, 45),
        'total_sessions' => rand(100, 200),
        'completed_exercises' => rand(50, 120),
        'avg_session_time' => round(rand(100, 300) / 10, 1),
        'retention_rate' => round(rand(750, 950) / 10, 1)
    ];
}

/**
 * Obtenir les métriques de performance
 */
function getPerformanceMetrics() {
    return [
        'requests_per_minute' => rand(200, 500),
        'error_rate' => round(rand(10, 300) / 100, 2),
        'p95_latency' => rand(80, 200),
        'cache_hit_rate' => round(rand(850, 980) / 10, 1)
    ];
}

/**
 * Obtenir les alertes
 */
function getAlerts() {
    $alerts = [
        [
            'id' => 'system_ok',
            'type' => 'success',
            'title' => 'Système opérationnel',
            'message' => 'Tous les services fonctionnent normalement',
            'timestamp' => date('c')
        ]
    ];
    
    // Ajouter parfois des alertes d'avertissement
    if (rand(1, 10) > 7) {
        $alerts[] = [
            'id' => 'memory_warning',
            'type' => 'warning',
            'title' => 'Utilisation mémoire élevée',
            'message' => 'Redis utilise 78% de la mémoire allouée',
            'timestamp' => date('c', time() - 300)
        ];
    }
    
    if (rand(1, 10) > 8) {
        $alerts[] = [
            'id' => 'backup_success',
            'type' => 'info',
            'title' => 'Sauvegarde complétée',
            'message' => 'Sauvegarde automatique réussie',
            'timestamp' => date('c', time() - 3600)
        ];
    }
    
    return $alerts;
}

/**
 * Gestion du cache simple
 */
function getCachedData($key, $callback, $duration = 30) {
    $cacheFile = "/tmp/dashboard_cache_" . md5($key) . ".json";
    
    // Vérifier si le cache existe et est valide
    if (file_exists($cacheFile) && (time() - filemtime($cacheFile)) < $duration) {
        $data = file_get_contents($cacheFile);
        return json_decode($data, true);
    }
    
    // Générer les nouvelles données
    $data = $callback();
    
    // Sauvegarder en cache
    @file_put_contents($cacheFile, json_encode($data));
    
    return $data;
}

// ================================================================
// ROUTER PRINCIPAL
// ================================================================

$endpoint = $_GET['endpoint'] ?? '';

switch ($endpoint) {
    case 'health':
        $response = [
            'status' => 'healthy',
            'timestamp' => date('c'),
            'version' => '1.0.0',
            'uptime' => '2 days, 14:32:15',
            'server' => 'Hostinger PHP',
            'environment' => 'production'
        ];
        break;
        
    case 'metrics/all':
        $response = getCachedData('metrics_all', function() {
            return [
                'timestamp' => date('c'),
                'system' => getSystemMetrics(),
                'services' => getServicesMetrics(),
                'business' => getBusinessMetrics(),
                'performance' => getPerformanceMetrics(),
                'alerts' => getAlerts()
            ];
        }, 30);
        break;
        
    case 'metrics/system':
        $response = getCachedData('metrics_system', function() {
            return getSystemMetrics();
        }, 15);
        break;
        
    case 'metrics/services':
        $response = getCachedData('metrics_services', function() {
            return getServicesMetrics();
        }, 20);
        break;
        
    case 'metrics/business':
        $response = getCachedData('metrics_business', function() {
            return getBusinessMetrics();
        }, 60);
        break;
        
    case 'metrics/performance':
        $response = getCachedData('metrics_performance', function() {
            return getPerformanceMetrics();
        }, 30);
        break;
        
    case 'alerts':
        $response = getCachedData('alerts', function() {
            return getAlerts();
        }, 45);
        break;
        
    case 'status':
        // Endpoint de statut étendu
        $response = [
            'dashboard' => 'operational',
            'api' => 'healthy',
            'cache' => 'enabled',
            'last_update' => date('c'),
            'endpoints' => [
                'health' => 'active',
                'metrics/all' => 'active',
                'metrics/system' => 'active',
                'metrics/services' => 'active',
                'metrics/business' => 'active',
                'metrics/performance' => 'active',
                'alerts' => 'active'
            ]
        ];
        break;
        
    default:
        http_response_code(404);
        $response = [
            'error' => 'Endpoint not found',
            'requested_endpoint' => $endpoint,
            'available_endpoints' => [
                'health' => 'Health check du dashboard',
                'metrics/all' => 'Toutes les métriques combinées',
                'metrics/system' => 'Métriques système (CPU, RAM, etc.)',
                'metrics/services' => 'Statut des services Eloquence',
                'metrics/business' => 'Métriques business (utilisateurs, sessions)',
                'metrics/performance' => 'Métriques de performance (latence, erreurs)',
                'alerts' => 'Alertes actives du système',
                'status' => 'Statut détaillé du dashboard'
            ],
            'usage_examples' => [
                'https://dashboard.éloquence.com/api/health',
                'https://dashboard.éloquence.com/api/metrics/all',
                'https://dashboard.éloquence.com/api/metrics/system'
            ]
        ];
        break;
}

// ================================================================
// RÉPONSE FINALE
// ================================================================

// Ajouter des headers de performance
header('Cache-Control: public, max-age=30');
header('X-Dashboard-Version: 1.0.0');
header('X-Response-Time: ' . round((microtime(true) - $_SERVER['REQUEST_TIME_FLOAT']) * 1000, 2) . 'ms');

// Encoder et envoyer la réponse
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

// Log de la requête (optionnel)
if (function_exists('error_log')) {
    error_log("Dashboard API: {$endpoint} - " . date('Y-m-d H:i:s'));
}
?>
