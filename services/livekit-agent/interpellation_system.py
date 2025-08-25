# /services/livekit-agent/interpellation_system.py
"""
Système d'interpellation intelligente pour agents multi-agents
Garantit que Sarah et Marcus répondent systématiquement quand interpellés
"""
import re
import logging
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
import random

logger = logging.getLogger(__name__)

@dataclass
class InterpellationDetection:
    """Résultat de détection d'interpellation"""
    agent_id: str
    agent_name: str
    confidence: float  # 0.0 à 1.0
    interpellation_type: str  # "direct", "indirect", "contextual"
    trigger_phrase: str  # Phrase qui a déclenché la détection

class AdvancedInterpellationDetector:
    """Détecteur d'interpellation intelligent pour agents multi-agents"""
    
    def __init__(self):
        # Patterns d'interpellation directe
        self.direct_patterns = {
            "sarah_johnson_journaliste": [
                r'\bsarah\b',
                r'\bjournaliste\b',
                r'\bsarah johnson\b',
                r'\bmadame johnson\b',
                r'\bnotre journaliste\b',
                r'\bms\. johnson\b',
                r'\bms johnson\b'
            ],
            "marcus_thompson_expert": [
                r'\bmarcus\b',
                r'\bexpert\b',
                r'\bmarcus thompson\b',
                r'\bmonsieur thompson\b',
                r'\bnotre expert\b',
                r'\bmr\. thompson\b',
                r'\bmr thompson\b'
            ]
        }
        
        # Patterns d'interpellation indirecte
        self.indirect_patterns = {
            "sarah_johnson_journaliste": [
                r'qu\'en pense.{0,20}journaliste',
                r'votre (avis|opinion|point de vue).{0,30}sarah',
                r'(question|demande).{0,20}journaliste',
                r'sarah.{0,10}(que|comment|pourquoi)',
                r'du point de vue journalistique',
                r'votre enquête',
                r'vos investigations',
                r'vos sources',
                r'votre analyse journalistique'
            ],
            "marcus_thompson_expert": [
                r'qu\'en pense.{0,20}expert',
                r'votre (avis|opinion|expertise).{0,30}marcus',
                r'(question|demande).{0,20}expert',
                r'marcus.{0,10}(que|comment|pourquoi)',
                r'du point de vue (expert|technique)',
                r'votre expertise',
                r'votre expérience',
                r'votre analyse technique',
                r'votre point de vue d\'expert'
            ]
        }
        
        # Patterns contextuels (selon le sujet de conversation)
        self.contextual_patterns = {
            "sarah_johnson_journaliste": [
                r'(enquête|investigation|terrain|faits|sources|révélation)',
                r'(journalisme|média|presse|information)',
                r'(vérification|fact.?check|validation)',
                r'(rumeur|révélation|scoop)',
                r'(sources|témoignages|documents)'
            ],
            "marcus_thompson_expert": [
                r'(expertise|expérience|technique|spécialisé)',
                r'(recherche|étude|analyse|données)',
                r'(solution|recommandation|conseil)',
                r'(méthode|approche|stratégie)',
                r'(résultats|statistiques|chiffres)'
            ]
        }
    
    def detect_interpellations(self, message: str, speaker_id: str, 
                             conversation_context: List[Dict]) -> List[InterpellationDetection]:
        """Détecte toutes les interpellations dans un message"""
        
        detections = []
        message_lower = message.lower()
        
        for agent_id in ["sarah_johnson_journaliste", "marcus_thompson_expert"]:
            # Skip si c'est l'agent qui parle (pas d'auto-interpellation)
            if speaker_id == agent_id:
                continue
            
            agent_name = "Sarah Johnson" if "sarah" in agent_id else "Marcus Thompson"
            
            # Détection directe (priorité haute)
            for pattern in self.direct_patterns[agent_id]:
                matches = re.finditer(pattern, message_lower, re.IGNORECASE)
                for match in matches:
                    detections.append(InterpellationDetection(
                        agent_id=agent_id,
                        agent_name=agent_name,
                        confidence=0.95,
                        interpellation_type="direct",
                        trigger_phrase=match.group()
                    ))
            
            # Détection indirecte (priorité moyenne)
            for pattern in self.indirect_patterns[agent_id]:
                matches = re.finditer(pattern, message_lower, re.IGNORECASE)
                for match in matches:
                    detections.append(InterpellationDetection(
                        agent_id=agent_id,
                        agent_name=agent_name,
                        confidence=0.80,
                        interpellation_type="indirect",
                        trigger_phrase=match.group()
                    ))
            
            # Détection contextuelle (priorité basse, mais importante)
            contextual_score = self._calculate_contextual_score(
                message_lower, agent_id, conversation_context
            )
            
            if contextual_score > 0.6:
                detections.append(InterpellationDetection(
                    agent_id=agent_id,
                    agent_name=agent_name,
                    confidence=contextual_score,
                    interpellation_type="contextual",
                    trigger_phrase="contexte spécialisé"
                ))
        
        # Tri par confiance décroissante
        detections.sort(key=lambda x: x.confidence, reverse=True)
        
        return detections
    
    def _calculate_contextual_score(self, message: str, agent_id: str, 
                                  context: List[Dict]) -> float:
        """Calcule le score contextuel d'interpellation"""
        
        score = 0.0
        patterns = self.contextual_patterns[agent_id]
        
        # Score basé sur les mots-clés contextuels
        for pattern in patterns:
            matches = len(re.findall(pattern, message, re.IGNORECASE))
            score += matches * 0.2
        
        # Bonus si l'agent n'a pas parlé récemment
        recent_speakers = [entry.get('speaker_id') for entry in context[-3:]]
        if agent_id not in recent_speakers:
            score += 0.3
        
        # Bonus si question ouverte sans interpellation directe
        if re.search(r'\?', message) and not re.search(r'\b(sarah|marcus)\b', message, re.IGNORECASE):
            score += 0.2
        
        return min(score, 1.0)

