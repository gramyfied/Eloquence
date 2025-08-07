# 🎭 Studio Situations Pro - Système Multi-Agents LiveKit

## 📋 Vue d'ensemble

Le **Studio Situations Pro** est un système révolutionnaire de simulation professionnelle utilisant plusieurs agents IA en temps réel via LiveKit WebRTC. Il permet aux utilisateurs de s'entraîner dans des situations professionnelles réalistes avec des agents IA ayant des personnalités distinctes.

## 🏗️ Architecture Complète

### 1. Architecture Multi-Couches

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │         Studio Situations Pro UI                      │    │
│  │  • Avatars animés avec effet de lueur                │    │
│  │  • Interface multi-agents interactive                 │    │
│  │  • Gestion des événements temps réel                 │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            │ WebSocket/WebRTC
┌───────────────────────────▼─────────────────────────────────┐
│                    HAProxy Load Balancer                     │
│                   (Round-robin, Health checks)               │
└──────┬──────────┬──────────┬──────────┬────────────────────┘
       │          │          │          │
┌──────▼────┐ ┌──▼────┐ ┌──▼────┐ ┌──▼────┐
│ Agent 1   │ │Agent 2│ │Agent 3│ │Agent 4│  ◄── 4 instances
│ Port:9091 │ │ :9092 │ │ :9093 │ │ :9094 │      Docker
└───────────┘ └───────┘ └───────┘ └───────┘
       │          │          │          │
       └──────────┴──────────┴──────────┘
                       │
           ┌───────────▼──────────┐
           │    Redis Cluster     │ ◄── Coordination
           │  (État partagé)      │     inter-agents
           └──────────────────────┘
                       │
           ┌───────────▼──────────┐
           │   LiveKit Server     │ ◄── WebRTC Media
           │    (Audio/Video)     │     Server
           └──────────────────────┘
```

### 2. Types de Simulations Disponibles

#### 📺 **Débat Télévisé** (`tv_debate`)
- **Agents**: Animateur, Expert Tech, Expert Social, Journaliste
- **Objectif**: S'entraîner à argumenter et débattre en public
- **Personnalités**:
  - Animateur: Neutre, structuré, gère le temps
  - Expert Tech: Enthousiaste, visionnaire
  - Expert Social: Prudent, éthique
  - Journaliste: Critique, investigateur

#### 📰 **Interview Journalistique** (`journalism`)
- **Agents**: Journaliste Senior, Journaliste Junior, Rédacteur en Chef
- **Objectif**: Préparer des interviews médiatiques
- **Personnalités**:
  - Senior: Questions incisives, expérimenté
  - Junior: Curieux, questions de clarification
  - Rédacteur: Vue d'ensemble, angles éditoriaux

#### 🏢 **Réunion d'Entreprise** (`corporate_meeting`)
- **Agents**: CEO, Manager, Directeur Technique
- **Objectif**: Présenter des projets, négocier des budgets
- **Personnalités**:
  - CEO: Vision stratégique, ROI
  - Manager: Opérationnel, pratique
  - Directeur Tech: Faisabilité technique

#### 👔 **Entretien RH** (`hr_interview`)
- **Agents**: DRH, Manager, Psychologue
- **Objectif**: S'entraîner aux entretiens d'embauche
- **Personnalités**:
  - DRH: Questions comportementales
  - Manager: Compétences techniques
  - Psychologue: Soft skills, stress test

#### 💼 **Pitch Commercial** (`sales_pitch`)
- **Agents**: Directeur Commercial, Directeur Produit, Directeur Financier
- **Objectif**: Perfectionner ses présentations commerciales
- **Personnalités**:
  - Commercial: Persuasif, bénéfices client
  - Produit: Caractéristiques, innovation
  - Financier: Prix, ROI, contrats

## 🚀 Fonctionnalités Clés

### 1. Système Multi-Agents Intelligent
- **Jusqu'à 12 agents simultanés** (3 par instance × 4 instances)
- **Personnalités distinctes** avec profils psychologiques
- **Interactions contextuelles** basées sur le rôle
- **Mémoire de conversation** via Redis

### 2. Interface Flutter Avancée
- **Avatars animés** avec effet de lueur pulsante
- **Indicateurs visuels** d'état (parle, écoute, réfléchit)
- **Timeline interactive** des échanges
- **Contrôles de session** (pause, stop, replay)

### 3. Infrastructure Scalable
- **Load balancing** HAProxy pour distribution de charge
- **Auto-scaling** basé sur les métriques
- **Health checks** automatiques
- **Failover** et résilience

### 4. Monitoring Complet
- **Métriques Prometheus** en temps réel
- **Dashboards Grafana** personnalisés
- **Alertes automatiques** sur seuils critiques
- **Logs centralisés** avec correlation ID

## 📊 Métriques de Performance

### Critères de Validation
- ✅ **Latence P95 < 2 secondes**
- ✅ **Taux de succès > 95%**
- ✅ **Débit > 10 messages/seconde**
- ✅ **Support de 20 sessions simultanées**
- ✅ **60 agents actifs en parallèle**

### Monitoring en Temps Réel
```yaml
Métriques surveillées:
- agent_requests_total: Requêtes totales par agent
- agent_response_time_seconds: Temps de réponse
- active_agents_total: Agents actifs
- concurrent_sessions_total: Sessions simultanées
- ai_tokens_used_total: Consommation tokens IA
- webrtc_connection_failures: Échecs WebRTC
```

## 🛠️ Guide de Déploiement

### 1. Prérequis
```bash
- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- Clés API: OpenAI, Mistral
```

### 2. Déploiement Rapide
```powershell
# Windows PowerShell
.\scripts\deploy-multiagent.ps1 -Mode production -WithMonitoring -RunTests

