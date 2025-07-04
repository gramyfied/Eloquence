# Guide de Résolution - Problème Environnement Flutter

## 🚨 Problème Identifié

**Erreur :** `flutter run` se termine avec le code de sortie 1
**Cause principale :** Git n'est pas installé ou pas dans le PATH système

## 🔧 Solutions Étape par Étape

### Étape 1 : Installation de Git

1. **Télécharger Git pour Windows :**
   - Allez sur : https://git-scm.com/download/win
   - Téléchargez la version 64-bit pour Windows

2. **Installer Git :**
   - Exécutez l'installateur téléchargé
   - **IMPORTANT :** Cochez "Add Git to PATH" pendant l'installation
   - Utilisez les paramètres par défaut pour le reste

3. **Vérifier l'installation :**
   ```cmd
   git --version
   ```

### Étape 2 : Vérification de Flutter

1. **Vérifier Flutter :**
   ```cmd
   flutter --version
   ```

2. **Si Flutter n'est pas reconnu :**
   - Vérifiez que Flutter est installé
   - Ajoutez Flutter au PATH système :
     - Variables d'environnement → PATH → Ajouter le chemin vers `flutter/bin`

### Étape 3 : Réparation du Projet Flutter

1. **Naviguer vers le projet :**
   ```cmd
   cd frontend/flutter_app
   ```

2. **Nettoyer le cache :**
   ```cmd
   flutter clean
   ```

3. **Récupérer les dépendances :**
   ```cmd
   flutter pub get
   ```

4. **Diagnostic complet :**
   ```cmd
   flutter doctor
   ```

### Étape 4 : Test de Fonctionnement

1. **Test de compilation :**
   ```cmd
   flutter build apk --debug
   ```

2. **Lancement de l'application :**
   ```cmd
   flutter run
   ```

## 🛠️ Script de Réparation Automatique

Exécutez le script de réparation automatique :

```cmd
scripts\fix_flutter_environment.bat
```

Ce script :
- ✅ Vérifie la présence de Git
- ✅ Vérifie la configuration Flutter
- ✅ Nettoie le cache Flutter
- ✅ Récupère les dépendances
- ✅ Effectue un diagnostic complet

## 🔍 Diagnostic des Problèmes Courants

### Problème : "Unable to find git in your PATH"
**Solution :** Installer Git et l'ajouter au PATH (voir Étape 1)

### Problème : "flutter command not found"
**Solution :** 
1. Vérifier l'installation de Flutter
2. Ajouter Flutter au PATH système
3. Redémarrer le terminal/VSCode

### Problème : "pub get failed"
**Solution :**
1. Vérifier la connexion internet
2. Exécuter `flutter clean` puis `flutter pub get`
3. Vérifier le fichier `pubspec.yaml`

### Problème : "Android toolchain issues"
**Solution :**
1. Installer Android Studio
2. Accepter les licences Android : `flutter doctor --android-licenses`
3. Configurer un émulateur Android

## 📱 Configuration pour le Développement Mobile

### Android
1. **Installer Android Studio**
2. **Configurer un émulateur :**
   ```cmd
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

3. **Ou connecter un appareil physique :**
   - Activer le mode développeur
   - Activer le débogage USB
   - Vérifier : `flutter devices`

### iOS (sur macOS uniquement)
1. **Installer Xcode**
2. **Configurer le simulateur iOS**

## 🚀 Commandes Utiles

```cmd
# Diagnostic complet
flutter doctor -v

# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device_id>

# Mode debug avec logs détaillés
flutter run --verbose

# Hot reload pendant le développement
# Appuyez sur 'r' dans le terminal pendant que l'app tourne

# Hot restart
# Appuyez sur 'R' dans le terminal
```

## 📞 Support Supplémentaire

Si les problèmes persistent :

1. **Vérifiez les logs détaillés :**
   ```cmd
   flutter run --verbose
   ```

2. **Nettoyage complet :**
   ```cmd
   flutter clean
   flutter pub cache repair
   flutter pub get
   ```

3. **Réinstallation Flutter :**
   - Télécharger la dernière version stable
   - Reconfigurer le PATH

## ✅ Checklist de Vérification

- [ ] Git installé et dans le PATH
- [ ] Flutter installé et dans le PATH
- [ ] `flutter doctor` sans erreurs critiques
- [ ] `flutter pub get` réussi
- [ ] Au moins un appareil/émulateur disponible
- [ ] `flutter run` fonctionne

---

**Note :** Après avoir installé Git, redémarrez complètement VSCode et votre terminal pour que les changements de PATH prennent effet.