class InterpellationResponseManager:
    """Gestionnaire des réponses aux interpellations"""
    
    def __init__(self, enhanced_manager):
        self.enhanced_manager = enhanced_manager
        self.detector = AdvancedInterpellationDetector()
        self.interpellation_history = []
    
    async def process_message_with_interpellations(self, message: str, speaker_id: str, 
                                                 conversation_history: List[Dict]) -> List[Tuple[str, str]]:
        """Traite un message et génère les réponses d'interpellation nécessaires"""
        
        # Détection des interpellations
        detections = self.detector.detect_interpellations(message, speaker_id, conversation_history)
        
        responses = []
        
        for detection in detections:
            # Éviter les réponses multiples du même agent
            if detection.agent_id in [r[0] for r in responses]:
                continue
            
            # Génération de réponse spécialisée pour interpellation
            response = await self._generate_interpellation_response(
                detection, message, speaker_id, conversation_history
            )
            
            responses.append((detection.agent_id, response))
            
            # Mémorisation de l'interpellation
            self.interpellation_history.append({
                'detection': detection,
                'original_message': message,
                'speaker_id': speaker_id,
                'response_generated': True
            })
        
        return responses
    
    async def _generate_interpellation_response(self, detection: InterpellationDetection,
                                              original_message: str, speaker_id: str,
                                              conversation_history: List[Dict]) -> str:
        """Génère une réponse spécialisée pour une interpellation"""
        
        agent = self.enhanced_manager.agents[detection.agent_id]
        
        # Construction du prompt spécialisé pour interpellation
        interpellation_prompt = self._build_interpellation_prompt(
            agent, detection, original_message, speaker_id
        )
        
        try:
            # Appel GPT-4o avec paramètres optimisés pour interpellation
            response = self.enhanced_manager.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": interpellation_prompt},
                    {"role": "user", "content": f"INTERPELLATION DÉTECTÉE: {original_message}"}
                ],
                temperature=0.85,  # Légèrement plus créatif pour interpellations
                max_tokens=150,    # Réponses concises mais complètes
                presence_penalty=0.7,  # Anti-répétition renforcée
                frequency_penalty=0.5
            )
            
            agent_response = response.choices[0].message.content.strip()
            
            # Validation que la réponse reconnaît l'interpellation
            if not self._validates_interpellation_response(agent_response, detection):
                agent_response = self._enhance_interpellation_response(agent_response, detection)
            
            return agent_response
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse interpellation: {e}")
            # Fallback spécialisé pour interpellations
            return self._get_interpellation_fallback(detection, original_message)
    
    def _build_interpellation_prompt(self, agent: Dict, detection: InterpellationDetection,
                                   original_message: str, speaker_id: str) -> str:
        """Construit un prompt spécialisé pour répondre à une interpellation"""
        
        base_prompt = agent["system_prompt"]
        
        # Nom de l'interpellateur
        speaker_name = self._get_speaker_name(speaker_id)
        
        interpellation_instruction = f"""

🚨 INTERPELLATION DÉTECTÉE - RÉPONSE OBLIGATOIRE !

📢 CONTEXTE D'INTERPELLATION :
- Tu es interpellé(e) par {speaker_name}
- Type d'interpellation : {detection.interpellation_type}
- Phrase déclencheuse : "{detection.trigger_phrase}"
- Confiance : {detection.confidence:.2f}

🎯 INSTRUCTIONS SPÉCIALES POUR INTERPELLATION :
1. Tu DOIS répondre immédiatement et directement
2. Commence par reconnaître l'interpellation : "Oui {speaker_name}..." ou "Effectivement..."
3. Réponds précisément à ce qui t'est demandé
4. Sois plus direct et concis que d'habitude
5. Montre que tu as bien compris qu'on s'adresse à toi

💬 EXEMPLES DE DÉBUTS DE RÉPONSE :
- "Oui {speaker_name}, excellente question ! [réponse]"
- "Effectivement, je peux vous éclairer sur ce point : [réponse]"
- "Absolument ! En tant que [rôle], je dirais que [réponse]"
- "C'est une question qui me tient à cœur ! [réponse]"

🚨 INTERDICTION ABSOLUE :
- Ne pas ignorer l'interpellation
- Ne pas faire comme si tu n'avais pas été interpellé(e)
- Ne pas donner une réponse générique

MESSAGE ORIGINAL : "{original_message}"
"""
        
        return base_prompt + interpellation_instruction
    
    def _validates_interpellation_response(self, response: str, detection: InterpellationDetection) -> bool:
        """Valide qu'une réponse reconnaît bien l'interpellation"""
        
        response_lower = response.lower()
        
        # Indicateurs de reconnaissance d'interpellation
        recognition_indicators = [
            "oui", "effectivement", "absolument", "bien sûr",
            "excellente question", "c'est vrai", "vous avez raison",
            "je peux vous dire", "en tant que", "permettez-moi"
        ]
        
        # Au moins un indicateur de reconnaissance
        has_recognition = any(indicator in response_lower for indicator in recognition_indicators)
        
        # Pas de réponse trop générique
        generic_responses = [
            "c'est intéressant", "il faut voir", "ça dépend",
            "c'est compliqué", "il y a plusieurs aspects"
        ]
        
        is_not_generic = not any(generic in response_lower for generic in generic_responses)
        
        return has_recognition and is_not_generic
    
    def _enhance_interpellation_response(self, response: str, detection: InterpellationDetection) -> str:
        """Améliore une réponse d'interpellation qui ne reconnaît pas assez l'interpellation"""
        
        agent_name = detection.agent_name.split()[0]  # Prénom seulement
        
        enhanced_beginnings = [
            f"Oui, excellente question ! {response}",
            f"Effectivement, je peux vous éclairer : {response}",
            f"Absolument ! En tant qu'expert, {response.lower()}",
            f"C'est une question importante ! {response}"
        ]
        
        return random.choice(enhanced_beginnings)
    
    def _get_interpellation_fallback(self, detection: InterpellationDetection, 
                                   original_message: str) -> str:
        """Réponse de fallback spécialisée pour interpellations"""
        
        if "sarah" in detection.agent_id:
            return "Oui, excellente question ! En tant que journaliste, j'aimerais creuser ce point avec vous..."
        else:
            return "Effectivement ! Mon expertise me permet de vous éclairer sur cette question..."
    
    def _get_speaker_name(self, speaker_id: str) -> str:
        """Récupère le nom de l'interpellateur"""
        
        if speaker_id == "michel_dubois_animateur":
            return "Michel"
        elif speaker_id == "sarah_johnson_journaliste":
            return "Sarah"
        elif speaker_id == "marcus_thompson_expert":
            return "Marcus"
        else:
            # Utilisateur ou autre
            user_context = getattr(self.enhanced_manager, 'user_context', {})
            return user_context.get('user_name', 'Participant')
    
    def _get_interpellation_emotion(self, detection: InterpellationDetection, 
                                  message: str) -> str:
        """Détermine l'émotion appropriée pour répondre à l'interpellation"""
        
        message_lower = message.lower()
        
        # Détection du ton du message
        if any(word in message_lower for word in ["urgent", "important", "crucial"]):
            return "autorité"
        elif any(word in message_lower for word in ["intéressant", "fascinant", "curieux"]):
            return "curiosité"
        elif any(word in message_lower for word in ["problème", "difficulté", "inquiétude"]):
            return "empathie"
        else:
            return "enthousiasme"  # Par défaut

