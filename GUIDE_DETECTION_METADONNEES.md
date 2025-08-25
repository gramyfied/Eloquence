# Guide de Test de Détection des Métadonnées

## 🎯 Problème Résolu

Le système multi-agent ne détectait pas correctement les métadonnées (nom et thème du débat) configurées dans la page de configuration avant le démarrage.

## ✅ Solutions Implémentées

### 1. **Amélioration de la Détection des Métadonnées**

Le système multi-agent (`multi_agent_main.py`) a été amélioré pour :

- ✅ **Vérifier les métadonnées de la room**
- ✅ **Vérifier les métadonnées des participants distants**
- ✅ **Vérifier les métadonnées du participant local** (NOUVEAU)
- ✅ **Améliorer l'extraction des données utilisateur**

### 2. **Amélioration de l'Extraction des Données**

La fonction `detect_exercise_from_metadata()` a été améliorée pour :

- ✅ **Extraire le nom d'utilisateur** depuis `user_name` ou `user_id`
- ✅ **Extraire le sujet/thème** depuis `user_subject` ou `topic`
- ✅ **Gérer les valeurs vides** avec des fallbacks appropriés
- ✅ **Logger détaillé** pour le débogage

### 3. **Transmission des Métadonnées**

Le frontend (`studio_livekit_service.dart`) a été modifié pour :

- ✅ **Attacher les métadonnées au participant local** après connexion
- ✅ **Inclure les métadonnées dans le token** de connexion
- ✅ **Envoyer les métadonnées via `sendMessage`** (méthode existante)

## 🧪 Comment Tester

### 1. **Démarrage d'une Session Multi-Agents**

1. Ouvrez l'application Flutter
2. Allez dans "Studio Situations Pro"
3. Configurez :
   - **Votre nom** : "Jean Dupont"
   - **Thème du débat** : "L'intelligence artificielle dans l'éducation"
4. Démarrez la simulation

### 2. **Vérification des Logs**

Les logs du conteneur `eloquence-multiagent` devraient maintenant afficher :

```
🔍 DIAGNOSTIC APPROFONDI DES MÉTADONNÉES
============================================================
✅ Métadonnées trouvées depuis: LOCAL_PARTICIPANT
📋 Contenu: {"exercise_type": "studio_debate_tv", "user_name": "Jean Dupont", ...}
🎯 SÉLECTION CONFIGURATION MULTI-AGENTS
🎭 CONFIGURATION MULTI-AGENTS SÉLECTIONNÉE:
   ID: studio_debate_tv
   Titre: Studio Débat TV
   Agents: ['Michel Dubois', 'Sarah Johnson', 'Marcus Thompson']
   Utilisateur: Jean Dupont
   Sujet: L'intelligence artificielle dans l'éducation
```

### 3. **Test avec le Script de Validation**

```bash
cd services/livekit-agent
python test_metadata_detection.py
```

Ce script teste différents formats de métadonnées et confirme que la détection fonctionne.

## 🔧 Fonctionnalités Améliorées

### **Détection Robuste**
- ✅ Vérification de multiples sources de métadonnées
- ✅ Fallbacks automatiques en cas d'échec
- ✅ Gestion des formats JSON invalides

### **Extraction Intelligente**
- ✅ Support de `user_name` et `user_id`
- ✅ Support de `user_subject` et `topic`
- ✅ Valeurs par défaut appropriées

### **Logging Détaillé**
- ✅ Affichage du contenu des métadonnées
- ✅ Indication de la source des métadonnées
- ✅ Confirmation de la configuration sélectionnée

## 🚀 Résultat Attendu

Maintenant, quand vous configurez un débat avec :
- **Nom** : "Marie Martin"
- **Thème** : "Les énergies renouvelables"

Le système multi-agent devrait :
1. ✅ **Détecter automatiquement** les métadonnées
2. ✅ **Extraire le nom** : "Marie Martin"
3. ✅ **Extraire le thème** : "Les énergies renouvelables"
4. ✅ **Configurer les agents** avec ces informations
5. ✅ **Personnaliser les conversations** selon le thème

## 📝 Notes Techniques

- Les métadonnées sont transmises via le **token LiveKit** et **attachées au participant local**
- Le système vérifie **3 sources** de métadonnées dans l'ordre de priorité
- Les **fallbacks** garantissent que le système fonctionne même sans métadonnées
- Le **logging détaillé** facilite le débogage en cas de problème

## 🎉 Conclusion

Le système multi-agent détecte maintenant correctement les métadonnées de configuration et personnalise les conversations selon le nom et le thème du débat configurés par l'utilisateur.
