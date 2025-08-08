# Guide de Validation des Exercices LiveKit

## État du Système
- ✅ **Services opérationnels** : Tous les conteneurs sont healthy
- ✅ **Agent LiveKit** : Enregistré et en écoute
- ✅ **Routage unifié** : Point d'entrée unique avec détection automatique

## Tests de Validation

### 1. Confidence Boost
**Agent attendu** : Thomas (voix alloy)
**Type** : Exercice individuel

#### Test via Flutter
1. Ouvrir l'application Flutter
2. Naviguer vers "Confidence Boost"
3. Démarrer une session
4. Vérifier que :
   - L'agent répond avec la voix "alloy" (Thomas)
   - Les interactions sont fluides
   - L'agent reste encourageant et positif

#### Test via Room Direct
```bash
# Créer une room de test
curl -X POST http://localhost:8004/create-room \
  -H "Content-Type: application/json" \
  -d '{"room_name": "confidence_boost_test", "metadata": {"exercise": "confidence_boost"}}'
```

### 2. Tribunal des Idées Impossibles
**Agent attendu** : Juge Magistrat (voix onyx)
**Type** : Exercice individuel

#### Test via Flutter
1. Ouvrir l'application Flutter
2. Naviguer vers "Tribunal des Idées Impossibles"
3. Proposer une idée impossible
4. Vérifier que :
   - L'agent utilise la voix "onyx" (Juge)
   - Le ton est sérieux et magistral
   - Les réponses sont créatives et théâtrales

#### Test via Room Direct
```bash
curl -X POST http://localhost:8004/create-room \
  -H "Content-Type: application/json" \
  -d '{"room_name": "tribunal_test", "metadata": {"exercise": "tribunal_idees_impossibles"}}'
```

### 3. Studio Situations Pro
**Agents attendus** : 11 agents multi-personnalités
**Type** : Exercice multi-agents

#### Scénarios à tester :

##### A. Entretien d'embauche
**Agents** : Sophie (RH) et Marc (Expert technique)
```bash
curl -X POST http://localhost:8004/create-room \
  -H "Content-Type: application/json" \
  -d '{"room_name": "studio_test", "metadata": {"exercise": "studio_situations_pro", "scenario": "simulation_entretien"}}'
```

##### B. Négociation commerciale
**Agents** : Ahmed (Client) et autres
```bash
curl -X POST http://localhost:8004/create-room \
  -H "Content-Type: application/json" \
  -d '{"room_name": "nego_test", "metadata": {"exercise": "studio_situations_pro", "scenario": "negociation_commerciale"}}'
```

##### C. Pitch Elevator
**Agent** : Isabelle (PDG)
```bash
curl -X POST http://localhost:8004/create-room \
  -H "Content-Type: application/json" \
  -d '{"room_name": "pitch_test", "metadata": {"exercise": "studio_situations_pro", "scenario": "pitch_elevator"}}'
```

## Checklist de Validation

### ✅ Configuration système
- [ ] Docker Compose unifié démarre sans erreur
- [ ] Tous les services sont healthy
- [ ] Agent LiveKit enregistré (voir logs)
- [ ] Pas d'erreurs dans les logs

### ✅ Exercices individuels
- [ ] **Confidence Boost**
  - [ ] Thomas répond (voix alloy)
  - [ ] Personnalité encourageante
  - [ ] Pas de confusion avec d'autres agents
  
- [ ] **Tribunal des Idées**
  - [ ] Juge Magistrat répond (voix onyx)
  - [ ] Ton magistral et théâtral
  - [ ] Créativité dans les jugements

### ✅ Exercices multi-agents (Studio Situations Pro)
- [ ] **Entretien d'embauche**
  - [ ] Sophie (RH) présente
  - [ ] Marc (Expert) intervient
  - [ ] Alternance des interlocuteurs
  
- [ ] **Négociation commerciale**
  - [ ] Ahmed (Client) négocie
  - [ ] Objections réalistes
  - [ ] Progression naturelle
  
- [ ] **Pitch Elevator**
  - [ ] Isabelle (PDG) écoute
  - [ ] Questions pertinentes
  - [ ] Feedback constructif

### ✅ Qualité audio/vocale
- [ ] Voix distinctes pour chaque agent
- [ ] Audio clair sans distorsion
- [ ] Latence acceptable (<2s)
- [ ] Reconnaissance vocale fonctionnelle

## Commandes utiles

### Voir les logs en temps réel
```bash
# Tous les logs
docker-compose -f docker-compose-unified.yml logs -f

# Agent LiveKit uniquement
docker-compose -f docker-compose-unified.yml logs -f livekit-agent

# Filtrer par exercice
docker-compose -f docker-compose-unified.yml logs -f livekit-agent | grep "confidence_boost"
```

### Vérifier l'état des services
```bash
docker-compose -f docker-compose-unified.yml ps
```

### Redémarrer si nécessaire
```bash
.\restart-unified.bat
```

## Résolution des problèmes courants

### Agent ne répond pas
1. Vérifier les logs : `docker-compose -f docker-compose-unified.yml logs --tail=100 livekit-agent`
2. Vérifier que le worker est enregistré (chercher "registered worker")
3. Redémarrer les services si nécessaire

### Mauvais agent qui répond
1. Vérifier les métadonnées envoyées (voir logs)
2. S'assurer que l'exercice est correctement détecté
3. Vérifier le routage dans `unified_entrypoint.py`

### Problèmes audio
1. Vérifier VOSK : `curl http://localhost:8002/health`
2. Vérifier les logs VOSK pour les erreurs
3. S'assurer que le modèle français est chargé

## Rapport de validation

### Date : ___________
### Testeur : ___________

| Exercice | Agent attendu | Fonctionne | Notes |
|----------|--------------|------------|-------|
| Confidence Boost | Thomas (alloy) | ☐ Oui ☐ Non | |
| Tribunal Idées | Juge (onyx) | ☐ Oui ☐ Non | |
| Studio - Entretien | Sophie & Marc | ☐ Oui ☐ Non | |
| Studio - Négociation | Ahmed | ☐ Oui ☐ Non | |
| Studio - Pitch | Isabelle | ☐ Oui ☐ Non | |

### Problèmes rencontrés :
_________________________________

### Actions correctives :
_________________________________

## Contact support
En cas de problème persistant, vérifier :
1. Les variables d'environnement dans `.env`
2. La configuration réseau Docker
3. Les ports exposés (7880, 8001, 8002, 8004, 8005)