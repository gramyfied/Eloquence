# 🔧 FIX TTS OpenAI - Confidence Boost

## 📋 Problème Résolu

**Problème :** Le TTS OpenAI ne fonctionnait pas pour les exercices individuels (Confidence Boost, Tribunal des Idées Impossible) car la clé API OpenAI n'était pas correctement configurée dans l'environnement Docker.

## ✅ Solution Appliquée

### 1. **Configuration des Variables d'Environnement**

- **Création du fichier `.env`** à la racine du projet avec :
  - `OPENAI_API_KEY` : Clé API OpenAI pour TTS
  - `MISTRAL_API_KEY` : Clé API Mistral pour fallback
  - Configuration complète des services

### 2. **Priorisation GPT-4o**

**Fichiers modifiés :**
- `services/livekit-agent/llm_optimizer.py` : Priorité GPT-4o pour les tâches complexes
- `services/livekit-agent/llm_client.py` : Fallback chain GPT-4o → GPT-3.5 → Mistral
- `services/livekit-agent/guaranteed_response_system.py` : Fallback OpenAI direct

**Logique de sélection :**
```python
# Priorité 1: GPT-4o si disponible et tâche complexe
if openai_key and use_advanced:
    model = 'gpt-4o'
elif openai_key:
    model = 'gpt-3.5-turbo'
# Fallback: Mistral si configuré
elif os.getenv('MISTRAL_BASE_URL'):
    model = 'mistral-nemo-instruct-2407'
```

### 3. **Configuration TTS**

**Exercices individuels (OpenAI TTS) :**
- **Confidence Boost** : Personnage `thomas` → Voix OpenAI `alloy`
- **Tribunal des Idées Impossible** : Personnage `juge_magistrat` → Voix OpenAI `onyx`

**Simulations multi-agents (ElevenLabs TTS) :**
- Réservé aux simulations multi-agents uniquement

## 🚀 Déploiement

### Étapes de configuration :

1. **Créer le fichier `.env`** à la racine :
```bash
# Copier env_template.txt vers .env
cp env_template.txt .env
# Éditer .env avec vos vraies clés API
```

2. **Redémarrer les services :**
```bash
docker-compose down
docker-compose up -d
```

3. **Vérifier la configuration :**
```bash
docker exec eloquence-multiagent python -c "import os; print('OPENAI_API_KEY presente:', 'Oui' if os.getenv('OPENAI_API_KEY') else 'Non')"
```

## 🧪 Tests

### Tests de validation :

1. **Test GPT-4o priorité :**
```bash
cd services/livekit-agent
python test_gpt4o_quick.py
```

2. **Test TTS Configuration :**
```bash
docker exec eloquence-multiagent python -c "from main import ExerciseTemplates; config = ExerciseTemplates.confidence_boost(); print('Personnage:', config.ai_character)"
```

## 📊 Résultats

- ✅ **TTS OpenAI** : Fonctionnel pour Confidence Boost
- ✅ **GPT-4o** : Priorité pour les exercices individuels
- ✅ **Fallback Mistral** : Opérationnel si OpenAI indisponible
- ✅ **Services Docker** : Tous opérationnels

## 🔄 Branche Git

**Branche :** `fix/tts-openai-confidence-boost`

**Fichiers modifiés :**
- `env_template.txt` : Template mis à jour avec Mistral
- `services/livekit-agent/llm_optimizer.py` : Priorisation GPT-4o
- `services/livekit-agent/llm_client.py` : Fallback chain
- `services/livekit-agent/guaranteed_response_system.py` : Fallback OpenAI direct

## 📝 Notes

- Le fichier `.env` n'est pas commité (sécurité)
- Les tests sont dans `.gitignore` (fichiers temporaires)
- Configuration Docker Compose utilise les variables d'environnement du `.env`
