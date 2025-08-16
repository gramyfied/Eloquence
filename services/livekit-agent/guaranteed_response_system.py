"""
Système de réponse garantie pour interpellations directes
"""
import asyncio
import logging
import os
from typing import Dict, Any

logger = logging.getLogger(__name__)


class GuaranteedResponseSystem:
    """Garantit qu'un agent répond TOUJOURS quand interpellé directement"""

    def __init__(self):
        # Timeouts ULTRA-RAPIDES pour réactivité maximale
        self.response_timeouts: Dict[str, float] = {
            'direct_address': 1.2,      # Réduit de 2.0 à 1.2s
            'opinion_request': 1.5,     # Réduit de 2.5 à 1.5s
            'action_request': 1.8,      # Réduit de 3.0 à 1.8s
            'explanation_request': 2.0, # Réduit de 3.5 à 2.0s
            'general_address': 1.2      # Réduit de 2.0 à 1.2s
        }

        self.emergency_responses: Dict[str, list[str]] = {
            'sarah': [
                "Sarah: Merci de me donner la parole, je réfléchis à votre question.",
                "Sarah: C'est une excellente question, laissez-moi y réfléchir un instant.",
                "Sarah: Je vous remercie de me solliciter sur ce point important."
            ],
            'marcus': [
                "Marcus: Merci, c'est une question intéressante que vous soulevez.",
                "Marcus: Je vous remercie de me donner l'opportunité de m'exprimer.",
                "Marcus: C'est effectivement un point crucial à aborder."
            ],
            'michel': [
                "Michel: Merci, permettez-moi de reformuler la question.",
                "Michel: C'est un point important que vous soulevez.",
                "Michel: Je vous remercie pour cette intervention."
            ]
        }

    async def ensure_response(self, agent_id: str, query: str, context: Dict[str, Any],
                              address_type: str = 'direct_address') -> Dict[str, Any]:
        """Garantit une réponse de l'agent interpellé"""

        timeout = self.response_timeouts.get(address_type, 3.0)
        agent = context.get('agents', {}).get(agent_id)

        if not agent:
            logger.error(f"❌ Agent {agent_id} non trouvé")
            return {'error': f'Agent {agent_id} not found'}

        logger.info(f"🚨 RÉPONSE GARANTIE pour {getattr(agent, 'name', agent_id)} (timeout: {timeout}s)")

        try:
            # Tentative de réponse normale avec timeout strict
            response = await asyncio.wait_for(
                self._generate_normal_response(agent, query, context, address_type),
                timeout=timeout
            )

            if response and str(response).strip():
                logger.info(f"✅ RÉPONSE NORMALE générée pour {getattr(agent, 'name', agent_id)}")
                return {
                    'agent_id': agent_id,
                    'agent_name': getattr(agent, 'name', agent_id),
                    'content': response,
                    'type': 'normal_guaranteed_response',
                    'response_time': timeout,
                    'success': True
                }
            else:
                raise Exception("Réponse vide générée")

        except (asyncio.TimeoutError, Exception) as e:  # noqa: PERF203
            logger.warning(f"⏰ TIMEOUT/ERREUR pour {getattr(agent, 'name', agent_id)}: {e}")

            # Fallback : réponse d'urgence IMMÉDIATE
            emergency_response = self._get_emergency_response(agent_id, query, address_type)

            logger.info(f"🆘 RÉPONSE D'URGENCE activée pour {getattr(agent, 'name', agent_id)}")

            return {
                'agent_id': agent_id,
                'agent_name': getattr(agent, 'name', agent_id),
                'content': emergency_response,
                'type': 'emergency_guaranteed_response',
                'response_time': timeout,
                'success': True,
                'fallback_reason': str(e)
            }

    async def _generate_normal_response(self, agent, query: str, context: Dict[str, Any],
                                        address_type: str) -> str:
        """Génère une réponse normale avec optimisations de vitesse"""

        agent_first_name = str(getattr(agent, 'name', 'Agent')).split()[0]

        # Prompt optimisé pour réactivité
        prompt = f"""Tu es {getattr(agent, 'name', 'Agent')} dans un débat TV en direct.

Tu viens d'être interpellé(e) DIRECTEMENT avec cette question/remarque :
"{query}"

🚨 SITUATION CRITIQUE : Tu DOIS répondre IMMÉDIATEMENT car tu as été explicitement sollicité(e).

INSTRUCTIONS ABSOLUES :
- Commence OBLIGATOIREMENT par "{agent_first_name}:"
- Réponds DIRECTEMENT à l'interpellation
- Sois naturel(le) et réactif(ve) comme dans un vrai débat TV
- Durée: 15-25 secondes maximum (2-3 phrases)
- Style: {getattr(agent, 'interaction_style', 'professionnel')}
- Ton: Engagé et confiant

CONTEXTE : Débat TV en direct, tu ne peux pas ignorer une interpellation directe.

Réponds MAINTENANT :"""

        # Configuration ULTRA-RAPIDE pour réactivité maximale
        response_config = {
            'max_tokens': 50,         # Encore plus court → ultra-rapide
            'temperature': 0.7,       # Plus créatif pour réponses naturelles
            'top_p': 0.9,
            'presence_penalty': 0.2
        }

        # Appel LLM optimisé (à adapter selon votre système)
        response = await self._call_llm_optimized(prompt, response_config)

        # S'assurer que la réponse commence par le prénom
        if response and not str(response).strip().lower().startswith(f"{agent_first_name.lower()}:"):
            response = f"{agent_first_name}: {str(response).strip()}"

        return str(response)

    def _get_emergency_response(self, agent_id: str, query: str, address_type: str) -> str:
        """Génère une réponse d'urgence contextuelle"""

        agent_responses = self.emergency_responses.get(agent_id, [
            "Merci de me donner la parole, je vais répondre à votre question."
        ])

        qlower = (query or "").lower()
        if 'opinion' in address_type or 'pensez' in qlower:
            return agent_responses[0]  # Réponse pour demande d'opinion
        elif 'action' in address_type or 'pouvez' in qlower:
            return agent_responses[1] if len(agent_responses) > 1 else agent_responses[0]
        else:
            return agent_responses[-1] if len(agent_responses) > 2 else agent_responses[0]

    async def _call_llm_optimized(self, prompt: str, config: Dict[str, Any]) -> str:
        """Appel LLM optimisé avec fallbacks robustes"""
        
        # ESSAI 1: LLM Optimizer (si disponible)
        try:
            # Import absolu pour éviter les erreurs de module
            import sys
            import os
            current_dir = os.path.dirname(os.path.abspath(__file__))
            if current_dir not in sys.path:
                sys.path.insert(0, current_dir)
            
            from llm_optimizer import llm_optimizer

            # Timeout ULTRA-RAPIDE pour réactivité maximale
            result = await asyncio.wait_for(
                llm_optimizer.get_optimized_response(
                    messages=[{"role": "system", "content": prompt}],
                    task_type='multi_agent_orchestration',
                    complexity={'num_agents': 3, 'context_length': len(prompt), 'interaction_depth': 1},
                    use_cache=True,
                    cache_ttl=120,
                ),
                timeout=1.0,  # Réduit de 1.6 à 1.0s
            )
            return str(result.get('response') or "Merci de me donner la parole.")
        except Exception as e:
            logger.debug(f"⚠️ LLM Optimizer non disponible: {e}")

        # ESSAI 2: OpenAI direct (si disponible)
        try:
            openai_key = os.getenv('OPENAI_API_KEY')
            if openai_key:
                import openai as openai_client
                client = openai_client.OpenAI(api_key=openai_key)
                
                response = await asyncio.wait_for(
                    client.chat.completions.create(
                        model="gpt-3.5-turbo",
                        messages=[{"role": "system", "content": prompt}],
                        temperature=0.8,
                        max_tokens=50,  # Réduit pour plus de rapidité
                    ),
                    timeout=1.2,  # Réduit de 2.0 à 1.2s
                )
                return response.choices[0].message.content
        except Exception as e:
            logger.debug(f"⚠️ OpenAI direct non disponible: {e}")

        # ESSAI 3: Mistral (si disponible)
        try:
            mistral_url = os.getenv('MISTRAL_BASE_URL')
            mistral_key = os.getenv('MISTRAL_API_KEY')
            if mistral_url and mistral_key:
                import aiohttp
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        mistral_url,
                        headers={
                            "Authorization": f"Bearer {mistral_key}",
                            "Content-Type": "application/json"
                        },
                        json={
                            "model": "mistral-small-latest",
                            "messages": [{"role": "system", "content": prompt}],
                            "max_tokens": 70,
                            "temperature": 0.7
                        },
                        timeout=aiohttp.ClientTimeout(total=2.0)
                    ) as resp:
                        if resp.status == 200:
                            data = await resp.json()
                            return data['choices'][0]['message']['content']
        except Exception as e:
            logger.debug(f"⚠️ Mistral non disponible: {e}")

        # FALLBACK FINAL: Réponse d'urgence
        logger.warning("🆘 Utilisation du fallback d'urgence pour LLM")
        await asyncio.sleep(0.1)  # Petit délai pour simuler le traitement
        return "Merci de me donner la parole, c'est une excellente question."


