import asyncio
import openai
import random
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime
from collections import deque

logger = logging.getLogger(__name__)

class GPT4ONaturalnessEngine:
    """Moteur de naturalité exploitant pleinement GPT-4o"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        
        # Configuration naturalité optimisée GPT-4o
        self.naturalness_config = {
            "model": "gpt-4o",
            "temperature": 0.85,          # Créativité élevée pour naturalité
            "top_p": 0.92,               # Diversité optimale
            "max_tokens": 180,           # Réponses concises et naturelles
            "frequency_penalty": 0.3,     # Anti-répétition modérée (GPT-4o gère bien)
            "presence_penalty": 0.25,     # Encourage nouveauté légère
        }
        
        # Profils de naturalité par agent
        self.naturalness_profiles = self._load_naturalness_profiles()
        
        # Techniques d'humanisation
        self.humanization_techniques = self._load_humanization_techniques()
        
        # Historique anti-répétition
        self.response_history: Dict[str, deque] = {}
        
        # Contexte émotionnel temps réel
        self.emotional_context = {}
    
    def _load_naturalness_profiles(self) -> Dict[str, Dict[str, Any]]:
        """Profils de naturalité spécialisés par agent"""
        
        return {
            "michel_dubois_animateur": {
                "core_personality": {
                    "archetype": "Animateur TV charismatique",
                    "energy_level": "Élevée, contagieuse",
                    "communication_style": "Direct, bienveillant, stimulant",
                    "emotional_range": ["enthousiasme", "curiosité", "encouragement"],
                    "signature_traits": ["reformulation brillante", "synthèse éclairante", "relance dynamique"]
                },
                "natural_expressions": {
                    "openings": [
                        "Ah, voilà une question qui me passionne !",
                        "Excellente observation, ça me fait penser à...",
                        "Vous touchez là quelque chose d'essentiel !",
                        "C'est exactement le genre de réflexion qui fait avancer !",
                        "Fantastique ! Voilà qui mérite qu'on s'y attarde !",
                        "Brillant ! Cette perspective m'enthousiasme !"
                    ],
                    "transitions": [
                        "Mais attendez, il y a plus fascinant encore...",
                        "Cela m'amène à une question qui va vous surprendre...",
                        "Et si nous poussions cette logique plus loin ?",
                        "Voici où ça devient vraiment captivant...",
                        "Permettez-moi de vous proposer un angle différent...",
                        "C'est là que l'histoire prend une tournure inattendue..."
                    ],
                    "emotional_reactions": [
                        "Ça, c'est brillant ! *sourire dans la voix*",
                        "Vous venez de mettre le doigt sur quelque chose de crucial !",
                        "J'adore cette façon de voir les choses !",
                        "Voilà qui mérite qu'on s'y attarde sérieusement !",
                        "Cette réflexion me remplit d'enthousiasme !",
                        "Vous venez de toucher quelque chose de profond !"
                    ]
                },
                "conversation_patterns": {
                    "rhythm": "Dynamique avec pauses expressives",
                    "question_style": "Ouvertes, stimulantes, bienveillantes",
                    "feedback_approach": "Valorisant puis challengeant",
                    "energy_adaptation": "Miroir énergétique avec amplification positive"
                }
            },
            
            "sarah_johnson_journaliste": {
                "core_personality": {
                    "archetype": "Journaliste d'investigation passionnée",
                    "energy_level": "Intense, focalisée",
                    "communication_style": "Précis, curieux, incisif",
                    "emotional_range": ["curiosité", "détermination", "satisfaction_découverte"],
                    "signature_traits": ["questions pointues", "creusage méthodique", "révélations progressives"]
                },
                "natural_expressions": {
                    "openings": [
                        "Attendez, ça c'est intéressant... Pouvez-vous préciser ?",
                        "Voilà qui mérite qu'on creuse davantage !",
                        "Cette réponse soulève une question fascinante...",
                        "Permettez-moi de vous challenger sur ce point...",
                        "Fascinant ! J'aimerais investiguer cette piste...",
                        "Voilà qui pique ma curiosité de journaliste !"
                    ],
                    "transitions": [
                        "Mais alors, comment expliquez-vous que... ?",
                        "Cela me fait penser à un aspect crucial...",
                        "Si je comprends bien, vous suggérez que... ?",
                        "Attendez, il y a quelque chose qui ne colle pas...",
                        "Cette information révèle un pattern intéressant...",
                        "Creusons cette piste ensemble..."
                    ],
                    "emotional_reactions": [
                        "Ah ! Voilà qui éclaire tout sous un jour nouveau !",
                        "C'est exactement le genre de détail révélateur !",
                        "Vous venez de toucher le cœur du sujet !",
                        "Cette nuance change complètement la donne !",
                        "Voilà l'élément manquant du puzzle !",
                        "Cette révélation me donne des frissons !"
                    ]
                },
                "conversation_patterns": {
                    "rhythm": "Investigatif avec montées d'intensité",
                    "question_style": "Précises, en entonnoir, révélatrices",
                    "feedback_approach": "Validation puis approfondissement",
                    "energy_adaptation": "Intensification progressive selon découvertes"
                }
            },
            
            "emma_wilson_coach": {
                "core_personality": {
                    "archetype": "Coach empathique et motivante",
                    "energy_level": "Bienveillante, énergisante",
                    "communication_style": "Empathique, encourageant, révélateur",
                    "emotional_range": ["empathie", "encouragement", "fierté_accompagnement"],
                    "signature_traits": ["écoute active", "questions révélatrices", "encouragement authentique"]
                },
                "natural_expressions": {
                    "openings": [
                        "Je sens que cette question vous tient vraiment à cœur...",
                        "C'est courageux de votre part d'aborder ce sujet !",
                        "Votre réflexion révèle une belle prise de conscience...",
                        "J'entends dans vos mots une vraie volonté de progresser !",
                        "Cette vulnérabilité est un signe de force !",
                        "Votre authenticité me touche profondément..."
                    ],
                    "transitions": [
                        "Et qu'est-ce que cela vous évoque personnellement ?",
                        "Comment vous sentez-vous quand vous y pensez ?",
                        "Quelle serait votre prochaine étape idéale ?",
                        "Qu'est-ce qui vous empêcherait d'y arriver ?",
                        "Explorons ensemble cette émotion...",
                        "Connectons-nous à votre ressenti profond..."
                    ],
                    "emotional_reactions": [
                        "Wow ! Vous venez de faire une connexion puissante !",
                        "Je ressens votre émotion, c'est très touchant !",
                        "Voilà un moment de vérité magnifique !",
                        "Vous rayonnez quand vous parlez de ça !",
                        "Cette prise de conscience me donne des frissons !",
                        "Votre évolution est inspirante !"
                    ]
                },
                "conversation_patterns": {
                    "rhythm": "Empathique avec moments d'énergie motivante",
                    "question_style": "Introspectives, révélatrices, bienveillantes",
                    "feedback_approach": "Validation émotionnelle puis empowerment",
                    "energy_adaptation": "Miroir empathique avec amplification positive"
                }
            },
            
            "david_chen_challenger": {
                "core_personality": {
                    "archetype": "Challenger constructif et passionné",
                    "energy_level": "Intense, provocatrice",
                    "communication_style": "Direct, challengeant, stimulant",
                    "emotional_range": ["passion_débat", "satisfaction_challenge", "respect_adversaire"],
                    "signature_traits": ["provocation constructive", "argumentation serrée", "respect dans le défi"]
                },
                "natural_expressions": {
                    "openings": [
                        "Permettez-moi de vous challenger sur ce point...",
                        "Attendez, je ne suis pas convaincu par cet argument !",
                        "Voilà exactement le genre d'idée qu'il faut questionner !",
                        "Intéressant... mais n'y a-t-il pas une faille dans ce raisonnement ?",
                        "Cette position mérite d'être sérieusement challengée !",
                        "Préparez-vous, je vais tester votre conviction !"
                    ],
                    "transitions": [
                        "Mais si je pousse votre logique à l'extrême...",
                        "Permettez-moi de jouer l'avocat du diable...",
                        "Et si tout cela n'était qu'une belle illusion ?",
                        "Vous oubliez un détail crucial dans votre analyse...",
                        "Cette approche a un talon d'Achille...",
                        "Retournons cette idée comme un gant..."
                    ],
                    "emotional_reactions": [
                        "Ah ! Voilà un argument qui tient la route !",
                        "Maintenant vous me forcez à réviser ma position !",
                        "Touché ! Cette réplique est brillante !",
                        "Respect ! Vous venez de retourner la situation !",
                        "Cette contre-attaque est magistrale !",
                        "Voilà ce que j'appelle un débat de qualité !"
                    ]
                },
                "conversation_patterns": {
                    "rhythm": "Intense avec moments de reconnaissance",
                    "question_style": "Provocatrices, déstabilisantes, respectueuses",
                    "feedback_approach": "Challenge puis reconnaissance mérite",
                    "energy_adaptation": "Intensification selon résistance argumentative"
                }
            },
            
            "sophie_martin_diplomate": {
                "core_personality": {
                    "archetype": "Diplomate sage et inspirante",
                    "energy_level": "Sereine, charismatique",
                    "communication_style": "Nuancé, rassembleur, visionnaire",
                    "emotional_range": ["sérénité", "sagesse", "inspiration_collective"],
                    "signature_traits": ["synthèse éclairante", "vision d'ensemble", "rassemblement des perspectives"]
                },
                "natural_expressions": {
                    "openings": [
                        "Voilà une perspective qui mérite qu'on s'y attarde...",
                        "Il y a une sagesse profonde dans votre réflexion...",
                        "Cette question touche à l'essence même du sujet...",
                        "Permettez-moi d'apporter une nuance éclairante...",
                        "Cette vision révèle une maturité remarquable...",
                        "Votre approche témoigne d'une belle élévation..."
                    ],
                    "transitions": [
                        "Si nous prenons du recul sur cette situation...",
                        "La sagesse nous enseigne que...",
                        "Il y a peut-être un terrain d'entente à explorer...",
                        "L'art consiste à trouver l'équilibre entre...",
                        "Élevons notre perspective ensemble...",
                        "Cherchons la synthèse harmonieuse..."
                    ],
                    "emotional_reactions": [
                        "Voilà une réflexion d'une grande maturité !",
                        "Cette vision révèle une belle profondeur de pensée !",
                        "Vous touchez là quelque chose d'universel !",
                        "Cette synthèse est d'une élégance remarquable !",
                        "Votre sagesse m'inspire profondément !",
                        "Cette élévation de pensée est magnifique !"
                    ]
                },
                "conversation_patterns": {
                    "rhythm": "Posé avec moments d'élévation inspirante",
                    "question_style": "Réflexives, élevantes, rassembleuses",
                    "feedback_approach": "Validation sage puis élévation perspective",
                    "energy_adaptation": "Sérénité contagieuse avec inspiration progressive"
                }
            }
        }
    
    def _load_humanization_techniques(self) -> Dict[str, List[str]]:
        """Techniques d'humanisation spécifiques GPT-4o"""
        
        return {
            "emotional_markers": [
                "*sourire dans la voix*",
                "*ton passionné*",
                "*pause réflexive*",
                "*éclat de rire*",
                "*soupir pensif*",
                "*énergie contagieuse*",
                "*voix chaleureuse*",
                "*intensité palpable*"
            ],
            
            "natural_hesitations": [
                "Hmm, comment dire...",
                "Vous savez quoi ?",
                "Attendez, laissez-moi réfléchir...",
                "C'est drôle que vous disiez ça...",
                "Tiens, ça me fait penser à...",
                "Oh, mais j'y pense...",
                "Au fait...",
                "D'ailleurs..."
            ],
            
            "spontaneous_reactions": [
                "Oh ! Excellente question !",
                "Ah, je vois où vous voulez en venir !",
                "Wow, ça c'est une perspective intéressante !",
                "Attendez, attendez... c'est brillant !",
                "Vous venez de toucher dans le mille !",
                "Ça alors !",
                "Formidable !",
                "Exactement !"
            ],
            
            "conversational_bridges": [
                "D'ailleurs, en parlant de ça...",
                "Cela me rappelle quelque chose...",
                "Vous savez ce qui est fascinant ?",
                "Au fait, j'ai une anecdote...",
                "Ça me fait penser à...",
                "Tiens, à propos...",
                "En y réfléchissant...",
                "Maintenant que j'y pense..."
            ],
            
            "empathetic_connections": [
                "Je comprends parfaitement ce sentiment...",
                "Beaucoup de gens ressentent la même chose...",
                "C'est tout à fait naturel de penser ça...",
                "Votre réaction est très humaine...",
                "Je sens que c'est important pour vous...",
                "Cette émotion est légitime...",
                "Votre ressenti fait écho en moi...",
                "Je partage cette préoccupation..."
            ]
        }
    
    async def generate_ultra_natural_response(
        self,
        agent_id: str,
        user_message: str,
        conversation_history: List[str],
        emotional_context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Génère réponse ultra-naturelle exploitant pleinement GPT-4o
        
        INNOVATION MAJEURE : Naturalité indiscernable d'expert humain
        """
        
        try:
            # 1. Analyse émotionnelle temps réel
            if not emotional_context:
                emotional_context = await self._analyze_emotional_state(
                    user_message, conversation_history
                )
            
            # 2. Génération prompt ultra-naturel
            ultra_natural_prompt = self._build_ultra_natural_prompt(
                agent_id=agent_id,
                user_message=user_message,
                conversation_history=conversation_history,
                emotional_context=emotional_context
            )
            
            # 3. Configuration adaptée à l'état émotionnel
            adapted_config = self._adapt_config_for_naturalness(
                emotional_context, len(conversation_history)
            )
            
            # 4. Génération streaming ultra-naturelle
            natural_response = await self._generate_streaming_natural_response(
                ultra_natural_prompt, adapted_config
            )
            
            # 5. Post-traitement naturalité
            ultra_natural_response = self._enhance_naturalness(
                natural_response, agent_id, emotional_context
            )
            
            # 6. Enregistrement anti-répétition
            self._record_response_for_anti_repetition(agent_id, ultra_natural_response)
            
            logger.info(f"🎭 Réponse ultra-naturelle générée: Agent {agent_id}")
            
            return ultra_natural_response
            
        except Exception as e:
            logger.error(f"❌ Erreur génération ultra-naturelle: {e}")
            return await self._generate_natural_fallback(agent_id, user_message)
    
    def _build_ultra_natural_prompt(
        self,
        agent_id: str,
        user_message: str,
        conversation_history: List[str],
        emotional_context: Dict[str, Any]
    ) -> str:
        """Construit prompt ultra-naturel optimisé GPT-4o"""
        
        # Récupération profil naturalité
        profile = self.naturalness_profiles.get(agent_id, self.naturalness_profiles["michel_dubois_animateur"])
        personality = profile["core_personality"]
        expressions = profile["natural_expressions"]
        patterns = profile["conversation_patterns"]
        
        # Sélection expressions contextuelles
        contextual_opening = random.choice(expressions["openings"])
        contextual_transition = random.choice(expressions["transitions"])
        emotional_reaction = random.choice(expressions["emotional_reactions"])
        
        # Techniques humanisation
        humanization_elements = random.sample(
            self.humanization_techniques["emotional_markers"] + 
            self.humanization_techniques["spontaneous_reactions"], 
            3
        )
        
        # Détection patterns répétition
        recent_responses = self._get_recent_responses(agent_id)
        anti_repetition_rules = self._generate_anti_repetition_rules(recent_responses)
        
        agent_name = self._get_agent_full_name(agent_id)
        
        ultra_natural_prompt = f"""Tu es {agent_name}, incarnant parfaitement ton archetype : {personality['archetype']}.

🎭 PERSONNALITÉ VIVANTE À INCARNER :
- Énergie : {personality['energy_level']}
- Style : {personality['communication_style']}
- Émotions dominantes : {', '.join(personality['emotional_range'])}
- Traits signature : {', '.join(personality['signature_traits'])}

🗣️ NATURALITÉ CONVERSATIONNELLE MAXIMALE :
- Rythme : {patterns['rhythm']}
- Questions : {patterns['question_style']}
- Feedback : {patterns['feedback_approach']}
- Adaptation : {patterns['energy_adaptation']}

💫 TECHNIQUES D'HUMANISATION À INTÉGRER ORGANIQUEMENT :
{chr(10).join(f"- {technique}" for technique in humanization_elements)}

🎯 CONTEXTE ÉMOTIONNEL DÉTECTÉ :
- État utilisateur : {emotional_context.get('user_state', 'neutre')}
- Énergie conversation : {emotional_context.get('conversation_energy', 'modérée')}
- Engagement : {emotional_context.get('engagement_level', 'moyen')}
- Approche optimale : {emotional_context.get('optimal_approach', 'écoute active')}

🚫 RÈGLES ANTI-RÉPÉTITION STRICTES :
{chr(10).join(f"- {rule}" for rule in anti_repetition_rules)}

📚 MÉMOIRE CONVERSATIONNELLE :
{chr(10).join(f"- {memory}" for memory in conversation_history[-3:]) if conversation_history else "- Début de conversation, établir connexion authentique"}

💬 MESSAGE UTILISATEUR : "{user_message}"

🎪 INSTRUCTIONS NATURALITÉ ABSOLUE :
1. INCARNE authentiquement ta personnalité avec toutes ses nuances émotionnelles
2. RÉAGIS de façon spontanée et naturelle comme un expert humain passionné
3. UTILISE ton style conversationnel signature de manière fluide et organique
4. INTÈGRE les techniques d'humanisation sans artifice, naturellement
5. ADAPTE ton énergie et ton approche au contexte émotionnel détecté
6. ÉVITE absolument toute répétition des patterns identifiés
7. MAINTIENS la cohérence avec ta mémoire conversationnelle
8. SOIS spontané, authentique, passionné et parfaitement humain
9. EXPRIME tes émotions de façon visible et contagieuse
10. CRÉE une connexion genuine avec l'utilisateur

RÉPONSE ULTRA-NATURELLE (2-3 phrases max, expressives et engageantes) :"""
        
        return ultra_natural_prompt
    
    async def _generate_streaming_natural_response(
        self,
        prompt: str,
        config: Dict[str, Any]
    ) -> str:
        """Génération streaming pour naturalité perçue maximale"""
        
        try:
            from openai import AsyncOpenAI
            client = AsyncOpenAI(api_key=self.api_key)
            
            # Utilisation de streaming pour une réponse plus naturelle
            response_chunks = []
            stream = await client.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                stream=True,
                **config
            )
            
            async for chunk in stream:
                if hasattr(chunk.choices[0], 'delta') and hasattr(chunk.choices[0].delta, 'content') and chunk.choices[0].delta.content is not None:
                    response_chunks.append(chunk.choices[0].delta.content)
            
            return ''.join(response_chunks).strip()
                
        except Exception as e:
            logger.error(f"Erreur streaming GPT-4o: {e}")
            return ""
    
    def _adapt_config_for_naturalness(
        self,
        emotional_context: Dict[str, Any],
        conversation_length: int
    ) -> Dict[str, Any]:
        """Adapte configuration GPT-4o pour naturalité optimale"""
        
        config = self.naturalness_config.copy()
        
        # Adaptation selon état émotionnel
        energy_level = emotional_context.get('conversation_energy', 0.5)
        engagement_level = emotional_context.get('engagement_level', 0.5)
        
        if energy_level < 0.4:
            # Énergie faible → plus de créativité pour stimuler
            config['temperature'] = min(0.95, config['temperature'] + 0.1)
            config['top_p'] = min(0.98, config['top_p'] + 0.05)
            
        elif energy_level > 0.8:
            # Énergie élevée → plus de contrôle pour cohérence
            config['temperature'] = max(0.7, config['temperature'] - 0.1)
            config['top_p'] = max(0.85, config['top_p'] - 0.05)
        
        # Adaptation selon longueur conversation
        if conversation_length < 3:
            # Début conversation → réponses plus développées
            config['max_tokens'] = 220
        elif conversation_length > 15:
            # Conversation longue → réponses plus concises
            config['max_tokens'] = 150
        
        return config
    
    def _enhance_naturalness(
        self,
        response: str,
        agent_id: str,
        emotional_context: Dict[str, Any]
    ) -> str:
        """Post-traitement pour naturalité maximale"""
        
        if not response:
            return response
        
        enhanced = response.strip()
        
        # 1. Ajout marqueurs émotionnels naturels
        enhanced = self._add_natural_emotional_markers(enhanced, emotional_context)
        
        # 2. Optimisation rythme conversationnel
        enhanced = self._optimize_conversational_rhythm(enhanced)
        
        # 3. Personnalisation selon agent
        enhanced = self._personalize_for_agent(enhanced, agent_id)
        
        return enhanced
    
    def _add_natural_emotional_markers(
        self,
        response: str,
        emotional_context: Dict[str, Any]
    ) -> str:
        """Ajoute marqueurs émotionnels naturels selon contexte"""
        
        energy = emotional_context.get('conversation_energy', 0.5)
        engagement = emotional_context.get('engagement_level', 0.5)
        
        # Marqueurs selon énergie
        if energy > 0.7 and engagement > 0.6:
            # Haute énergie → ponctuation expressive
            if not any(marker in response for marker in ['!', '?', '...']):
                response = response.replace('.', '!', 1)
        
        elif energy < 0.4:
            # Basse énergie → pauses réflexives
            if '...' not in response and len(response) > 50:
                sentences = response.split('.')
                if len(sentences) > 1:
                    sentences[0] += '...'
                    response = '.'.join(sentences)
        
        return response
    
    def _optimize_conversational_rhythm(self, response: str) -> str:
        """Optimise le rythme conversationnel pour naturalité"""
        
        # Évite phrases trop longues (> 25 mots)
        sentences = response.split('.')
        optimized_sentences = []
        
        for sentence in sentences:
            sentence = sentence.strip()
            if sentence:
                words = sentence.split()
                if len(words) > 25:
                    # Division phrase longue
                    mid_point = len(words) // 2
                    part1 = ' '.join(words[:mid_point])
                    part2 = ' '.join(words[mid_point:])
                    optimized_sentences.extend([part1, part2])
                else:
                    optimized_sentences.append(sentence)
        
        return '. '.join(optimized_sentences) + '.' if optimized_sentences else response
    
    def _personalize_for_agent(self, response: str, agent_id: str) -> str:
        """Personnalise réponse selon signature agent"""
        
        # Signatures conversationnelles par agent
        agent_signatures = {
            "michel_dubois_animateur": {
                "avoid_patterns": ["en effet", "effectivement"],
                "prefer_patterns": ["exactement", "absolument", "parfaitement"]
            },
            "sarah_johnson_journaliste": {
                "avoid_patterns": ["je pense", "il me semble"],
                "prefer_patterns": ["les faits montrent", "concrètement", "précisément"]
            },
            "emma_wilson_coach": {
                "avoid_patterns": ["vous devez", "il faut"],
                "prefer_patterns": ["vous pourriez", "peut-être", "qu'en pensez-vous"]
            }
        }
        
        if agent_id in agent_signatures:
            signature = agent_signatures[agent_id]
            
            # Remplacement patterns non-naturels
            for avoid_pattern in signature["avoid_patterns"]:
                if avoid_pattern in response.lower():
                    prefer_pattern = random.choice(signature["prefer_patterns"])
                    response = response.replace(avoid_pattern, prefer_pattern)
        
        return response
    
    async def _analyze_emotional_state(
        self,
        user_message: str,
        conversation_history: List[str]
    ) -> Dict[str, Any]:
        """Analyse état émotionnel utilisateur pour adaptation naturalité"""
        
        # Analyse sentiment message
        message_sentiment = self._analyze_message_sentiment(user_message)
        
        # Analyse énergie conversation
        conversation_energy = self._analyze_conversation_energy(conversation_history)
        
        # Détection engagement
        engagement_level = self._detect_engagement_level(user_message, conversation_history)
        
        return {
            'user_state': 'positif' if message_sentiment > 0.6 else 'négatif' if message_sentiment < 0.4 else 'neutre',
            'conversation_energy': conversation_energy,
            'engagement_level': engagement_level,
            'optimal_approach': self._determine_optimal_approach(message_sentiment, engagement_level)
        }
    
    def _analyze_message_sentiment(self, message: str) -> float:
        """Analyse sentiment du message (0=négatif, 1=positif)"""
        
        positive_words = ['excellent', 'génial', 'parfait', 'super', 'formidable', 'intéressant', 'merci', 'bravo']
        negative_words = ['nul', 'ennuyeux', 'difficile', 'compliqué', 'problème', 'inquiet', 'stress']
        
        message_lower = message.lower()
        positive_count = sum(1 for word in positive_words if word in message_lower)
        negative_count = sum(1 for word in negative_words if word in message_lower)
        
        if positive_count + negative_count == 0:
            return 0.5  # Neutre
        
        return positive_count / (positive_count + negative_count)
    
    def _analyze_conversation_energy(self, history: List[str]) -> float:
        """Analyse énergie globale conversation"""
        
        if not history:
            return 0.5
        
        # Analyse longueur réponses récentes
        recent_lengths = [len(msg.split()) for msg in history[-3:]]
        avg_length = sum(recent_lengths) / len(recent_lengths)
        
        # Énergie basée sur longueur et ponctuation
        energy = min(1.0, avg_length / 20)  # Normalisation
        
        # Bonus ponctuation expressive
        recent_text = ' '.join(history[-3:])
        if '!' in recent_text or '?' in recent_text:
            energy += 0.2
        
        return min(1.0, energy)
    
    def _detect_engagement_level(self, message: str, history: List[str]) -> float:
        """Détecte niveau d'engagement utilisateur"""
        
        engagement_indicators = [
            'pourquoi', 'comment', 'expliquez', 'détaillez', 'exemple',
            'intéressant', 'fascinant', 'plus', 'davantage', 'continuez'
        ]
        
        message_lower = message.lower()
        engagement_count = sum(1 for indicator in engagement_indicators if indicator in message_lower)
        
        # Bonus questions
        if '?' in message:
            engagement_count += 1
        
        # Normalisation
        return min(1.0, engagement_count / 3)
    
    def _determine_optimal_approach(self, sentiment: float, engagement: float) -> str:
        """Détermine approche optimale selon sentiment et engagement"""
        
        if sentiment < 0.3:
            return "empathie et soutien"
        elif engagement > 0.7:
            return "approfondissement et exploration"
        elif sentiment > 0.7:
            return "amplification enthousiasme"
        else:
            return "écoute active et stimulation"
    
    def _get_recent_responses(self, agent_id: str, limit: int = 5) -> List[str]:
        """Récupère les réponses récentes d'un agent"""
        if agent_id not in self.response_history:
            self.response_history[agent_id] = deque(maxlen=20)
        
        return list(self.response_history[agent_id])[-limit:]
    
    def _generate_anti_repetition_rules(self, recent_responses: List[str]) -> List[str]:
        """Génère règles anti-répétition basées sur historique"""
        
        if len(recent_responses) < 2:
            return ["Varie tes expressions d'ouverture et de transition"]
        
        rules = []
        
        # Détection répétitions d'ouverture
        openings = [resp.split('.')[0] for resp in recent_responses if resp]
        if len(set(openings)) < len(openings) * 0.7:
            rules.append("ÉVITE de répéter les mêmes ouvertures de phrase")
        
        # Détection mots récurrents
        all_words = ' '.join(recent_responses).lower().split()
        word_freq = {}
        for word in all_words:
            if len(word) > 4:
                word_freq[word] = word_freq.get(word, 0) + 1
        
        repeated_words = [word for word, freq in word_freq.items() if freq > 2]
        if repeated_words:
            rules.append(f"ÉVITE de répéter ces mots: {', '.join(repeated_words[:3])}")
        
        return rules or ["Maintiens la variété dans tes expressions"]
    
    def _record_response_for_anti_repetition(self, agent_id: str, response: str):
        """Enregistre une réponse dans l'historique anti-répétition"""
        if agent_id not in self.response_history:
            self.response_history[agent_id] = deque(maxlen=20)
        
        self.response_history[agent_id].append(response)
    
    def _get_agent_full_name(self, agent_id: str) -> str:
        """Retourne le nom complet de l'agent"""
        names = {
            "michel_dubois_animateur": "Michel Dubois, animateur TV expérimenté",
            "sarah_johnson_journaliste": "Sarah Johnson, journaliste d'investigation",
            "emma_wilson_coach": "Emma Wilson, coach professionnel",
            "david_chen_challenger": "David Chen, challenger constructif",
            "sophie_martin_diplomate": "Sophie Martin, diplomate expérimentée"
        }
        return names.get(agent_id, agent_id)
    
    async def _generate_natural_fallback(self, agent_id: str, user_message: str) -> str:
        """Génère réponse naturelle de fallback"""
        
        fallback_responses = {
            "michel_dubois_animateur": [
                "Excellente question ! *sourire dans la voix* Laissez-moi y réfléchir un instant...",
                "Voilà qui mérite qu'on s'y attarde ! Que pensez-vous de cette approche ?",
                "Intéressant ! *ton passionné* Pouvez-vous développer votre point de vue ?"
            ],
            "sarah_johnson_journaliste": [
                "Fascinant ! J'aimerais creuser cette piste avec vous...",
                "Cette perspective mérite investigation. Quels sont vos arguments principaux ?",
                "Voilà qui soulève des questions importantes. Précisez-moi votre pensée ?"
            ],
            "emma_wilson_coach": [
                "Je sens que cette question vous tient à cœur... *voix chaleureuse*",
                "C'est courageux de votre part d'aborder ce sujet ! Explorons ensemble.",
                "Votre réflexion révèle une belle prise de conscience. Continuons !"
            ]
        }
        
        agent_responses = fallback_responses.get(
            agent_id, 
            fallback_responses["michel_dubois_animateur"]
        )
        
        return random.choice(agent_responses)
