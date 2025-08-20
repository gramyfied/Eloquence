# 🔧 Eloquence - Fix TTS OpenAI Confidence Boost

## 📋 Description

Ce repository contient la **réparation complète** du système TTS OpenAI pour les exercices individuels d'Eloquence, notamment **Confidence Boost** et **Tribunal des Idées Impossible**.

## 🎯 Problème Résolu

**Problème initial :** Le TTS OpenAI ne fonctionnait pas pour les exercices individuels car la clé API OpenAI n'était pas correctement configurée dans l'environnement Docker.

## ✅ Solution Implémentée

### 🔧 **Configuration Environnement**
- Création du fichier `.env` avec les variables d'environnement
- Configuration Docker Compose pour utiliser les variables d'environnement
- Support des clés API OpenAI et Mistral

### 🤖 **Priorisation GPT-4o**
- **GPT-4o** : Priorité pour les exercices individuels
- **GPT-3.5-turbo** : Fallback pour les tâches simples
- **Mistral** : Fallback final si OpenAI indisponible

### 🎤 **Configuration TTS**
- **Confidence Boost** : Personnage `thomas` → Voix OpenAI `alloy`
- **Tribunal des Idées Impossible** : Personnage `juge_magistrat` → Voix OpenAI `onyx`
- **ElevenLabs** : Réservé aux simulations multi-agents uniquement

## 🚀 Installation Rapide

### 1. **Cloner le repository**
```bash
git clone https://github.com/votre-username/eloquence-tts-fix-2025.git
cd eloquence-tts-fix-2025
```

### 2. **Configurer les variables d'environnement**
```bash
# Copier le template
cp env_template.txt .env

# Éditer .env avec vos vraies clés API
# OPENAI_API_KEY=sk-proj-votre-vraie-cle-openai
# MISTRAL_API_KEY=votre-cle-mistral
```

### 3. **Démarrer les services**
```bash
docker-compose up -d
```

### 4. **Vérifier la configuration**
```bash
docker exec eloquence-multiagent python -c "import os; print('OPENAI_API_KEY presente:', 'Oui' if os.getenv('OPENAI_API_KEY') else 'Non')"
```

## 🧪 Tests

### Test GPT-4o
```bash
cd services/livekit-agent
python test_gpt4o_quick.py
```

### Test Configuration TTS
```bash
docker exec eloquence-multiagent python -c "from main import ExerciseTemplates; config = ExerciseTemplates.confidence_boost(); print('Personnage:', config.ai_character)"
```

## 📁 Structure des Fichiers

```
├── .env                          # Variables d'environnement (à créer)
├── env_template.txt              # Template des variables d'environnement
├── docker-compose.yml            # Configuration Docker
├── FIX_TTS_OPENAI_CONFIDENCE_BOOST.md  # Documentation complète
├── push_to_new_repo.ps1          # Script pour push vers nouveau repo
├── services/
│   └── livekit-agent/
│       ├── llm_optimizer.py      # Priorisation GPT-4o
│       ├── llm_client.py         # Fallback chain
│       └── guaranteed_response_system.py  # Fallback OpenAI
```

## 🔄 Branches

- **`fix/tts-openai-confidence-boost`** : Branche principale avec la réparation

## 📊 Résultats

- ✅ **TTS OpenAI** : Fonctionnel pour Confidence Boost
- ✅ **GPT-4o** : Priorité pour les exercices individuels
- ✅ **Fallback Mistral** : Opérationnel si OpenAI indisponible
- ✅ **Services Docker** : Tous opérationnels

## 🆘 Support

Pour toute question ou problème :
1. Consultez `FIX_TTS_OPENAI_CONFIDENCE_BOOST.md` pour la documentation complète
2. Vérifiez que le fichier `.env` est correctement configuré
3. Assurez-vous que tous les services Docker sont démarrés

## 📝 Notes

- Le fichier `.env` n'est pas commité pour des raisons de sécurité
- Les tests temporaires sont dans `.gitignore`
- Cette réparation est spécifique aux exercices individuels
- Les simulations multi-agents utilisent ElevenLabs TTS
