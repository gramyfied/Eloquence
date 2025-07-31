# 📱 GUIDE DE DÉMARRAGE MOBILE - ELOQUENCE

## 📍 LOCALISATION DU FRONTEND

### **Chemin principal du frontend Flutter :**
```
/home/ubuntu/.vscode-server/data/User/globalStorage/saoudrizwan.claude-dev/settings/frontend/flutter_app/
```

### **Lien GitHub du projet :**
```
https://github.com/gramyfied/Eloquence.git
```

### **Structure des dossiers :**
```
frontend/
├── flutter_app/                    # 📱 Application mobile Flutter
│   ├── lib/                       # Code source Dart
│   │   ├── config/               # Configuration API
│   │   ├── services/             # Services backend
│   │   └── main.dart             # Point d'entrée
│   ├── android/                  # Configuration Android
│   ├── web/                      # Version web
│   ├── windows/                  # Version Windows
│   ├── pubspec.yaml              # Dépendances Flutter
│   └── README.md                 # Documentation
└── web/                          # Version web alternative
```

---

## 🚀 DÉMARRAGE SUR TÉLÉPHONE MOBILE

### **Méthode 1 : Développement Flutter (Recommandée)**

#### Étape 1 : Cloner le projet
```bash
git clone https://github.com/gramyfied/Eloquence.git
cd Eloquence/frontend/flutter_app
```

#### Étape 2 : Installer Flutter (si pas déjà fait)
```bash
# Télécharger Flutter SDK
# https://docs.flutter.dev/get-started/install

# Vérifier l'installation
flutter doctor
```

#### Étape 3 : Installer les dépendances
```bash
flutter pub get
```

#### Étape 4 : Connecter votre téléphone
```bash
# Android : Activer le mode développeur
# Paramètres > À propos du téléphone > Appuyer 7 fois sur "Numéro de build"
# Paramètres > Options pour les développeurs > Débogage USB

# iOS : Connecter via Xcode
# Faire confiance à l'ordinateur sur l'iPhone

# Vérifier la connexion
flutter devices
```

#### Étape 5 : Lancer l'application
```bash
# Démarrer en mode debug
flutter run

# Ou spécifier un device
flutter run -d <device_id>
```

---

## 📋 CONFIGURATION BACKEND

### **Backend opérationnel :**
- ✅ **Serveur** : http://51.159.110.4:8000
- ✅ **Health Check** : OK
- ✅ **Exercices** : 4 exercices disponibles
- ✅ **Sessions** : Endpoints fonctionnels

### **Configuration automatique :**
Le fichier `lib/config/api_config.dart` est déjà configuré pour pointer vers le bon serveur en production.

---

## 🔧 DÉPANNAGE

### **Problèmes courants :**

#### 1. Flutter non reconnu
```bash
# Ajouter Flutter au PATH
export PATH="$PATH:/path/to/flutter/bin"
```

#### 2. Device non détecté
```bash
# Android
adb devices

# iOS
xcrun simctl list devices
```

#### 3. Erreurs de dépendances
```bash
flutter clean
flutter pub get
```

#### 4. Problèmes de permissions
```bash
# Android : Vérifier les permissions dans android/app/src/main/AndroidManifest.xml
# iOS : Vérifier Info.plist
```

---

## 📱 ALTERNATIVES DE DÉPLOIEMENT

### **Méthode 2 : APK Android (Plus simple)**
```bash
# Construire l'APK
flutter build apk --release

# L'APK sera dans : build/app/outputs/flutter-apk/app-release.apk
# Transférer sur le téléphone et installer
```

### **Méthode 3 : Version Web Mobile**
```bash
# Construire pour le web
flutter build web

# Servir localement
flutter run -d web-server --web-port 8080
# Accéder via http://localhost:8080 sur le téléphone
```

---

## 🎯 ÉTAPES RAPIDES

### **Démarrage express (5 minutes) :**
1. `git clone https://github.com/gramyfied/Eloquence.git`
2. `cd Eloquence/frontend/flutter_app`
3. `flutter pub get`
4. Connecter le téléphone en USB
5. `flutter run`

### **Vérification backend :**
```bash
# Tester que le backend répond
curl http://51.159.110.4:8000/health
curl http://51.159.110.4:8000/api/exercises
```

---

## 📞 SUPPORT

### **Logs utiles :**
```bash
# Logs Flutter
flutter logs

# Logs détaillés
flutter run --verbose
```

### **Fichiers de configuration importants :**
- `frontend/flutter_app/lib/config/api_config.dart` - Configuration serveur
- `frontend/flutter_app/pubspec.yaml` - Dépendances
- `frontend/flutter_app/lib/main.dart` - Point d'entrée

---

## ✅ STATUS ACTUEL

- ✅ **Backend opérationnel** sur http://51.159.110.4:8000
- ✅ **Endpoints créés** et fonctionnels
- ✅ **Configuration frontend** corrigée
- ✅ **Prêt pour démarrage mobile**

**Le système est prêt pour être lancé sur votre téléphone !**
