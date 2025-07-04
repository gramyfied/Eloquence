# 🚀 GUIDE MONITORING PERFORMANCE - Goulots d'Étranglement et Rapidité

## 📊 SYSTÈME DE MONITORING COMPLET

L'agent LiveKit dispose maintenant d'un **système de monitoring avancé** pour détecter automatiquement les goulots d'étranglement et mesurer la rapidité en temps réel.

## ⏱️ MÉTRIQUES DE PERFORMANCE SURVEILLÉES

### **🎤 STT (Speech-to-Text)**
```bash
# Métriques surveillées
- stt_processing: Temps total de traitement STT (seuil: 2.0s)
- audio_chunk: Préparation des chunks audio (seuil: 0.1s)
- network_request: Requêtes vers Whisper (seuil: 1.0s)

# Logs de performance
🚀 PERF: stt_processing - 1250.5ms (BON) - Seuil: 2000ms
⏱️ PERF: STT chunk traité - 32000 bytes -> 45 chars
⚠️ PERF: network_request - 1800.2ms (LENT) - Seuil: 1000ms
🐌 BOTTLENECK: stt_processing est lent (2.8s)
```

### **🔊 TTS (Text-to-Speech)**
```bash
# Métriques surveillées
- tts_synthesis: Synthèse vocale complète (seuil: 0.5s)
- tts_chunk: Traitement par chunks (seuil: 0.2s)
- audio_conversion: Conversion audio (seuil: 0.1s)

# Logs de performance
🚀 PERF: tts_synthesis - 420.1ms (✅ BON) - Seuil: 500ms
⚠️ PERF: tts_chunk - 650.3ms (LENT) - Seuil: 200ms
🐌 BOTTLENECK: tts_synthesis est lent (0.8s)
```

### **🧠 LLM (Language Model)**
```bash
# Métriques surveillées
- llm_response: Réponse LLM complète (seuil: 4.0s)
- llm_api_call: Appel API Mistral (seuil: 3.0s)
- cache_lookup: Recherche en cache (seuil: 0.05s)

# Logs de performance
🚀 PERF: llm_response - 2100.8ms (✅ BON) - Seuil: 4000ms
🚀 PERF: cache_lookup - 12.5ms (🚀 EXCELLENT) - Seuil: 50ms
⚠️ PERF: llm_api_call - 4200.1ms (LENT) - Seuil: 3000ms
```

### **🔗 Pipeline End-to-End**
```bash
# Métriques surveillées
- end_to_end: Pipeline complet (seuil: 6.0s)
- voice_to_voice: Latence voix-à-voix (seuil: 5.0s)

# Logs de performance
🚀 PERF: end_to_end - 4850.2ms (✅ BON) - Seuil: 6000ms
⚠️ PERF: voice_to_voice - 5800.1ms (LENT) - Seuil: 5000ms
```

## 🎯 NIVEAUX DE PERFORMANCE

### **🚀 EXCELLENT** (< 50% du seuil)
- Performance optimale
- Aucune action requise
- Expérience utilisateur fluide

### **✅ BON** (50-100% du seuil)
- Performance acceptable
- Surveillance continue
- Optimisations mineures possibles

### **⚠️ LENT** (100-150% du seuil)
- Performance dégradée
- **Action recommandée**
- Goulot d'étranglement potentiel

### **🐌 GOULOT** (> 150% du seuil)
- **Goulot d'étranglement critique**
- **Action immédiate requise**
- Impact sur l'expérience utilisateur

## 🔍 DÉTECTION AUTOMATIQUE DES GOULOTS

### **Analyse Intelligente**
```python
# Le système détecte automatiquement :
- Composants les plus lents
- Tendances de dégradation
- Corrélations entre métriques
- Suggestions d'optimisation contextuelles
```

### **Logs de Diagnostic Automatique**
```bash
🚨 GOULOTS DÉTECTÉS: stt_processing (2800ms > 2000ms), network_request (1800ms > 1000ms)

🔍 BOTTLENECK: stt_processing est lent (2.800s)
💡 OPTIMISATIONS: stt_processing
   - Réduire la taille des chunks audio
   - Optimiser la configuration Whisper
   - Vérifier la latence réseau vers le service STT

🔍 BOTTLENECK: network_request est lent (1.800s)
💡 OPTIMISATIONS: network_request
   - Vérifier la connectivité réseau
   - Augmenter le pool de connexions
   - Implémenter un retry plus intelligent
```

## 📈 STATISTIQUES DE PERFORMANCE

### **Résumé Automatique**
```bash
📊 RÉSUMÉ PERFORMANCE - Dernières mesures
============================================================
🚀 EXCELLENT stt_processing      | Moy:  1250.1ms | Seuil:  2000ms | Succès:  95.2%
✅ BON       tts_synthesis       | Moy:   420.8ms | Seuil:   500ms | Succès:  98.1%
⚠️ LENT      llm_response        | Moy:  4200.5ms | Seuil:  4000ms | Succès:  92.3%
🐌 GOULOT    network_request     | Moy:  1800.2ms | Seuil:  1000ms | Succès:  87.5%
============================================================
```