# Linux/Mac
./scripts/deploy-multiagent.sh --mode production --with-monitoring --run-tests
```

### 3. URLs d'Accès
- **Application**: http://localhost:8080
- **LiveKit Server**: http://localhost:7880
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **HAProxy Stats**: http://localhost:8404/stats

## 🧪 Tests et Validation

### Tests Unitaires
```bash
# Backend Python
pytest services/livekit-agent/tests/

# Frontend Flutter
flutter test
```

### Tests de Charge
```bash
# 20 sessions simultanées, 3 agents par session
python tests/load_testing/multiagent_load_test.py
```

### Tests d'Intégration
```bash
# Test complet du système
python tests/integration/test_multiagent_system_complete.py
```

## 📁 Structure des Fichiers

```
eloquence/
├── frontend/flutter_app/
│   └── lib/features/studio_situations_pro/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── agent_entity.dart
│       │   │   └── simulation_entity.dart
│       │   └── repositories/
│       ├── data/
│       │   ├── models/
│       │   └── services/
│       │       └── studio_situations_pro_service.dart
│       └── presentation/
│           ├── screens/
│           │   ├── studio_situations_home_screen.dart
│           │   └── simulation_room_screen.dart
│           └── widgets/
│               ├── agent_avatar_widget.dart
│               └── multi_agent_interface_widget.dart
│
├── services/livekit-agent/
│   ├── multi_agent_manager.py
│   ├── multi_agent_config.py
│   ├── metrics_exporter.py
│   ├── Dockerfile.multiagent
│   └── tests/
│
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── alerts/
│   └── grafana/
│       ├── dashboards/
│       └── provisioning/
│
├── docker-compose.multiagent.yml
├── services/haproxy/haproxy.cfg
│
├── tests/
│   ├── load_testing/
│   │   └── multiagent_load_test.py
│   └── integration/
│       └── test_multiagent_system_complete.py
│
└── scripts/
    └── deploy-multiagent.ps1
```

## 🔧 Configuration Avancée

### Variables d'Environnement
```env
# LiveKit
LIVEKIT_API_KEY=your_key
LIVEKIT_API_SECRET=your_secret
LIVEKIT_URL=ws://localhost:7880

# Redis
REDIS_URL=redis://redis:6379

# IA
OPENAI_API_KEY=your_openai_key
MISTRAL_API_KEY=your_mistral_key

# Performance
MAX_WORKERS=4
MAX_AGENTS_PER_WORKER=10
AGENT_TIMEOUT=30
```

### Personnalisation des Agents
```python
# services/livekit-agent/multi_agent_config.py
CUSTOM_AGENT = {
    "id": "custom_expert",
    "name": "Expert Custom",
    "personality": {
        "traits": ["analytical", "detail-oriented"],
        "speaking_style": "technical",
        "response_length": "detailed"
    }
}
```

## 🎯 Cas d'Usage

### 1. Formation Professionnelle
- Préparation aux entretiens
- Amélioration de la prise de parole
- Gestion du stress

### 2. Éducation
- Débats académiques
- Présentations de projets
- Examens oraux

### 3. Entreprise
- Onboarding nouveaux employés
- Formation commerciale
- Préparation de pitchs

## 📈 Roadmap Future

### Version 2.0 (Q2 2024)
- [ ] Support vidéo avec avatars 3D
- [ ] Analyse sentimentale en temps réel
- [ ] Personnalisation vocale des agents
- [ ] Export des sessions en vidéo

### Version 3.0 (Q3 2024)
- [ ] Agents multilingues
- [ ] Scénarios adaptatifs par ML
- [ ] Intégration VR/AR
- [ ] Analytics avancés

## 🤝 Support et Contribution

### Support
- Documentation: `/docs`
- Issues: GitHub Issues
- Email: support@eloquence.ai

### Contribution
1. Fork le repository
2. Créer une branche feature
3. Commiter les changements
4. Push et créer une PR

## 📜 Licence

MIT License - Voir LICENSE.md

---

**Développé avec ❤️ par l'équipe Eloquence**

*Version 1.0.0 - Studio Situations Pro Multi-Agents*