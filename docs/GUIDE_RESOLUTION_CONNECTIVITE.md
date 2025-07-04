# Guide de Résolution des Problèmes de Connectivité

## Problème Identifié
L'application Flutter ne peut pas se connecter aux services backend depuis l'appareil mobile, avec des erreurs de timeout sur les ports 5002 (TTS) et 8000 (API).

## Diagnostic Effectué

### ✅ Services Fonctionnels
- Tous les conteneurs Docker sont en cours d'exécution
- Les services répondent correctement en local :
  - API Backend (port 8000) : ✅ http://192.168.1.44:8000/health
  - TTS Service (port 5002) : ✅ http://192.168.1.44:5002/health
  - Whisper STT (port 8001) : ✅ En cours d'exécution
  - LiveKit (ports 7880-7881) : ✅ En cours d'exécution

### ✅ Configuration Réseau
- Adresse IP du serveur : 192.168.1.44
- Ports exposés par Docker : 5002, 8000, 8001, 7880-7881
- Connectivité réseau : ✅ (ping réussi)

### ❌ Problème Identifié : Firewall Windows
Le firewall Windows bloque les connexions entrantes sur les ports des services.

## Solution de Déploiement

### Étape 1 : Configuration du Firewall Windows

**Option A : Via PowerShell (Recommandé)**
1. Ouvrir PowerShell en tant qu'administrateur
2. Naviguer vers le répertoire du projet
3. Exécuter le script de configuration :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\configure_firewall.ps1
```

**Option B : Via l'interface graphique**
1. Ouvrir "Pare-feu Windows Defender avec sécurité avancée"
2. Cliquer sur "Règles de trafic entrant" → "Nouvelle règle"
3. Créer des règles pour chaque port :
   - Port 5002 (TTS Service)
   - Port 8000 (API Service)
   - Port 8001 (Whisper STT)
   - Ports 7880-7881 (LiveKit)

### Étape 2 : Vérification de la Connectivité

Après configuration du firewall, tester depuis l'appareil mobile :

```bash
# Test API Backend
curl http://192.168.1.44:8000/health

# Test TTS Service
curl http://192.168.1.44:5002/health
```

### Étape 3 : Configuration Alternative (si nécessaire)

Si le problème persiste, vérifier :

1. **Antivirus tiers** : Certains antivirus bloquent les connexions réseau
2. **Configuration du routeur** : Isolation des clients WiFi
3. **Réseau mobile vs WiFi** : S'assurer que l'appareil est sur le même réseau

## Commandes de Diagnostic

### Vérifier les ports en écoute
```cmd
netstat -an | findstr "5002\|8000\|8001\|7880\|7881"
```

### Vérifier les conteneurs Docker
```cmd
docker ps
```

### Tester la connectivité réseau
```cmd
ping 192.168.1.44
```

### Vérifier les règles de firewall
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Eloquence*"}
```

## Rollback (si nécessaire)

Pour supprimer les règles de firewall :
```powershell
Remove-NetFirewallRule -DisplayName "Eloquence TTS Service"
Remove-NetFirewallRule -DisplayName "Eloquence API Service"
Remove-NetFirewallRule -DisplayName "Eloquence Whisper STT Service"
Remove-NetFirewallRule -DisplayName "Eloquence LiveKit Service"
```

## Monitoring Post-Déploiement

### Logs à surveiller
- Logs des conteneurs Docker : `docker logs [container_name]`
- Logs de l'application Flutter
- Logs du firewall Windows (Observateur d'événements)

### Métriques de performance
- Latence réseau entre mobile et serveur
- Temps de réponse des services
- Utilisation mémoire des conteneurs (particulièrement eloquence-agent-v1)

## Sécurité

### Bonnes pratiques appliquées
- ✅ Règles firewall spécifiques par port
- ✅ Accès limité au réseau local uniquement
- ✅ Pas d'exposition sur Internet public
- ✅ Utilisation de Docker pour l'isolation des services

### Recommandations supplémentaires
- Configurer un VPN pour l'accès distant si nécessaire
- Mettre en place une surveillance des connexions
- Effectuer des audits de sécurité réguliers

## Troubleshooting Avancé

### Si les timeouts persistent
1. Augmenter les timeouts dans l'application Flutter
2. Vérifier la configuration DNS
3. Tester avec l'adresse IP directement
4. Vérifier les logs détaillés des services

### Performance réseau
- Utiliser `iperf3` pour tester la bande passante
- Monitorer la latence avec `ping -t`
- Vérifier la qualité du signal WiFi