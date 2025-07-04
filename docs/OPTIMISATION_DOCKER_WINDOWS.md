# 🚀 Guide d'optimisation Docker sur Windows pour le développement

## 📋 Configuration Docker Desktop recommandée

### 1. Ressources système
```
Mémoire (RAM): 8-12 GB (selon votre système)
CPU: 4-6 cœurs
Swap: 2 GB
Disk image size: 100 GB minimum
```

### 2. Fonctionnalités à activer
- ✅ **Use WSL 2 based engine** (OBLIGATOIRE)
- ✅ **Enable integration with my default WSL distro**
- ✅ **Enable integration with additional distros** (Ubuntu, etc.)
- ✅ **Use Docker Compose V2**

### 3. Fonctionnalités à désactiver (pour les performances)
- ❌ **Send usage statistics**
- ❌ **Show Docker Desktop system tray icon**
- ❌ **Start Docker Desktop when you log in** (optionnel)

## 🛡️ Configuration antivirus (CRITIQUE)

### Windows Defender
Ajoutez ces exclusions dans Windows Defender :

```
Dossiers à exclure :
- C:\Users\[VotreNom]\AppData\Local\Docker
- \\wsl$\docker-desktop
- \\wsl$\docker-desktop-data
- Votre répertoire de projet WSL : \\wsl$\Ubuntu\home\[user]\projects\
- C:\Program Files\Docker

Processus à exclure :
- docker.exe
- dockerd.exe
- docker-compose.exe
- wsl.exe
- wslhost.exe
```

### Autres antivirus (Avast, Norton, etc.)
Ajoutez les mêmes exclusions dans votre antivirus tiers.

## ⚡ Optimisations WSL 2

### 1. Configuration .wslconfig
Créez/modifiez le fichier `C:\Users\[VotreNom]\.wslconfig` :

```ini
[wsl2]
# Limite la mémoire WSL à 8GB (ajustez selon votre RAM)
memory=8GB

# Limite les processeurs à 4 (ajustez selon vos cœurs)
processors=4

# Désactive le swap pour de meilleures performances
swap=0

# Désactive la pagination pour de meilleures performances I/O
pageReporting=false

# Active les fonctionnalités réseau avancées
networkingMode=mirrored
```

### 2. Redémarrer WSL après modification
```cmd
wsl --shutdown
```

## 🔧 Optimisations système Windows

### 1. Mode haute performance
```cmd
# Activer le mode haute performance
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

### 2. Désactiver l'indexation Windows sur les dossiers Docker
- Ouvrir l'Explorateur de fichiers
- Clic droit sur `C:\Users\[VotreNom]\AppData\Local\Docker`
- Propriétés → Décocher "Autoriser l'indexation du contenu"

### 3. Optimiser le stockage
- Utiliser un SSD pour Docker Desktop si possible
- Déplacer le répertoire Docker vers un SSD rapide

## 📊 Monitoring des performances

### Commandes utiles pour surveiller
```bash
# Utilisation des ressources Docker
docker system df

# Statistiques des conteneurs
docker stats

# Informations système WSL
wsl --status
wsl --list --verbose

# Espace disque WSL
wsl -d docker-desktop df -h
```

### Nettoyage régulier
```bash
# Nettoyer les images inutilisées
docker system prune -af --volumes

# Nettoyer les builds cache
docker builder prune -af
```

## 🎯 Résultats attendus

Avec ces optimisations, vous devriez observer :

- ⚡ **Temps de build réduit de 60-80%**
- 🔄 **Hot-reload quasi instantané (< 1 seconde)**
- 💾 **Utilisation mémoire optimisée**
- 🚀 **Démarrage des conteneurs 3x plus rapide**

## 🔍 Diagnostic des performances

### Script de test des performances
```bash
# Tester la vitesse d'écriture dans WSL
time dd if=/dev/zero of=test.tmp bs=1M count=1000
rm test.tmp

# Tester la vitesse d'écriture sur Windows
time dd if=/dev/zero of=/mnt/c/temp/test.tmp bs=1M count=1000
rm /mnt/c/temp/test.tmp
```

La différence devrait être significative (WSL 2 beaucoup plus rapide).

## 🆘 Dépannage

### Problème : Build lent
1. Vérifiez que vous êtes dans WSL 2
2. Vérifiez les exclusions antivirus
3. Augmentez la mémoire allouée à WSL

### Problème : Hot-reload ne fonctionne pas
1. Vérifiez les bind mounts dans docker-compose
2. Assurez-vous que le polling est activé
3. Vérifiez les permissions de fichiers

### Problème : Conteneurs qui crashent
1. Augmentez la mémoire Docker Desktop
2. Vérifiez les logs : `docker compose logs`
3. Redémarrez Docker Desktop

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs Docker Desktop
2. Consultez `docker system events`
3. Redémarrez WSL : `wsl --shutdown`
4. Redémarrez Docker Desktop