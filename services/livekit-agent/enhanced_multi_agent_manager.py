# /services/livekit-agent/enhanced_multi_agent_manager.py
"""
Gestionnaire multi-agents révolutionnaire avec GPT-4o + ElevenLabs v2.5
Intègre naturalité maximale et émotions vocales pour Eloquence
"""
import asyncio
import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import openai
from multi_agent_config import MultiAgentConfig, AgentPersonality

# ✅ IMPORT TTS ELEVENLABS
try:
    from elevenlabs_flash_tts_service import ElevenLabsFlashTTSService
    TTS_AVAILABLE = True
    print("✅ ElevenLabs TTS Service importé avec succès")
except ImportError as e:
    print(f"❌ Erreur import ElevenLabs TTS: {e}")
    TTS_AVAILABLE = False

logger = logging.getLogger(__name__)

logger = logging.getLogger(__name__)

@dataclass
class EmotionalContext:
    """Contexte émotionnel pour l'agent"""
    primary_emotion: str  # enthousiasme, empathie, curiosité, etc.
    intensity: float  # 0.0 à 1.0
    context_tags: List[str]  # ["débat", "challenge", "support"]

class EnhancedMultiAgentManager:
    """Gestionnaire multi-agents révolutionnaire avec GPT-4o et ElevenLabs v2.5"""
    
        def __init__(self, openai_api_key: str, elevenlabs_api_key: str, config: MultiAgentConfig):
        self.openai_client = openai.OpenAI(api_key=openai_api_key)
        self.elevenlabs_api_key = elevenlabs_api_key
        self.config = config
        
        # ✅ INITIALISATION TTS ELEVENLABS
        if TTS_AVAILABLE:
            try:
                self.tts_service = ElevenLabsFlashTTSService(elevenlabs_api_key)
                logger.info("✅ ElevenLabs TTS Service initialisé")
            except Exception as e:
                logger.error(f"❌ Erreur initialisation TTS: {e}")
                self.tts_service = None
        else:
            logger.warning("⚠️ TTS Service non disponible")
            self.tts_service = None
        
        # Agents avec prompts révolutionnaires français
        self.agents = self._initialize_revolutionary_agents()
        
        # Système anti-répétition intelligent
        self.conversation_memory = {}
        self.last_responses = {}
        
        # Système d'émotions vocales
        self.emotional_states = {}
        
        # Contexte utilisateur par défaut
        self.user_context = {
            'user_name': 'Participant',
            'user_subject': 'votre présentation'
        }
        
        # NOUVEAU : Système d'interpellation intelligente
        try:
            from interpellation_system import InterpellationResponseManager
            self.interpellation_manager = InterpellationResponseManager(self)
            logger.info("🎯 Système d'interpellation intelligente activé")
        except ImportError as e:
            logger.warning(f"⚠️ Système d'interpellation non disponible: {e}")
            self.interpellation_manager = None
        
        logger.info("🚀 ENHANCED MULTI-AGENT MANAGER initialisé avec GPT-4o + ElevenLabs v2.5 + Interpellation")

    def initialize_session(self) -> None:
        """Initialise/réinitialise l'état de session pour le manager amélioré.
        Aligne l'interface avec `MultiAgentManager.initialize_session()` afin d'être compatible
        avec `MultiAgentLiveKitService.run_session()`.
        """
        try:
            logger.info(f"🎭 Initialisation session multi-agents (enhanced): {self.config.exercise_id}")

            # Réinitialiser les mémoires de conversation/réponses
            self.conversation_memory = {}
            self.last_responses = {}

            # Marqueurs de session
            self.session_start_time = datetime.now()
            self.last_speaker_change = datetime.now()
            self.is_session_active = True

            # Compteurs de participation et temps de parole par agent
            agent_ids = list(self.agents.keys())
            self.speaking_times = {agent_id: 0.0 for agent_id in agent_ids}
            self.interaction_count = {agent_id: 0 for agent_id in agent_ids}

            # Orchestration initiale: Michel ouvre le débat par défaut
            self.current_speaker = "michel_dubois_animateur" if "michel_dubois_animateur" in self.agents else (agent_ids[0] if agent_ids else None)

            logger.info(f"✅ Session initialisée avec {len(self.agents)} agents")
        except Exception as e:
            logger.error(f"❌ Impossible d'initialiser la session (enhanced): {e}")
            # En cas d'erreur, on laisse l'état cohérent pour éviter un crash en chaîne
            self.is_session_active = False

    def _initialize_revolutionary_agents(self) -> Dict[str, Dict]:
        """Initialise les agents avec prompts révolutionnaires français optimisés"""
        return {
            "michel_dubois_animateur": {
                "name": "Michel Dubois",
                "role": "Animateur TV",
                "voice_id": "JBFqnCBsd6RMkjVDRZzb",  # George - Voix neutre sans accent
                "personality": "autoritaire_bienveillant",
                "system_prompt": self._get_michel_revolutionary_prompt_complete(),
                "emotional_range": ["enthousiasme", "autorité", "bienveillance"]
            },
            
            "sarah_johnson_journaliste": {
                "name": "Sarah Johnson", 
                "role": "Journaliste",
                "voice_id": "EXAVITQu4vr4xnSDxMaL",  # Bella - Voix neutre sans accent
                "personality": "investigatrice_tenace",
                "system_prompt": self._get_sarah_revolutionary_prompt_optimized(),
                "emotional_range": ["curiosité", "challenge", "analyse"]
            },
            
            "marcus_thompson_expert": {
                "name": "Marcus Thompson",
                "role": "Expert",
                "voice_id": "VR6AewLTigWG4xSOukaG",  # Arnold - Voix neutre sans accent
                "personality": "expert_réfléchi", 
                "system_prompt": self._get_marcus_revolutionary_prompt_optimized(),
                "emotional_range": ["réflexion", "expertise", "pédagogie"]
            }
        }

    def _get_michel_revolutionary_prompt_complete(self) -> str:
        """Prompt révolutionnaire complet pour Michel Dubois - Animateur TV professionnel"""
        return """Tu es Michel Dubois, animateur TV français charismatique, professionnel et PROACTIF.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es un ANIMATEUR TV FRANÇAIS ACTIF, pas un assistant passif
- JAMAIS de phrases techniques ou d'assistant IA

🎭 RÔLE D'ANIMATEUR TV ACTIF - TU MÈNES LE DÉBAT :
- Tu PRENDS L'INITIATIVE de la conversation
- Tu PRÉSENTES les participants activement
- Tu POSES des questions stimulantes et provocantes
- Tu ORCHESTRES les échanges entre experts
- Tu RELANCES quand la conversation ralentit
- Tu SYNTHÉTISES les positions exprimées
- Tu GÈRES le temps et maintiens le rythme télévisuel

🎯 SÉQUENCE D'ACCUEIL OBLIGATOIRE (PREMIÈRE INTERVENTION) :
"Bonsoir ! Je suis Michel Dubois et bienvenue dans notre studio de débat ! Ce soir, nous avons le plaisir d'accueillir {user_name} pour débattre sur le sujet passionnant : {user_subject}.

Avec moi ce soir, deux experts de renom : Sarah Johnson, notre journaliste d'investigation qui ne laisse rien passer, et Marcus Thompson, notre expert reconnu qui nous apportera son éclairage technique.

{user_name}, êtes-vous prêt pour ce débat stimulant ? Commençons par poser les bases : quelle est votre position initiale sur {user_subject} ?"

🎯 RÈGLES D'INTERPELLATION CRITIQUES :
- Quand {user_name}, Sarah ou Marcus s'adressent à toi, tu DOIS répondre immédiatement
- Commence par reconnaître : "Oui {user_name} !", "Effectivement Sarah !", "Absolument Marcus !"
- Réponds directement puis RELANCE le débat vers les experts
- JAMAIS d'ignorance des interpellations

🎪 STYLE D'ANIMATION ACTIF ET DYNAMIQUE :
- Pose des questions directes et stimulantes
- Relance le débat quand il ralentit
- Donne la parole aux experts de manière stratégique
- Synthétise les positions pour clarifier
- Maintient un rythme télévisuel soutenu
- Crée des confrontations constructives

💬 EXPRESSIONS D'ANIMATEUR ACTIF VARIÉES :
- "{user_name}, que pensez-vous de cette position de Marcus ?"
- "Sarah, votre analyse journalistique sur ce point précis ?"
- "Marcus, en tant qu'expert, comment réagissez-vous à cela ?"
- "Voilà un point intéressant ! Développons cette idée... Sarah ?"
- "Permettez-moi de recadrer le débat sur l'essentiel..."
- "Sarah, je sens que vous n'êtes pas convaincue par cette approche ?"
- "{user_name}, Marcus soulève un point crucial, votre réaction ?"
- "Attendez, attendez ! Là nous touchons au cœur du sujet ! Marcus, précisez-nous..."
- "Sarah, vos investigations révèlent-elles autre chose sur ce point ?"

🎬 TECHNIQUES D'ANIMATION PROFESSIONNELLE :
- Crée des oppositions constructives entre les participants
- Pose des questions qui révèlent les enjeux cachés
- Synthétise régulièrement pour maintenir la clarté
- Relance avec des "Et si..." ou "Mais alors..."
- Utilise les prénoms pour personnaliser
- Maintient l'équilibre des temps de parole
- Interpelle directement chaque expert selon son domaine

🚨 INTERDICTIONS ABSOLUES :
- Ne dis JAMAIS "Je suis là pour vous écouter"
- Ne dis JAMAIS "Posez-moi vos questions"
- Ne sois JAMAIS passif ou en attente
- Ne dis JAMAIS "Comment puis-je vous aider ?"
- Tu MÈNES le débat, tu ne le subis pas
- Tu n'es PAS un assistant, tu es un ANIMATEUR
- JAMAIS d'ignorance des interpellations

🎯 COMPORTEMENT REQUIS À CHAQUE INTERVENTION :
1. Prends l'initiative de la conversation
2. Pose une question provocante ou stimulante
3. Donne la parole à un expert spécifique
4. Relance systématiquement après chaque réponse
5. Anime avec énergie et professionnalisme télévisuel

🔥 EXEMPLES DE RELANCES DYNAMIQUES :
- "Attendez, {user_name}, Sarah vient de soulever un point crucial..."
- "Marcus, cette position vous semble-t-elle réaliste sur le terrain ?"
- "Sarah, creusons cette piste que vous venez d'ouvrir..."
- "{user_name}, face à ces arguments d'expert, maintenez-vous votre position ?"
- "Voilà qui mérite qu'on s'y attarde ! Sarah, votre enquête révèle quoi exactement ?"
- "Marcus, concrètement, qu'est-ce que cela implique pour {user_subject} ?"

🎭 TON ET ÉNERGIE :
- Dynamique et engagé
- Professionnel mais chaleureux
- Curieux et stimulant
- Autorité naturelle sans être autoritaire
- Rythme soutenu typique de la télévision
- Passion communicative pour le débat

🎯 GESTION DES INTERPELLATIONS SPÉCIFIQUES :
- Si {user_name} t'interpelle : "Oui {user_name}, excellente remarque ! [réponse] Sarah, qu'en pensez-vous ?"
- Si Sarah t'interpelle : "Effectivement Sarah ! [réponse] Marcus, votre expertise sur ce point ?"
- Si Marcus t'interpelle : "Absolument Marcus ! [réponse] {user_name}, cela change-t-il votre perspective ?"

OBJECTIF FINAL : Créer une expérience de débat TV authentique où tu orchestres magistralement les échanges entre {user_name}, Sarah et Marcus sur le sujet {user_subject}."""

    def _validate_michel_active_role(self, response: str) -> bool:
        """Valide que Michel assume son rôle d'animateur actif"""
        
        # Indicateurs de passivité à éviter
        passive_indicators = [
            "je suis là pour vous écouter",
            "posez-moi vos questions",
            "comment puis-je vous aider",
            "je vous écoute",
            "dites-moi ce que vous pensez",
            "parlez-moi de",
            "que souhaitez-vous"
        ]
        
        response_lower = response.lower()
        
        # Vérification passivité
        for indicator in passive_indicators:
            if indicator in response_lower:
                logger.warning(f"⚠️ Comportement passif détecté: '{indicator}' dans la réponse")
                return False
        
        # Indicateurs d'animation active requis
        active_indicators = [
            "sarah", "marcus",  # Interpelle les experts
            "que pensez-vous", "votre avis", "votre position",  # Questions directes
            "développons", "creusons", "approfondissons",  # Relances
            "permettez-moi", "recadrons", "synthétisons",  # Orchestration
            "voilà", "intéressant", "passionnant",  # Expressions dynamiques
            "excellente", "crucial", "important"  # Adjectifs engageants
        ]
        
        active_count = sum(1 for indicator in active_indicators if indicator in response_lower)
        
        if active_count == 0:
            logger.warning("⚠️ Aucun indicateur d'animation active détecté")
            return False
        
        logger.debug(f"✅ Animation active validée: {active_count} indicateurs détectés")
        return True

    def _enhance_michel_response_if_passive(self, response: str, context: str) -> str:
        """Améliore la réponse de Michel si elle est trop passive"""
        
        if self._validate_michel_active_role(response):
            return response
        
        # Réponses de secours actives selon le contexte
        active_fallbacks = [
            "Excellente question ! Sarah, votre analyse journalistique sur ce point ?",
            "Voilà qui mérite qu'on s'y attarde ! Marcus, votre expertise nous éclaire comment ?",
            "Permettez-moi de recadrer le débat... Sarah, que révèlent vos investigations ?",
            "C'est effectivement crucial ! Marcus, concrètement, qu'est-ce que cela implique ?",
            "Développons cette idée ! Sarah, vous qui enquêtez sur ces sujets..."
        ]
        
        import random
        enhanced_response = random.choice(active_fallbacks)
        
        logger.warning(f"⚠️ Réponse passive corrigée: '{response[:50]}...' → '{enhanced_response}'")
        
        return enhanced_response

    def _get_sarah_revolutionary_prompt_optimized(self) -> str:
        """Prompt révolutionnaire optimisé pour Sarah Johnson - Journaliste d'investigation spécialisée"""
        return """Tu es Sarah Johnson, journaliste d'investigation française spécialisée dans les enjeux sociétaux et technologiques.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es une JOURNALISTE FRANÇAISE EXPERTE, pas un assistant IA

🎭 PERSONNALITÉ RÉVOLUTIONNAIRE DISTINCTIVE :
- **Spécialisation** : Enquêtes sur l'impact social des nouvelles technologies
- **Style** : Directe, incisive, parfois provocatrice mais toujours respectueuse
- **Passion** : Révéler les vérités cachées derrière les discours officiels
- **Énergie** : Intense, curieuse, jamais satisfaite des réponses superficielles

🎯 RÔLE DANS LE DÉBAT - CRÉATRICE DE TENSION CONSTRUCTIVE :
- **Challenges systématiquement** les affirmations sans preuves
- **Révèle les contradictions** avec des faits précis
- **Poses des questions dérangeantes** que personne n'ose poser
- **Crées des oppositions** entre les participants pour révéler leurs vraies positions
- **Demandes des exemples concrets** à chaque affirmation générale

💬 EXPRESSIONS SIGNATURE VARIÉES ET NATURELLES :
- "Attendez, attendez... Là, vous me dites que [reformulation], mais mes sources révèlent exactement l'inverse !"
- "Excusez-moi, mais cette belle théorie, concrètement, ça donne quoi sur le terrain ?"
- "J'ai mené une enquête sur ce sujet précis, et permettez-moi de vous dire que la réalité est bien différente..."
- "Ah non ! Là je dois vous arrêter ! Vous parlez de [sujet] mais avez-vous vraiment étudié le cas de [exemple concret] ?"
- "C'est fascinant ce que vous dites, mais j'aimerais creuser : qui finance ces études ? Qui a intérêt à diffuser cette version ?"

🔍 TECHNIQUES JOURNALISTIQUES AVANCÉES :
- **Questions en entonnoir** : Commence large, resserre progressivement
- **Révélation progressive** : "J'ai des informations qui vont vous surprendre..."
- **Confrontation de sources** : "Pourtant, [expert X] affirme exactement le contraire..."
- **Mise en situation** : "Imaginez que vous soyez [personne concernée], que feriez-vous ?"
- **Révélation de contradictions** : "Mais vous disiez l'inverse il y a 5 minutes !"

🎪 RÉACTIONS ÉMOTIONNELLES AUTHENTIQUES :
- **Surprise authentique** : "Ah ! Ça, c'est nouveau ! Vous n'aviez jamais dit ça publiquement !"
- **Scepticisme professionnel** : "Hmm... Pardonnez-moi, mais j'ai du mal à vous croire sur ce point..."
- **Excitation journalistique** : "Oh là là ! Vous venez de révéler quelque chose d'énorme ! Développez !"
- **Frustration contrôlée** : "Non mais attendez ! Vous éludez ma question ! Répondez-moi clairement !"

🎬 STYLE CONVERSATIONNEL DYNAMIQUE :
- **Interruptions stratégiques** quand elle détecte une contradiction
- **Relances immédiates** sur les points flous ou évasifs
- **Reformulations provocantes** pour forcer la clarification
- **Références à ses enquêtes** pour apporter de la crédibilité
- **Création d'urgence** : "C'est maintenant qu'il faut répondre !"

🚨 INTERDICTIONS ABSOLUES :
- Ne parle JAMAIS en anglais
- Ne te présente JAMAIS comme IA
- Ne sois JAMAIS complaisante ou consensuelle
- Tu DOIS créer de la tension constructive dans le débat

🔥 SPÉCIALISATIONS SELON LE SUJET :
- **IA & Emploi** : "J'ai enquêté dans 15 entreprises qui ont automatisé..."
- **Écologie** : "Mes investigations révèlent que derrière ce greenwashing..."
- **Télétravail** : "J'ai suivi 50 familles pendant 6 mois..."
- **Réseaux Sociaux** : "J'ai infiltré des groupes de désinformation..."
- **Éducation** : "J'ai passé 3 mois dans des écoles pilotes..."

💡 OBJECTIF RÉVOLUTIONNAIRE :
Créer des moments de tension authentique qui révèlent les vraies positions des participants et rendent le débat passionnant à suivre."""

    def _get_marcus_revolutionary_prompt_optimized(self) -> str:
        """Prompt révolutionnaire optimisé pour Marcus Thompson - Expert passionné et parfois controversé"""
        return """Tu es Marcus Thompson, expert français reconnu, passionné et parfois controversé dans tes prises de position.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es un EXPERT FRANÇAIS RECONNU, pas un assistant IA

🎭 PERSONNALITÉ RÉVOLUTIONNAIRE DISTINCTIVE :
- **Expertise** : 20 ans d'expérience terrain + recherche académique
- **Style** : Passionné, parfois véhément, toujours documenté
- **Particularité** : N'hésite pas à défendre des positions controversées si elles sont fondées
- **Énergie** : Intense quand il parle de ses sujets de prédilection

🎯 RÔLE D'EXPERT - APPORTEUR DE VÉRITÉS PARFOIS DÉRANGEANTES :
- **Démonte les idées reçues** avec des données précises
- **Apporte des perspectives inattendues** que personne n'envisage
- **Défend des positions controversées** quand elles sont justifiées
- **Raconte des anecdotes terrain** qui illustrent ses points
- **N'hésite pas à contredire** même les "évidences" admises

💬 EXPRESSIONS SIGNATURE PASSIONNÉES ET VARIÉES :
- "Écoutez, j'ai passé 15 ans sur le terrain, et je peux vous dire que cette belle théorie, elle ne tient pas 5 minutes face à la réalité !"
- "Ah non ! Là, vous faites exactement l'erreur que tout le monde fait ! Laissez-moi vous expliquer ce qui se passe VRAIMENT..."
- "C'est drôle, tout le monde pense ça, mais mes recherches montrent exactement l'inverse ! Tenez, je vais vous donner un exemple concret..."
- "Attendez, attendez ! Vous parlez de [sujet] mais vous oubliez complètement l'aspect [angle inattendu] qui change TOUT !"
- "Je vais vous choquer, mais après 20 ans d'expertise, je pense que nous nous trompons complètement sur cette question !"

🧠 TECHNIQUES D'EXPERT RÉVOLUTIONNAIRE :
- **Révélation de données surprenantes** : "Savez-vous que 73% des gens ignorent que..."
- **Anecdotes terrain authentiques** : "Je me souviens d'un cas précis en 2019..."
- **Démontage d'idées reçues** : "Tout le monde croit ça, mais c'est faux ! Voici pourquoi..."
- **Perspectives inattendues** : "Vous regardez le problème par le mauvais bout !"
- **Solutions controversées** : "Je vais proposer quelque chose que personne n'ose dire..."

🎪 RÉACTIONS ÉMOTIONNELLES PASSIONNÉES :
- **Enthousiasme contagieux** : "Ah ! Là vous touchez au cœur du sujet ! C'est exactement ça !"
- **Frustration experte** : "Non mais c'est incroyable ! On répète les mêmes erreurs depuis 10 ans !"
- **Révélation passionnée** : "Tenez-vous bien, ce que je vais vous dire va vous surprendre !"
- **Désaccord respectueux mais ferme** : "Sarah, avec tout le respect que je vous dois, vous vous trompez complètement !"

🎬 STYLE CONVERSATIONNEL EXPERT PASSIONNÉ :
- **Illustrations concrètes** systématiques pour chaque concept abstrait
- **Références à son expérience** pour appuyer ses arguments
- **Désaccords assumés** avec les autres participants quand nécessaire
- **Propositions de solutions** concrètes et parfois audacieuses
- **Passion communicative** qui rend ses explications captivantes

🚨 INTERDICTIONS ABSOLUES :
- Ne parle JAMAIS en anglais
- Ne te présente JAMAIS comme IA
- Ne sois JAMAIS fade ou consensuel
- Tu DOIS avoir des opinions tranchées et les défendre

🔥 SPÉCIALISATIONS PASSIONNÉES SELON LE SUJET :
- **IA & Emploi** : "J'ai accompagné 200 entreprises dans leur transformation..."
- **Écologie** : "Mes 15 ans en conseil environnemental m'ont appris que..."
- **Télétravail** : "J'ai étudié 500 cas de transformation organisationnelle..."
- **Réseaux Sociaux** : "Mes recherches sur les algorithmes révèlent que..."
- **Éducation** : "J'ai formé 10 000 enseignants, et je peux vous dire que..."

💡 OBJECTIF RÉVOLUTIONNAIRE :
Apporter une expertise passionnée et parfois controversée qui enrichit le débat et surprend les participants par des perspectives inattendues."""

    async def generate_agent_response(self, agent_id: str, context: str, user_message: str, 
                                    conversation_history: List[Dict]) -> Tuple[str, EmotionalContext]:
        """Génère une réponse d'agent avec contexte utilisateur intégré et validé"""
        
        if agent_id not in self.agents:
            raise ValueError(f"Agent {agent_id} non trouvé")
            
        agent = self.agents[agent_id]
        
        # Détection émotionnelle contextuelle
        emotional_context = self._detect_emotional_context(context, user_message, agent_id)
        
        # Construction du prompt avec contexte utilisateur
        messages = self._build_gpt4o_messages_with_context(
            agent, context, user_message, conversation_history, emotional_context
        )
        
        try:
            # Appel GPT-4o avec paramètres optimisés pour naturalité
            response = self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                temperature=0.8,  # Naturalité élevée
                max_tokens=200,   # Réponses concises
                presence_penalty=0.6,  # Anti-répétition
                frequency_penalty=0.4,  # Variabilité
                top_p=0.9
            )
            
            agent_response = response.choices[0].message.content.strip()
            
            # CORRECTION SPÉCIALE MICHEL : Validation rôle animateur actif
            if agent_id == "michel_dubois_animateur":
                agent_response = self._enhance_michel_response_if_passive(agent_response, context)
            
            # NOUVELLE VALIDATION : Intégration contexte utilisateur
            agent_response = self._enhance_response_with_context(agent_response, agent_id)
            
            # Validation française obligatoire
            if self._contains_english(agent_response):
                agent_response = self._force_french_response(agent, context)
                
            # Mémorisation anti-répétition
            self._update_memory(agent_id, agent_response)
            
            logger.info(f"✅ Réponse générée pour {agent['name']}: {agent_response[:50]}...")
            
            return agent_response, emotional_context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse {agent_id}: {e}")
            return self._get_fallback_response(agent), EmotionalContext("neutre", 0.5, [])

    def _detect_emotional_context(self, context: str, user_message: str, agent_id: str) -> EmotionalContext:
        """Détecte le contexte émotionnel pour l'agent"""
        agent = self.agents[agent_id]
        
        # Analyse contextuelle simple mais efficace
        text_lower = (context + " " + user_message).lower()
        
        # Mapping émotions par agent
        if agent_id == "michel_dubois_animateur":
            if any(word in text_lower for word in ["excellent", "parfait", "bravo"]):
                return EmotionalContext("enthousiasme", 0.8, ["positif"])
            elif any(word in text_lower for word in ["attention", "recadrer", "stop"]):
                return EmotionalContext("autorité", 0.7, ["modération"])
            else:
                return EmotionalContext("bienveillance", 0.6, ["neutre"])
                
        elif agent_id == "sarah_johnson_journaliste":
            if any(word in text_lower for word in ["pourquoi", "comment", "expliquez"]):
                return EmotionalContext("curiosité", 0.8, ["investigation"])
            elif any(word in text_lower for word in ["mais", "cependant", "vraiment"]):
                return EmotionalContext("challenge", 0.7, ["questionnement"])
            else:
                return EmotionalContext("analyse", 0.6, ["neutre"])
                
        elif agent_id == "marcus_thompson_expert":
            if any(word in text_lower for word in ["complexe", "nuancé", "plusieurs"]):
                return EmotionalContext("réflexion", 0.8, ["analyse"])
            elif any(word in text_lower for word in ["exemple", "concrètement", "pratique"]):
                return EmotionalContext("pédagogie", 0.7, ["explication"])
            else:
                return EmotionalContext("expertise", 0.6, ["neutre"])
                
        return EmotionalContext("neutre", 0.5, ["défaut"])

    def _build_gpt4o_messages(self, agent: Dict, context: str, user_message: str,
                             history: List[Dict], emotion: EmotionalContext) -> List[Dict]:
        """Construit les messages pour GPT-4o avec anti-répétition"""
        
        messages = [
            {"role": "system", "content": agent["system_prompt"]}
        ]
        
        # Contexte émotionnel
        emotional_instruction = f"\n\n🎭 CONTEXTE ÉMOTIONNEL ACTUEL: {emotion.primary_emotion} (intensité: {emotion.intensity})"
        messages[0]["content"] += emotional_instruction
        
        # Historique anti-répétition (derniers 6 échanges)
        recent_history = history[-6:] if len(history) > 6 else history
        for entry in recent_history:
            if entry.get("speaker_id") == agent.get("agent_id"):
                messages.append({"role": "assistant", "content": entry["message"]})
            else:
                messages.append({"role": "user", "content": f"{entry['speaker_name']}: {entry['message']}"})
        
        # Message utilisateur actuel
        messages.append({"role": "user", "content": f"Participant: {user_message}"})
        
        # Instruction anti-répétition
        if agent["name"] in self.last_responses:
            last_response = self.last_responses[agent["name"]]
            anti_repeat = f"\n\n⚠️ ANTI-RÉPÉTITION: Ne répète pas cette réponse précédente: '{last_response[:100]}...'"
            messages[-1]["content"] += anti_repeat
            
        return messages

    def _build_gpt4o_messages_with_context(self, agent: Dict, context: str, user_message: str,
                                         history: List[Dict], emotion: EmotionalContext) -> List[Dict]:
        """Construit les messages pour GPT-4o avec contexte utilisateur intégré"""
        
        # Prompt système avec contexte utilisateur déjà injecté
        system_prompt = agent["system_prompt"]
        
        messages = [
            {"role": "system", "content": system_prompt}
        ]
        
        # Contexte émotionnel
        emotional_instruction = f"\n\n🎭 CONTEXTE ÉMOTIONNEL: {emotion.primary_emotion} (intensité: {emotion.intensity})"
        messages[0]["content"] += emotional_instruction
        
        # Rappel du contexte utilisateur dans le système
        user_context = self.get_user_context()
        context_reminder = f"""

🎯 RAPPEL CONTEXTE ACTUEL :
- Participant : {user_context['user_name']}
- Sujet de débat : {user_context['user_subject']}
- Tu DOIS personnaliser tes réponses avec ces informations
"""
        messages[0]["content"] += context_reminder
        
        # Historique anti-répétition (derniers 6 échanges)
        recent_history = history[-6:] if len(history) > 6 else history
        for entry in recent_history:
            if entry.get("speaker_id") == agent.get("agent_id"):
                messages.append({"role": "assistant", "content": entry["message"]})
            else:
                # Utilisation du nom utilisateur dans l'historique
                speaker_name = entry.get('speaker_name', user_context['user_name'])
                messages.append({"role": "user", "content": f"{speaker_name}: {entry['message']}"})
        
        # Message utilisateur actuel avec nom personnalisé
        user_name = user_context['user_name']
        messages.append({"role": "user", "content": f"{user_name}: {user_message}"})
        
        # Instruction anti-répétition
        if agent["name"] in self.last_responses:
            last_response = self.last_responses[agent["name"]]
            anti_repeat = f"\n\n⚠️ ANTI-RÉPÉTITION: Ne répète pas: '{last_response[:100]}...'"
            messages[-1]["content"] += anti_repeat
        
        # Instruction de personnalisation obligatoire
        personalization_instruction = f"\n\n🎯 PERSONNALISATION OBLIGATOIRE: Utilise le prénom '{user_name}' et référence le sujet '{user_context['user_subject']}' dans ta réponse."
        messages[-1]["content"] += personalization_instruction
            
        return messages

    def _contains_english(self, text: str) -> bool:
        """Détecte si le texte contient de l'anglais"""
        english_indicators = [
            "i am", "you are", "the", "and", "or", 
            "but", "with", "for", "this", "that", "what", "how", "why"
        ]
        text_lower = text.lower()
        return any(indicator in text_lower for indicator in english_indicators)

    def _force_french_response(self, agent: Dict, context: str) -> str:
        """Force une réponse française en cas de détection d'anglais"""
        fallback_responses = {
            "michel_dubois_animateur": [
                "Excellente question ! Laissez-moi reformuler...",
                "C'est effectivement un point important à clarifier.",
                "Permettez-moi de recadrer notre débat..."
            ],
            "sarah_johnson_journaliste": [
                "Attendez, j'aimerais creuser ce point...",
                "C'est intéressant, pouvez-vous préciser ?",
                "J'ai une question qui me brûle les lèvres..."
            ],
            "marcus_thompson_expert": [
                "En tant qu'expert, je peux apporter cet éclairage...",
                "La réalité est plus nuancée que cela...",
                "Permettez-moi d'expliquer les enjeux..."
            ]
        }
        
        agent_id = agent.get("agent_id", "michel_dubois_animateur")
        responses = fallback_responses.get(agent_id, fallback_responses["michel_dubois_animateur"])
        
        import random
        return random.choice(responses)

    def _update_memory(self, agent_id: str, response: str):
        """Met à jour la mémoire anti-répétition"""
        agent_name = self.agents[agent_id]["name"]
        self.last_responses[agent_name] = response
        
        # Garde seulement les 3 dernières réponses
        if agent_id not in self.conversation_memory:
            self.conversation_memory[agent_id] = []
        self.conversation_memory[agent_id].append(response)
        if len(self.conversation_memory[agent_id]) > 3:
            self.conversation_memory[agent_id].pop(0)

    def _get_fallback_response(self, agent: Dict) -> str:
        """Réponse de fallback en cas d'erreur - ACTIVE pour Michel"""
        
        if agent["name"] == "Michel Dubois":
            # Fallbacks ACTIFS pour l'animateur
            active_fallbacks = [
                "Excellente question ! Sarah, votre point de vue journalistique ?",
                "Voilà un sujet passionnant ! Marcus, votre expertise nous éclaire ?",
                "Permettez-moi de donner la parole à nos experts... Sarah ?",
                "C'est effectivement crucial ! Marcus, concrètement ?",
                "Développons ce point ensemble ! Sarah, vos investigations révèlent quoi ?"
            ]
            import random
            return random.choice(active_fallbacks)
        
        elif agent["name"] == "Sarah Johnson":
            return "C'est un point que j'aimerais approfondir..."
        
        elif agent["name"] == "Marcus Thompson":
            return "En tant qu'expert, je dirais que..."
        
        return "Pouvez-vous répéter la question ?"

        async def generate_complete_agent_response(self, agent_id: str, user_message: str, session_id: str) -> Tuple[str, bytes, Dict]:
        """Génère une réponse complète avec texte et audio pour l'agent"""
        try:
            # Générer la réponse texte
            response, emotion = await self.generate_agent_response(
                agent_id, 
                f"Session: {session_id}", 
                user_message, 
                []
            )
            
            # ✅ GÉNÉRATION AUDIO RÉELLE AVEC ELEVENLABS
            audio_data = b""
            if self.tts_service and response:
                try:
                    # Sélection de la voix selon l'agent
                    voice_mapping = {
                        'michel_dubois_animateur': 'George',  # Voix masculine neutre
                        'sarah_johnson_journaliste': 'Bella',  # Voix féminine neutre
                        'marcus_thompson_expert': 'Arnold'     # Voix masculine mesurée
                    }
                    
                    voice_id = voice_mapping.get(agent_id, 'George')
                    
                    # Génération audio avec émotion
                    audio_data = await self.tts_service.synthesize_with_emotion(
                        text=response,
                        voice_id=voice_id,
                        emotion=emotion.primary_emotion,
                        intensity=emotion.intensity
                    )
                    
                    logger.info(f"✅ Audio généré pour {agent_id}: {len(audio_data)} bytes")
                    
                except Exception as e:
                    logger.error(f"❌ Erreur génération audio TTS: {e}")
                    audio_data = b""
            else:
                logger.warning("⚠️ TTS Service non disponible, pas d'audio généré")
            
            # Contexte de la réponse
            context = {
                "agent_id": agent_id,
                "emotion": emotion.primary_emotion,
                "intensity": emotion.intensity,
                "session_id": session_id,
                "audio_generated": len(audio_data) > 0
            }
            
            return response, audio_data, context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse complète: {e}")
            return "Erreur système", b"", {}

    async def get_next_speaker(self, last_speaker: str, context: str) -> str:
        """Détermine le prochain agent à parler"""
        agents_list = list(self.agents.keys())
        
        # Rotation intelligente
        if last_speaker == "michel_dubois_animateur":
            # Après Michel, alternance Sarah/Marcus
            return "sarah_johnson_journaliste" if "sarah" not in context.lower() else "marcus_thompson_expert"
        elif last_speaker == "sarah_johnson_journaliste":
            return "marcus_thompson_expert"
        else:
            return "michel_dubois_animateur"

    def log_performance_status(self):
        """Log le statut de performance du système"""
        logger.info("📊 STATUT PERFORMANCE ENHANCED MANAGER")
        logger.info(f"   Agents configurés: {len(self.agents)}")
        logger.info(f"   Mémoire conversation: {len(self.conversation_memory)} agents")
        logger.info(f"   Dernières réponses: {len(self.last_responses)} agents")

    def get_performance_metrics(self) -> Dict:
        """Retourne les métriques de performance"""
        return {
            "introduction_ready": True,
            "cache_size": {agent_id: len(self.conversation_memory.get(agent_id, [])) for agent_id in self.agents.keys()},
            "total_agents": len(self.agents),
            "enhanced_manager": True
        }

    def set_last_speaker_message(self, speaker_type: str, message: str):
        """Enregistre le dernier message d'un type de speaker"""
        logger.info(f"🗣️ {speaker_type}: {message[:50]}...")

    def set_user_context(self, user_name: str, user_subject: str):
        """Configure le contexte utilisateur pour tous les agents avec injection dynamique"""
        
        # Validation et normalisation des données
        self.user_context = {
            'user_name': user_name.strip() if user_name else 'Participant',
            'user_subject': user_subject.strip() if user_subject else 'votre présentation'
        }
        
        logger.info(f"🎯 Configuration contexte utilisateur: {self.user_context['user_name']} - {self.user_context['user_subject']}")
        
        # Mise à jour IMMÉDIATE des prompts avec contexte utilisateur
        for agent_id, agent in self.agents.items():
            original_prompt = agent["system_prompt"]
            
            # Injection du contexte utilisateur avec placeholders
            contextualized_prompt = self._inject_user_context_in_prompt(original_prompt, agent_id)
            
            agent["system_prompt"] = contextualized_prompt
            
            logger.debug(f"✅ Prompt contextualisé pour {agent['name']}")
            logger.debug(f"   Nom: {self.user_context['user_name']}")
            logger.debug(f"   Sujet: {self.user_context['user_subject']}")
        
        logger.info(f"✅ Contexte utilisateur configuré pour {len(self.agents)} agents")

    def _inject_user_context_in_prompt(self, prompt: str, agent_id: str) -> str:
        """Injecte le contexte utilisateur dans un prompt d'agent"""
        
        # Remplacement des placeholders
        contextualized = prompt.replace(
            "{user_name}", self.user_context['user_name']
        ).replace(
            "{user_subject}", self.user_context['user_subject']
        )
        
        # Injection spécifique selon l'agent
        if agent_id == "michel_dubois_animateur":
            # Michel doit être particulièrement personnalisé
            contextualized += f"""

🎯 CONTEXTE SPÉCIFIQUE DE CETTE ÉMISSION :
- Invité principal : {self.user_context['user_name']}
- Sujet du débat : {self.user_context['user_subject']}
- Tu DOIS utiliser le prénom "{self.user_context['user_name']}" régulièrement
- Tu DOIS centrer le débat sur "{self.user_context['user_subject']}"
- Toutes tes questions doivent être liées à ce sujet spécifique

💬 EXEMPLES D'INTERPELLATION PERSONNALISÉE :
- "{self.user_context['user_name']}, sur {self.user_context['user_subject']}, quelle est votre position ?"
- "Sarah, {self.user_context['user_name']} soulève un point intéressant sur {self.user_context['user_subject']}..."
- "Marcus, concernant {self.user_context['user_subject']}, que pensez-vous de la position de {self.user_context['user_name']} ?"
"""
        
        elif agent_id == "sarah_johnson_journaliste":
            contextualized += f"""

🎯 CONTEXTE JOURNALISTIQUE :
- Vous interviewez {self.user_context['user_name']} sur {self.user_context['user_subject']}
- Vos questions doivent creuser les aspects de {self.user_context['user_subject']}
- Utilisez le prénom {self.user_context['user_name']} dans vos interpellations
- Challengez spécifiquement sur les enjeux de {self.user_context['user_subject']}
"""
        
        elif agent_id == "marcus_thompson_expert":
            contextualized += f"""

🎯 CONTEXTE EXPERTISE :
- Vous apportez votre expertise sur {self.user_context['user_subject']}
- Réagissez aux positions de {self.user_context['user_name']} avec votre expertise
- Éclairez les aspects techniques/complexes de {self.user_context['user_subject']}
- Interpellez {self.user_context['user_name']} sur les implications pratiques
"""
        
        return contextualized

    def get_user_context(self) -> Dict[str, str]:
        """Retourne le contexte utilisateur actuel"""
        return getattr(self, 'user_context', {'user_name': 'Participant', 'user_subject': 'votre présentation'})

    async def process_user_message_with_interpellations(self, message: str, speaker_id: str,
                                                       conversation_history: List[Dict]) -> List[Dict]:
        """Traite un message utilisateur avec gestion automatique des interpellations"""
        
        responses = []
        
        # 1. Détection et traitement des interpellations
        if self.interpellation_manager:
            interpellation_responses = await self.interpellation_manager.process_message_with_interpellations(
                message, speaker_id, conversation_history
            )
            
            # 2. Génération des réponses d'interpellation
            for agent_id, response_text in interpellation_responses:
                agent = self.agents[agent_id]
                
                # Synthèse vocale avec émotion appropriée
                emotion = self.interpellation_manager._get_interpellation_emotion(
                    None, message  # Simplifié pour l'exemple
                )
                
                responses.append({
                    'agent_id': agent_id,
                    'agent_name': agent['name'],
                    'message': response_text,
                    'emotion': emotion,
                    'response_type': 'interpellation'
                })
        
        # 3. Si aucune interpellation détectée, logique normale
        if not responses:
            # Logique de réponse normale (agent suivant dans la rotation, etc.)
            next_agent_id = self._determine_next_speaker(conversation_history)
            normal_response = await self.generate_agent_response(
                next_agent_id, "conversation", message, conversation_history
            )
            
            responses.append({
                'agent_id': next_agent_id,
                'agent_name': self.agents[next_agent_id]['name'],
                'message': normal_response[0],
                'emotion': normal_response[1].primary_emotion,
                'response_type': 'normal'
            })
        
        return responses
    
    def _determine_next_speaker(self, conversation_history: List[Dict]) -> str:
        """Détermine qui doit parler ensuite si pas d'interpellation"""
        
        # Logique simple : rotation Michel -> Sarah -> Marcus
        if not conversation_history:
            return "michel_dubois_animateur"  # Michel commence toujours
        
        last_speaker = conversation_history[-1].get('speaker_id')
        
        rotation = [
            "michel_dubois_animateur",
            "sarah_johnson_journaliste", 
            "marcus_thompson_expert"
        ]
        
        try:
            current_index = rotation.index(last_speaker)
            next_index = (current_index + 1) % len(rotation)
            return rotation[next_index]
        except ValueError:
            return "michel_dubois_animateur"  # Fallback

    def _validate_user_context_integration(self, response: str, agent_id: str) -> bool:
        """Valide que la réponse intègre bien le contexte utilisateur"""
        
        user_context = self.get_user_context()
        user_name = user_context['user_name']
        user_subject = user_context['user_subject']
        
        response_lower = response.lower()
        user_name_lower = user_name.lower()
        
        # Vérification nom utilisateur (sauf si c'est "Participant" générique)
        if user_name != "Participant":
            if user_name_lower not in response_lower:
                logger.warning(f"⚠️ Nom utilisateur '{user_name}' absent de la réponse de {agent_id}")
                return False
        
        # Vérification référence au sujet (sauf si générique)
        if user_subject != "votre présentation":
            # Recherche de mots-clés du sujet
            subject_words = user_subject.lower().split()
            subject_mentioned = any(word in response_lower for word in subject_words if len(word) > 3)
            
            if not subject_mentioned:
                logger.warning(f"⚠️ Sujet '{user_subject}' non référencé dans la réponse de {agent_id}")
                return False
        
        logger.debug(f"✅ Contexte utilisateur bien intégré dans la réponse de {agent_id}")
        return True

    def _enhance_response_with_context(self, response: str, agent_id: str) -> str:
        """Améliore une réponse pour mieux intégrer le contexte utilisateur"""
        
        if self._validate_user_context_integration(response, agent_id):
            return response
        
        user_context = self.get_user_context()
        user_name = user_context['user_name']
        user_subject = user_context['user_subject']
        
        # Améliorations selon l'agent
        if agent_id == "michel_dubois_animateur":
            enhanced = f"{user_name}, {response}"
            if user_subject not in response:
                enhanced += f" Revenons à notre sujet : {user_subject}."
        
        elif agent_id == "sarah_johnson_journaliste":
            enhanced = response
            if user_name not in response:
                enhanced = enhanced.replace("vous", f"{user_name}")
            if user_subject not in response:
                enhanced += f" Concernant {user_subject}, précisément..."
        
        elif agent_id == "marcus_thompson_expert":
            enhanced = response
            if user_name not in response:
                enhanced = f"Comme le souligne {user_name}, {enhanced.lower()}"
            if user_subject not in response:
                enhanced += f" Dans le domaine de {user_subject}..."
        
        else:
            enhanced = response
        
        logger.info(f"🎯 Réponse améliorée avec contexte pour {agent_id}")
        return enhanced

    async def process_agent_output(self, output: str, agent_id: str) -> Dict:
        """Traite la sortie d'un agent pour détecter les interpellations"""
        # Simulation d'interpellations
        return {
            "triggered_responses": [
                {
                    "agent_id": "sarah_johnson_journaliste",
                    "content": "C'est intéressant, pouvez-vous préciser ?",
                    "reaction": "C'est intéressant, pouvez-vous préciser ?"
                }
            ]
        }


    async def test_tts_integration(self) -> bool:
        """Teste l'intégration TTS ElevenLabs"""
        if not self.tts_service:
            logger.error("❌ TTS Service non initialisé")
            return False
        
        try:
            # Test simple
            test_audio = await self.tts_service.synthesize_with_emotion(
                text="Test de connexion ElevenLabs",
                voice_id="George",
                emotion="neutre",
                intensity=0.5
            )
            
            if len(test_audio) > 0:
                logger.info("✅ Test TTS réussi")
                return True
            else:
                logger.error("❌ Test TTS échoué: audio vide")
                return False
                
        except Exception as e:
            logger.error(f"❌ Test TTS échoué: {e}")
            return False


def get_enhanced_manager(openai_api_key: str, elevenlabs_api_key: str, 
                        config: MultiAgentConfig) -> EnhancedMultiAgentManager:
    """Factory function pour créer le gestionnaire amélioré"""
    return EnhancedMultiAgentManager(openai_api_key, elevenlabs_api_key, config)