# Tests du système d'interpellation
async def test_interpellation_system():
    """Tests complets du système d'interpellation"""
    
    print("🧪 TESTS SYSTÈME D'INTERPELLATION")
    print("=" * 50)
    
    # Simulation d'un manager pour les tests
    class MockManager:
        def __init__(self):
            self.agents = {
                "sarah_johnson_journaliste": {
                    "name": "Sarah Johnson",
                    "system_prompt": "Tu es Sarah Johnson, journaliste..."
                },
                "marcus_thompson_expert": {
                    "name": "Marcus Thompson", 
                    "system_prompt": "Tu es Marcus Thompson, expert..."
                }
            }
            self.user_context = {'user_name': 'Pierre', 'user_subject': 'IA'}
    
    manager = MockManager()
    interpellation_manager = InterpellationResponseManager(manager)
    detector = AdvancedInterpellationDetector()
    
    # Test 1: Interpellation directe Sarah
    print("1. Test interpellation directe Sarah...")
    message = "Sarah, que pensez-vous de cette situation ?"
    detections = detector.detect_interpellations(message, "michel_dubois_animateur", [])
    
    assert len(detections) >= 1
    assert detections[0].agent_id == 'sarah_johnson_journaliste'
    assert detections[0].interpellation_type == 'direct'
    print("✅ Test 1 PASSÉ: Interpellation directe Sarah")
    
    # Test 2: Interpellation directe Marcus
    print("2. Test interpellation directe Marcus...")
    message = "Marcus, votre expertise sur ce point ?"
    detections = detector.detect_interpellations(message, "sarah_johnson_journaliste", [])
    
    assert len(detections) >= 1
    assert detections[0].agent_id == 'marcus_thompson_expert'
    assert detections[0].interpellation_type == 'direct'
    print("✅ Test 2 PASSÉ: Interpellation directe Marcus")
    
    # Test 3: Interpellation indirecte
    print("3. Test interpellation indirecte...")
    message = "Qu'en pense notre journaliste ?"
    detections = detector.detect_interpellations(message, "michel_dubois_animateur", [])
    
    assert len(detections) >= 1
    assert detections[0].agent_id == 'sarah_johnson_journaliste'
    assert detections[0].interpellation_type == 'indirect'
    print("✅ Test 3 PASSÉ: Interpellation indirecte")
    
    # Test 4: Pas d'interpellation
    print("4. Test pas d'interpellation...")
    message = "C'est un sujet très intéressant."
    detections = detector.detect_interpellations(message, "user", [])
    
    assert len(detections) == 0
    print("✅ Test 4 PASSÉ: Pas d'interpellation")
    
    print("🎉 SYSTÈME D'INTERPELLATION COMPLÈTEMENT VALIDÉ !")

if __name__ == "__main__":
    import asyncio
    asyncio.run(test_interpellation_system())
