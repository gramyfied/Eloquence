# 🚀 Guide de Démarrage Rapide - Blender MCP dans RooCode

## ⚡ Test Rapide (5 minutes)

### 1. **Prérequis Vérifiés** ✅
- Python 3.10+ ✅
- Dépendances installées ✅ (`pip install -r requirements.txt`)
- Blender 3.0+ installé
- VS Code avec RooCode

### 2. **Installation de l'Addon Blender** (2 min)

```bash
# 1. Ouvrir Blender
# 2. Edit > Preferences > Add-ons > Install...
# 3. Sélectionner : services/blender-mcp/addon.py
# 4. Activer l'addon "Interface: Blender MCP"
# 5. Dans le panneau latéral (N) > BlenderMCP > "Connect to Claude"
```

### 3. **Configuration RooCode** (2 min)

Ajouter ce serveur MCP dans RooCode :

```json
{
  "name": "blender-eloquence",
  "command": "python",
  "args": ["services/blender-mcp/main.py"],
  "cwd": "c:/Users/User/Desktop/Eloquence"
}
```

### 4. **Premier Test** (1 min)

Dans RooCode, tapez :

```
Crée une roulette de casino avec 6 segments colorés
```

**Résultat attendu :** Animation 3D d'une roulette qui tourne ! 🎰

## 🎯 Prompts de Test

### **Roulettes**
```
"Roulette 8 segments rouges et noirs"
"Roue de la fortune avec 12 segments colorés"  
"Roulette de casino qui tourne pendant 5 secondes"
```

### **Cubes Rebondissants**
```
"Cube orange qui rebondit 3 fois"
"Cube bleu métallique qui rebondit 5 fois"
"Box qui saute 2 fois sur le sol"
```

### **Logos 3D**
```
"Logo ELOQUENCE doré qui apparaît et tourne"
"Logo 'MON TEXTE' qui apparaît avec effet"
"Texte 3D 'HELLO' qui tourne"
```

## 🛠️ Outils Disponibles

| Outil | Description | Exemple |
|-------|-------------|---------|
| `create_animation_from_prompt` | Création via prompt naturel | "Roulette 6 segments" |
| `export_animation` | Export GLTF/FBX/MP4 | Format + nom de fichier |
| `list_animation_templates` | Liste des templates | Voir tous les types |
| `execute_blender_code` | Code Python direct | Script personnalisé |
| `get_scene_info` | Infos de la scène | État actuel |

## 📁 Fichiers Exportés

**Localisation :** Bureau utilisateur (`~/Desktop/`)

**Formats supportés :**
- **GLTF** → Pour le web (Three.js, A-Frame)
- **FBX** → Pour Unity/Unreal Engine  
- **OBJ** → Modèles statiques
- **MP4** → Vidéos d'animations

## 🚨 Dépannage Express

| Problème | Solution |
|----------|----------|
| "Connexion échouée" | Vérifier que Blender est ouvert + addon actif |
| "Prompt non reconnu" | Utiliser mots-clés : roulette, cube, logo, rebond |
| "Serveur MCP introuvable" | Vérifier le chemin dans la config RooCode |

## ✨ Fonctionnalités Avancées

### **Personnalisation de Couleurs**
```
"Roulette rouge et noir alternée"
"Cube violet métallique"  
"Logo doré brillant"
```

### **Contrôle d'Animation**
```
"Cube qui rebondit 5 fois en ralentissant"
"Roulette qui tourne pendant 10 secondes"
"Logo qui apparaît lentement"
```

### **Export Automatique**
```
# Dans RooCode après création :
"Exporte cette animation en GLTF"
"Sauvegarde en MP4 haute qualité"
```

## 🎉 Prêt à Créer !

Votre intégration Blender MCP pour Eloquence est maintenant opérationnelle ! 

**Dans RooCode, tapez simplement :**
> *"Crée une roulette colorée qui tourne"*

Et regardez la magie opérer ! ✨🎨