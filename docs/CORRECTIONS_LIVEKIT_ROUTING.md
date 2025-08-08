# 🔧 CORRECTIONS DU SYSTÈME LIVEKIT - ROUTAGE DES EXERCICES

## 📋 RÉSUMÉ DES PROBLÈMES IDENTIFIÉS

1. **Tribunal des idées impossibles** : LiveKit cassé, ne fonctionne plus
2. **Confidence Boost** : LiveKit également cassé  
3. **Studio Situations Pro** : Thomas (agent de Confidence Boost) répond au lieu des agents multi-agents dédiés

## ✅ CORRECTIONS APPLIQUÉES

### 1. Création d'un Point d'Entrée Unifié
**Fichier** : `services/livekit-agent/unified_entrypoint.py`

- **Rôle** : Router intelligemment les exercices vers le bon système
- **Logique** :
  ```
  Exercices Multi-Agents → multi_agent_main.py
  - studio_situations_pro
  - studio_debate_tv
  - studio_job_interview
  - studio_boardroom
  - studio_sales_conference
  - studio_keynote
  
  Exercices Individuels → main.py
  - confidence_boost (Thomas)
  - tribunal_idees_impossibles (Juge Magistrat)
  - cosmic_voice_control (Nova)
  - job_interview (Marie)
  ```

### 2. Correction du Fichier main.py
**Modifications** :
- Suppression de toute tentative de conversion des exercices multi-agents
- Les exercices multi-agents détectés génèrent maintenant une erreur avec fallback
- Suppression de la méthode `convert_multiagent_to_exercise_config()`
- Le système ne gère plus QUE les exercices individuels

### 3. Infrastructure Docker Mise à Jour

#### Nouveau Dockerfile Unifié
**Fichier** : `services/livekit-agent/Dockerfile.unified`
- Utilise `unified_entrypoint.py` comme point d'entrée
- Architecture optimisée avec Poetry
- Support complet des dépendances audio (ffmpeg, portaudio)

#### Docker Compose Modifié
**Fichier** : `docker-compose-new.yml`
- Service `livekit-agents` utilise maintenant `Dockerfile.unified`
- Variable d'environnement `AGENT_MODE=unified` ajoutée
- Port 8090 pour éviter les conflits

### 4. Script de Redémarrage
**Fichier** : `scripts/restart-livekit-fixed.ps1`
- Arrête et supprime les anciens conteneurs
- Reconstruit avec le nouveau Dockerfile unifié
- Redémarre le service avec le routage corrigé

## 🎯 RÉSULTAT ATTENDU APRÈS CORRECTIONS

### ✅ Tribunal des Idées Impossibles
- **Agent** : Juge Magistrat
- **Voix** : onyx (grave et autoritaire)
- **Comportement** : Présidence de tribunal bienveillante

### ✅ Confidence Boost  
- **Agent** : Thomas
- **Voix** : alloy
- **Comportement** : Coach en communication bienveillant

### ✅ Studio Situations Pro
- **Agents** : Multi-agents dédiés
  - Michel Dubois (Modérateur)
  - Sarah Johnson (Experte technique)
  - Marcus Thompson (Sceptique analytique)
  - Et autres selon le scénario
- **Voix** : Différenciées par agent
- **Comportement** : Simulation multi-agents réaliste

## 📝 INSTRUCTIONS DE DÉPLOIEMENT

### 1. Arrêter les Services Actuels
```powershell
docker-compose -f docker-compose-new.yml stop
```

### 2. Appliquer les Corrections
```powershell
# Méthode automatique
.\scripts\restart-livekit-fixed.ps1

# OU méthode manuelle
docker-compose -f docker-compose-new.yml build livekit-agents
docker-compose -f docker-compose-new.yml up -d livekit-agents
```

### 3. Vérifier les Logs
```powershell
docker-compose -f docker-compose-new.yml logs -f livekit-agents
```

### 4. Points de Vérification
Recherchez ces messages dans les logs :
- `🚀 DÉMARRAGE WORKER LIVEKIT UNIFIÉ`
- `🎯 TYPE D'EXERCICE DÉTECTÉ: [nom_exercice]`
- `🎭 ROUTAGE → SYSTÈME MULTI-AGENTS` (pour Studio Situations Pro)
- `👤 ROUTAGE → SYSTÈME INDIVIDUEL` (pour Tribunal, Confidence, etc.)

## 🧪 TESTS DE VALIDATION

### Test 1 : Tribunal des Idées Impossibles
1. Lancer l'exercice depuis Flutter
2. **Attendu** : "⚖️ Maître, la cour vous écoute ! Je suis le Juge Magistrat..."
3. **Voix** : Grave et autoritaire (onyx)

### Test 2 : Confidence Boost
1. Lancer l'exercice depuis Flutter  
2. **Attendu** : "Bonjour ! Je suis Thomas, votre coach IA..."
3. **Voix** : Chaleureuse et encourageante (alloy)

### Test 3 : Studio Situations Pro
1. Lancer un scénario (ex: Débat TV)
2. **Attendu** : "🎭 Bienvenue dans Studio Debate Tv ! Je suis Michel Dubois..."
3. **Agents** : Michel Dubois, Sarah Johnson, Marcus Thompson selon le contexte
4. **Voix** : Différenciées selon l'agent qui parle

## 🔍 DÉPANNAGE

### Si un exercice ne fonctionne pas :

1. **Vérifier les métadonnées** dans les logs :
   ```
   🔍 TYPE D'EXERCICE DÉTECTÉ: [exercise_type]
   ```

2. **Vérifier le routage** :
   - Multi-agents : `🎭 ROUTAGE → SYSTÈME MULTI-AGENTS`
   - Individuel : `👤 ROUTAGE → SYSTÈME INDIVIDUEL`

3. **Si mauvais agent répond** :
   - Vérifier que `unified_entrypoint.py` est bien utilisé
   - Vérifier que le bon Dockerfile est utilisé (`Dockerfile.unified`)

4. **Si erreur de connexion** :
   - Vérifier que tous les services sont démarrés (livekit, vosk-stt, mistral)
   - Vérifier les variables d'environnement dans `.env`

## 📊 ARCHITECTURE FINALE

```
                    Flutter App
                         |
                    exercise_type
                         |
                 unified_entrypoint.py
                    /          \
                   /            \
    Exercices Individuels    Exercices Multi-Agents
           |                         |
        main.py              multi_agent_main.py
           |                         |
    [Thomas, Juge, Nova]    [Michel, Sarah, Marcus...]
```

## ✨ AMÉLIORATIONS APPORTÉES

1. **Séparation claire** entre exercices individuels et multi-agents
2. **Routage intelligent** basé sur le type d'exercice
3. **Élimination des conversions incorrectes** qui causaient les bugs
4. **Maintien de l'identité des agents** (plus de confusion Thomas/Michel)
5. **Architecture modulaire** facilitant l'ajout de nouveaux exercices

---

📅 **Date des corrections** : 08/08/2025
🔧 **Version** : 2.0.0 (Routage Unifié)