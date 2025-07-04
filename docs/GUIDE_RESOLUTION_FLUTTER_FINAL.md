# 🚨 Guide de Résolution - Problème Flutter "Code de sortie 1"

## Problème Identifié

**Erreur :** `flutter run` se termine avec le code de sortie 1  
**Cause principale :** Git n'est pas installé ou pas accessible dans le PATH

## 🎯 Solutions Disponibles (par ordre de recommandation)

### Solution 1 : Installation Automatique de Git + Réparation Complète ⭐ RECOMMANDÉE

```cmd
scripts\install_git_and_fix_flutter.bat
```

**Ce script :**
- ✅ Installe Git automatiquement
- ✅ Répare toutes les dépendances Flutter
- ✅ Active toutes les fonctionnalités (LiveKit, WebRTC, etc.)
- ✅ Solution complète et définitive

### Solution 2 : Installation Manuelle de Git

1. **Télécharger Git :**
   - Allez sur : https://git-scm.com/download/win
   - Téléchargez "64-bit Git for Windows Setup"

2. **Installer Git :**
   - Exécutez l'installateur
   - **IMPORTANT :** Cochez "Add Git to PATH" pendant l'installation
   - Utilisez les paramètres par défaut

3. **Redémarrer :**
   - Fermez complètement VSCode
   - Redémarrez votre terminal
   - Relancez VSCode

4. **Réparer Flutter :**
   ```cmd
   scripts\fix_flutter_dependencies.bat
   ```

### Solution 3 : Version Minimale (Temporaire)

Si vous ne pouvez pas installer Git immédiatement :

```cmd
scripts\fix_flutter_quick.bat
```

**Limitations :**
- ❌ Pas de LiveKit (audio en temps réel)
- ❌ Pas de WebRTC
- ❌ Fonctionnalités audio limitées
- ✅ Interface utilisateur fonctionnelle

## 🔧 Réparation Manuelle (Si les scripts échouent)

### Étape 1 : Vérification de Git
```cmd
git --version
```

### Étape 2 : Navigation vers le projet
```cmd
cd frontend/flutter_app
```

### Étape 3 : Nettoyage complet
```cmd
flutter clean
del pubspec.lock
rmdir /s /q .dart_tool
rmdir /s /q build
```

### Étape 4 : Utilisation du pubspec.yaml corrigé
```cmd
copy pubspec_fixed.yaml pubspec.yaml
```

### Étape 5 : Récupération des dépendances
```cmd
flutter pub get
```

### Étape 6 : Test
```cmd
flutter doctor
flutter run
```

## 📋 Checklist de Vérification

- [ ] Git installé et accessible (`git --version`)
- [ ] Flutter installé et accessible (`flutter --version`)
- [ ] Projet Flutter nettoyé (`flutter clean`)
- [ ] Dépendances récupérées (`flutter pub get`)
- [ ] Aucune erreur dans `flutter doctor`
- [ ] Au moins un appareil/émulateur disponible (`flutter devices`)

## 🚀 Test Final

Une fois la réparation terminée :

```cmd
cd frontend/flutter_app
flutter devices
flutter run
```

## 📁 Fichiers de Réparation Créés

- `scripts/install_git_and_fix_flutter.bat` - Solution complète automatique
- `scripts/fix_flutter_dependencies.bat` - Réparation avec Git installé
- `scripts/fix_flutter_quick.bat` - Solution temporaire sans Git
- `frontend/flutter_app/pubspec_fixed.yaml` - Dépendances corrigées
- `frontend/flutter_app/GUIDE_RESOLUTION_FLUTTER_ENVIRONMENT.md` - Guide détaillé

## 🆘 Support Supplémentaire

### Si Git refuse de s'installer :
1. Vérifiez les permissions administrateur
2. Désactivez temporairement l'antivirus
3. Utilisez la solution minimale temporaire

### Si Flutter pub get échoue encore :
1. Vérifiez votre connexion internet
2. Essayez : `flutter pub cache repair`
3. Utilisez la version minimale du pubspec.yaml

### Si flutter run échoue après réparation :
1. Vérifiez qu'un appareil est connecté : `flutter devices`
2. Essayez avec un émulateur Android
3. Consultez les logs détaillés : `flutter run --verbose`

## 🎯 Résumé Rapide

**Pour une solution immédiate :**
1. Exécutez : `scripts\install_git_and_fix_flutter.bat`
2. Suivez les instructions à l'écran
3. Redémarrez VSCode si nécessaire
4. Testez avec : `flutter run`

**Le problème sera résolu une fois Git installé et les dépendances Flutter corrigées.**