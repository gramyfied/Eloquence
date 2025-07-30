# 🎮 Guide de Visualisation Interactive Blender

## 🌟 Nouvelle Fonctionnalité : Ouverture Directe de Blender GUI

Vous pouvez maintenant ouvrir Blender directement avec votre création 3D depuis RooCode !

## 🚀 Comment Utiliser

### 1. Via RooCode (Recommandé)

Dans VS Code avec RooCode, utilisez simplement le nouvel outil MCP :

```
Utilise l'outil open_blender_gui_with_prompt avec le prompt "Roulette virelangues interactive"
```

### 2. Via Script Direct

```bash
cd C:\Users\User\Desktop\Eloquence\services\blender-mcp
python launch_blender_gui.py "Roulette des virelangues colorée"
```

## 🎨 Prompts Supportés

- **Roulettes** : "Roulette des virelangues colorée", "Roulette casino 8 segments"
- **Cubes** : "Cube qui rebondit 5 fois", "Cube orange rebondissant"
- **Logos** : "Logo ELOQUENCE qui tourne", "Logo 'MON TEXTE' doré"

## 🎮 Contrôles Blender

Une fois Blender ouvert :

| Action | Contrôle |
|--------|----------|
| 🔄 Rotation de la vue | Bouton du milieu + glisser |
| 🔍 Zoom/Dézoom | Molette de la souris |
| ⏯️ Lancer/Arrêter animation | ESPACE |
| 🎥 Rendre image HD | F12 |
| 🎬 Rendre animation complète | CTRL+F12 |
| 💾 Sauvegarder fichier .blend | CTRL+S |

## ✨ Avantages de la Visualisation Interactive

- **Rotation libre** de votre création 3D
- **Zoom** pour voir les détails 
- **Animation en temps réel** avec contrôles
- **Modification manuelle** des paramètres
- **Rendu haute qualité** personnalisé
- **Sauvegarde** de vos projets

## 🔧 Dépannage

**Si Blender ne s'ouvre pas :**
1. Vérifiez que Blender 4.5 est installé dans `C:\Program Files\Blender Foundation\Blender 4.5\`
2. Essayez d'exécuter le script directement en ligne de commande
3. Consultez les logs dans la console

**Erreur de chemin :**
- Le script recherche automatiquement Blender 4.5
- Modifiez `blender_path` dans `launch_blender_gui.py` si nécessaire

## 🎉 Exemples Réussis

### Roulette des Virelangues
```python
python launch_blender_gui.py "Roulette virelangues 8 segments"
```
Résultat : Roulette colorée avec 8 segments et couleurs Flutter vibrantes

### Cube Rebondissant
```python  
python launch_blender_gui.py "Cube rebondit 3 fois orange"
```
Résultat : Cube orange qui rebondit avec animation fluide

### Logo 3D
```python
python launch_blender_gui.py "Logo ELOQUENCE doré qui tourne"
```
Résultat : Texte 3D métallique avec animation de rotation

## 📋 Prochaines Étapes

1. **Testez** la fonctionnalité avec différents prompts
2. **Explorez** les contrôles Blender pour personnaliser
3. **Sauvegardez** vos créations favorites
4. **Experimentez** avec les rendus haute qualité (F12)

---

*Cette fonctionnalité complète parfaitement l'intégration Blender-RooCode avec une visualisation interactive professionnelle !*