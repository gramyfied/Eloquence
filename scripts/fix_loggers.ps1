# Script pour corriger les références au logger dans toute l'application

$files = Get-ChildItem -Path "frontend/flutter_app/lib/" -Recurse -Include "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Remplacer les imports
    $content = $content -replace "import 'package:logger/logger.dart';", "import 'package:eloquence/core/utils/unified_logger_service.dart';"
    $content = $content -replace "import '../../../../core/utils/logger.dart';", "import 'package:eloquence/core/utils/unified_logger_service.dart';"
    $content = $content -replace "import '../utils/logger_service.dart';", "import 'package:eloquence/core/utils/unified_logger_service.dart';"
    $content = $content -replace "import 'package:eloquence_2_0/core/utils/logger_service.dart';", "import 'package:eloquence/core/utils/unified_logger_service.dart';"
    $content = $content -replace "import 'package:eloquence_2_0/core/utils/logger.dart';", "import 'package:eloquence/core/utils/unified_logger_service.dart';"

    # Remplacer les appels de méthodes statiques
    $content = $content -replace "AppLogger.debug", "UnifiedLoggerService.debug"
    $content = $content -replace "AppLogger.info", "UnifiedLoggerService.info"
    $content = $content -replace "AppLogger.warning", "UnifiedLoggerService.warning"
    $content = $content -replace "AppLogger.error", "UnifiedLoggerService.error"
    $content = $content -replace "AppLogger.fatal", "UnifiedLoggerService.fatal"

    # Remplacer les appels de l'ancien service
    $content = $content -replace "_UnifiedLoggerService.info", "UnifiedLoggerService.info"
    $content = $content -replace "_UnifiedLoggerService.debug", "UnifiedLoggerService.debug"
    $content = $content -replace "_UnifiedLoggerService.warning", "UnifiedLoggerService.warning"
    $content = $content -replace "_UnifiedLoggerService.error", "UnifiedLoggerService.error"

    # Remplacer les instances de logger
    $content = $content -replace "final _logger = Logger\(\);", ""
    $content = $content -replace "static final Logger _logger = Logger\([^;]+\);", ""
    $content = $content -replace "logger.d", "unifiedLogger.d"
    $content = $content -replace "logger.i", "unifiedLogger.i"
    $content = $content -replace "logger.w", "unifiedLogger.w"
    $content = $content -replace "logger.e", "unifiedLogger.e"
    $content = $content -replace "logger.v", "unifiedLogger.v"
    $content = $content -replace "logger.performance", "unifiedLogger.performance"
    $content = $content -replace "logger.dataSize", "unifiedLogger.dataSize"
    $content = $content -replace "logger.networkLatency", "unifiedLogger.networkLatency"
    $content = $content -replace "logger.webSocket", "unifiedLogger.webSocket"

    Set-Content -Path $file.FullName -Value $content
}

Write-Host "Correction des loggers terminée."