### **Métriques Détaillées**
```python
{
    "count": 150,
    "avg_ms": 1250.1,
    "min_ms": 890.2,
    "max_ms": 2100.8,
    "median_ms": 1180.5,
    "std_dev_ms": 245.3,
    "threshold_ms": 2000.0,
    "success_rate": 95.2
}
```

## 🛠️ UTILISATION DU MONITORING

### **1. Monitoring Automatique**
```python
# Déjà intégré dans l'agent - aucune action requise
# Les mesures se font automatiquement sur tous les composants critiques
```

### **2. Monitoring Manuel**
```python
from services.performance_monitor import measure_time, performance_monitor

# Context manager
with measure_time("custom_operation", {"param": "value"}):
    # Votre code ici
    result = await some_operation()

# Décorateur
@measure_performance("api_call")
async def my_function():
    # Votre code ici
    pass
```

### **3. Consultation des Statistiques**
```python
# Obtenir les stats d'une métrique
stats = performance_monitor.get_performance_stats("stt_processing")

# Résumé complet
performance_monitor.log_performance_summary()

# Détection des goulots
bottlenecks = performance_monitor.detect_bottlenecks()
```

## 🔧 OPTIMISATIONS PAR COMPOSANT

### **🎤 STT - Optimisations**
```python
# Si stt_processing > 2s :
- Réduire chunk_duration de 1.0s à 0.5s
- Optimiser la taille des fichiers WAV
- Paralléliser le traitement des chunks
- Utiliser un cache de transcription

# Si network_request > 1s :
- Augmenter le pool de connexions HTTP
- Réduire le timeout de 10s à 5s
- Implémenter un load balancer
- Vérifier la latence réseau
```

### **🔊 TTS - Optimisations**
```python
# Si tts_synthesis > 0.5s :
- Réduire la qualité audio temporairement
- Utiliser un cache TTS plus agressif
- Paralléliser la synthèse de chunks
- Optimiser la sélection de voix

# Si tts_chunk > 0.2s :
- Réduire chunk_size_ms de 200ms à 100ms
- Optimiser la conversion audio
- Utiliser un buffer de pré-génération
```

### **🧠 LLM - Optimisations**
```python
# Si llm_response > 4s :
- Réduire max_tokens de 50 à 30
- Utiliser le cache plus agressivement
- Optimiser les prompts système
- Implémenter un timeout plus court

# Si llm_api_call > 3s :
- Changer de modèle (plus rapide)
- Utiliser un endpoint plus proche
- Implémenter un fallback local
```

## 📊 DASHBOARD DE MONITORING

### **Commandes de Monitoring Temps Réel**
```bash
# Suivre les performances en temps réel
tail -f logs | grep "⏱️ PERF\|🚨 GOULOTS\|🔍 BOTTLENECK"

# Filtrer par niveau de performance
tail -f logs | grep "🐌 GOULOT\|⚠️ LENT"

# Statistiques par composant
tail -f logs | grep "📊 RÉSUMÉ PERFORMANCE" -A 10

# Compter les goulots par minute
tail -f logs | grep "🐌 GOULOT" | pv -l -i 60 > /dev/null
```

### **Alertes Automatiques**
```bash
# Le système génère automatiquement des alertes pour :
- Goulots d'étranglement critiques (> 150% seuil)
- Dégradation de performance (> 3 échecs consécutifs)
- Timeouts répétés (> 5 timeouts/minute)
- Taux de succès faible (< 90%)
```

## 🎯 OBJECTIFS DE PERFORMANCE

### **Cibles de Production**
```
🎤 STT Processing    : < 1.5s  (excellent < 1.0s)
🔊 TTS Synthesis     : < 400ms (excellent < 250ms)
🧠 LLM Response      : < 3.0s  (excellent < 2.0s)
🔗 End-to-End        : < 5.0s  (excellent < 4.0s)
📡 Network Requests  : < 800ms (excellent < 500ms)
```

### **SLA de Performance**
```
- 95% des requêtes STT < 2.0s
- 98% des requêtes TTS < 500ms
- 90% des requêtes LLM < 4.0s
- 95% du pipeline end-to-end < 6.0s
- Disponibilité > 99.5%
```

---

## 🚀 RÉSUMÉ

Le système de monitoring de performance est **complet et automatique** :

✅ **Mesures automatiques** sur tous les composants critiques
✅ **Détection intelligente** des goulots d'étranglement
✅ **Suggestions d'optimisation** contextuelles
✅ **Statistiques détaillées** avec tendances
✅ **Alertes en temps réel** pour les problèmes critiques
✅ **Dashboard de monitoring** avec commandes pratiques

**Votre système peut maintenant détecter et résoudre automatiquement les problèmes de performance !** 🎯