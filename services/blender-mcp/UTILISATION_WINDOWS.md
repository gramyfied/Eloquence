# 🎯 Guide d'utilisation rapide - Windows

## 🚀 Lancement rapide

### Option 1: Script batch (recommandé) - PowerShell
```powershell
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
.\preview.bat "Roulette des virelangues magiques"
```

### Option 2: Python direct
```powershell
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
python preview_simple.py "Cube orange qui rebondit 3 fois"
```

### Option 3: Mode interactif
```powershell
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
.\preview.bat interactive
```

### Option 4: CMD classique
```cmd
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
preview.bat "Roulette des virelangues magiques"
```

## 📝 Exemples de prompts testés

### ✅ Virelangues Eloquence
```powershell
.\preview.bat "Roulette des virelangues magiques"
.\preview.bat "Roulette virelangue française"
```

### ✅ Animations classiques
```powershell
.\preview.bat "Cube orange qui rebondit 5 fois"
.\preview.bat "Roulette casino avec 6 segments"
.\preview.bat "Logo ELOQUENCE doré qui tourne"
```

## 🔧 En cas de problème

### Erreur "n'est pas reconnu"
- Vérifiez que vous êtes dans le bon répertoire : `services\blender-mcp`
- **PowerShell** : Utilisez `.\preview.bat` (avec le point-slash)
- **CMD** : Utilisez `preview.bat` directement

### Erreur Python
- Vérifiez que Python est installé : `python --version`
- Installez les dépendances : `pip install fastmcp`

### Erreur d'encodage
- Le script `preview_simple.py` est optimisé pour Windows
- Utilise l'encodage UTF-8 avec fallback ASCII

## 🎮 Test rapide
```powershell
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
.\preview.bat "Cube orange qui rebondit 3 fois"
```

✅ **TESTÉ AVEC SUCCÈS** : Cette commande génère un cube animé pour vérifier que tout fonctionne.

## 🏆 Résultat validé
L'exemple `.\preview.bat "Roulette des virelangues magiques"` produit :
- Type détecté : `roulette`
- Paramètres : `{'segments': 6, 'colors': None}`
- Code généré : `2403 caractères`
- Extrait du code Python Blender affiché