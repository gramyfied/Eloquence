# 🎨 Installation Blender MCP pour RooCode

Guide d'installation et de configuration pour utiliser Blender avec des prompts en langage naturel dans VS Code via RooCode.

## ⚡ Installation Rapide (35 minutes)

### 📋 Prérequis

1. **Blender 3.0+** installé sur votre système
2. **Python 3.10+** 
3. **VS Code** avec l'extension **RooCode**
4. **pip** pour installer les dépendances Python

### 🚀 ÉTAPE 1 : Installation des dépendances Python (5 min)

```bash
# Dans le dossier services/blender-mcp/
cd services/blender-mcp
pip install -r requirements.txt
```

### 🎯 ÉTAPE 2 : Installation de l'addon Blender (10 min)

1. **Ouvrir Blender**
2. **Aller dans** : `Edit` > `Preferences` > `Add-ons`
3. **Cliquer** sur `Install...`
4. **Sélectionner** le fichier `services/blender-mcp/addon.py`
5. **Activer** l'addon `Interface: Blender MCP`
6. **Démarrer le serveur** :
   - Aller dans le panneau latéral (touche `N`)
   - Onglet `BlenderMCP`
   - Cliquer sur `Connect to Claude`

### ⚙️ ÉTAPE 3 : Configuration RooCode (10 min)

1. **Ouvrir VS Code**
2. **Aller dans** : Settings > Extensions > RooCode > MCP Servers
3. **Ajouter un nouveau serveur MCP** avec ces paramètres :

```json
{
  "name": "blender-eloquence",
  "command": "python",
  "args": ["services/blender-mcp/main.py"],
  "cwd": "c:/Users/User/Desktop/Eloquence",
  "env": {
    "PYTHONPATH": "services/blender-mcp"
  }
}
```

### 🧪 ÉTAPE 4 : Test de l'intégration (10 min)

1. **Redémarrer VS Code** 
2. **Ouvrir RooCode** (Ctrl+Shift+P > "RooCode")
3. **Tester avec ces prompts** :

```
Crée une roulette de casino avec 6 segments colorés
```

```
Fais un cube orange qui rebondit 3 fois
```

```
Génère un logo "ELOQUENCE" doré qui apparaît et tourne
```

## 🎨 Utilisation dans RooCode

### 📝 Prompts Supportés

| Type d'Animation | Exemple de Prompt | Paramètres |
|------------------|-------------------|------------|
| **Roulette** | "Roulette 8 segments rouges et noirs" | Segments (2-20), couleurs |
| **Cube Rebondissant** | "Cube qui rebondit 5 fois" | Nombre de rebonds (1-10) |
| **Logo 3D** | "Logo 'MON TEXTE' qui apparaît" | Texte personnalisé |

### 🔧 Outils Disponibles

- `create_animation_from_prompt` : Créer depuis un prompt
- `export_animation` : Exporter en GLTF/FBX/MP4
- `list_animation_templates` : Lister les templates
- `execute_blender_code` : Exécuter du Python Blender
- `get_scene_info` : Informations sur la scène

### 🎯 Exemples Pratiques

**1. Roulette personnalisée :**
```
"Roulette de casino avec 12 segments, alternant rouge et noir, qui tourne pendant 5 secondes"
```

**2. Animation de logo :**
```
"Logo 'ELOQUENCE' en or qui apparaît avec un effet de rebond et tourne lentement"
```

**3. Cube animé :**
```
"Cube bleu métallique qui rebondit 4 fois en ralentissant progressivement"
```

## 🚨 Dépannage

### ❌ Problème : "Connexion à Blender échouée"
**Solution :** 
1. Vérifier que Blender est ouvert
2. Vérifier que l'addon est activé
3. Cliquer sur "Connect to Claude" dans Blender

### ❌ Problème : "Module 'mcp' non trouvé"
**Solution :**
```bash
pip install mcp fastmcp
```

### ❌ Problème : "Prompt non reconnu"
**Solution :** Utiliser les mots-clés : "roulette", "cube", "logo", "rebond"

## 📁 Structure des Fichiers

```
services/blender-mcp/
├── main.py                      # Point d'entrée
├── server.py                    # Serveur MCP principal
├── eloquence_blender_tools.py   # Outils spécialisés RooCode
├── addon.py                     # Addon Blender
├── requirements.txt             # Dépendances Python
├── roocode_mcp_config.json     # Configuration MCP
└── INSTALLATION_ROOCODE.md     # Ce guide
```

## 🎉 Résultat Final

**Après installation :**
- ✅ Blender connecté à RooCode
- ✅ Prompts en langage naturel fonctionnels
- ✅ Export automatique GLTF/FBX/MP4
- ✅ Templates d'animations prêts à l'emploi

**Dans RooCode, tapez simplement :**
```
"Crée une roulette colorée qui tourne"
```

Et obtenez une animation 3D complète ! 🎨✨