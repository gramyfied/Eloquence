# 🎨 Blender MCP - Intégration Eloquence

**Intégration Blender optimisée pour RooCode avec prompts en langage naturel**

![Status](https://img.shields.io/badge/Status-✅%20Fonctionnel-green)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![Blender](https://img.shields.io/badge/Blender-3.0+-orange)
![Python](https://img.shields.io/badge/Python-3.10+-yellow)

## 🚀 Aperçu

Cette intégration permet de créer des animations 3D dans Blender directement depuis VS Code avec RooCode en utilisant des prompts simples en langage naturel.

**Exemple d'utilisation :**
```
Utilisateur dans RooCode : "Crée une roulette de casino avec 6 segments colorés"
→ Blender génère automatiquement une animation 3D de roulette qui tourne !
```

## ✨ Fonctionnalités

### 🎯 **Prompts en Langage Naturel**
- **Roulettes :** `"Roulette 8 segments rouges et noirs"`
- **Cubes Rebondissants :** `"Cube orange qui rebondit 3 fois"`
- **Logos 3D :** `"Logo ELOQUENCE doré qui apparaît"`

### 🛠️ **Outils MCP Spécialisés**
- `create_animation_from_prompt` - Création via prompt naturel
- `export_animation` - Export GLTF/FBX/MP4
- `list_animation_templates` - Liste des templates disponibles
- `execute_blender_code` - Exécution de code Python Blender
- `get_scene_info` - Informations sur la scène

### 📁 **Formats d'Export**
- **GLTF** → Web (Three.js, A-Frame)
- **FBX** → Unity/Unreal Engine
- **OBJ** → Modèles statiques  
- **MP4** → Vidéos d'animations

## 📦 Installation

### **Option 1 : Installation Express (5 min)**
```bash
# 1. Installer les dépendances
cd services/blender-mcp
pip install -r requirements.txt

# 2. Tester l'intégration
python test_integration.py
```

### **Option 2 : Installation Complète**
Voir [`INSTALLATION_ROOCODE.md`](INSTALLATION_ROOCODE.md) pour le guide détaillé.

## ⚡ Démarrage Rapide

Voir [`GUIDE_DEMARRAGE_RAPIDE.md`](GUIDE_DEMARRAGE_RAPIDE.md) pour commencer immédiatement.

## 🏗️ Architecture

```
services/blender-mcp/
├── main.py                      # Point d'entrée MCP
├── server.py                    # Serveur MCP principal
├── eloquence_blender_tools.py   # Outils spécialisés RooCode
├── addon.py                     # Addon Blender (communication socket)
├── requirements.txt             # Dépendances Python
├── roocode_mcp_config.json     # Configuration MCP pour RooCode
├── test_integration.py         # Tests d'intégration
├── INSTALLATION_ROOCODE.md     # Guide d'installation
├── GUIDE_DEMARRAGE_RAPIDE.md   # Guide de démarrage
└── README.md                   # Ce fichier
```

## 🎨 Templates d'Animations

### **1. Roulettes de Casino**
- Segments personnalisables (2-20)
- Couleurs au choix
- Animation de rotation fluide
- **Exemple :** `"Roulette 12 segments alternés rouge noir"`

### **2. Cubes Rebondissants**
- Nombre de rebonds variable (1-10)
- Couleurs personnalisées
- Physique réaliste
- **Exemple :** `"Cube bleu métallique qui rebondit 5 fois"`

### **3. Logos Texte 3D**
- Texte personnalisé
- Animation d'apparition
- Matériaux métalliques
- **Exemple :** `"Logo 'ELOQUENCE' doré qui tourne"`

## 🔧 Configuration RooCode

Ajouter dans les serveurs MCP de RooCode :

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

## 📊 Tests d'Intégration

```bash
# Lancer les tests complets
python test_integration.py
```

**Résultats attendus :**
- ✅ Fichiers de configuration
- ✅ Dépendances Python
- ✅ Parsing des prompts  
- ✅ Templates d'animations
- ✅ Serveur MCP

## 🚨 Dépannage

| Problème | Solution |
|----------|----------|
| **Connexion Blender échouée** | Vérifier que Blender est ouvert + addon activé |
| **Prompt non reconnu** | Utiliser mots-clés : "roulette", "cube", "logo", "rebond" |
| **Import MCP échoué** | Vérifier `pip install mcp fastmcp` |
| **Serveur non trouvé** | Vérifier le chemin dans la config RooCode |

## 🔗 Intégration Eloquence

Cette intégration fait partie du projet **Eloquence** et s'intègre parfaitement avec :
- 🎤 **Streaming API** pour la reconnaissance vocale
- 🧠 **Mistral AI** pour la génération de contenu
- 📱 **Flutter App** pour l'interface mobile
- 🔄 **LiveKit** pour la communication temps réel

## 📈 Performances

- **Parsing de prompts :** ~10ms
- **Génération de code :** ~50ms  
- **Communication Blender :** ~200ms
- **Export GLTF :** ~2-5s selon complexité

## 🛣️ Roadmap

- [ ] Support des animations de caméra
- [ ] Templates de scènes complètes
- [ ] Intégration avec les assets PolyHaven
- [ ] Export direct vers Eloquence Flutter
- [ ] Mode batch pour animations multiples

## 📄 Licence

Projet Eloquence - Intégration Blender MCP pour la création d'animations 3D via prompts naturels.

---

**Créé avec ❤️ pour le projet Eloquence**  
*Transformez vos idées en animations 3D d'un simple prompt !* ✨🎨