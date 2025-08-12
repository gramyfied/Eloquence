"""
Optimiseur LLM avec cache Redis et sélection intelligente des modèles
Réduit les coûts tout en maintenant la qualité
"""
import os
import json
import hashlib
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import redis
from livekit.plugins import openai
import openai as openai_client

logger = logging.getLogger(__name__)

class LLMOptimizer:
    """Gestionnaire optimisé pour les appels LLM avec cache et sélection de modèle"""
    
    def __init__(self):
        self.api_key = os.getenv('OPENAI_API_KEY')
        self.redis_client = self._init_redis()
        self.cache_ttl = 3600  # 1 heure de cache par défaut
        self.usage_stats = {
            'cache_hits': 0,
            'cache_misses': 0,
            'gpt_35_calls': 0,
            'gpt_4_mini_calls': 0,
            'tokens_saved': 0,
            'cost_saved': 0.0
        }
        
        # Coûts approximatifs par 1000 tokens (en USD)
        self.model_costs = {
            'gpt-3.5-turbo': {'input': 0.0015, 'output': 0.002},
            'gpt-4o-mini': {'input': 0.00015, 'output': 0.0006}
        }
        
    def _init_redis(self) -> Optional[redis.Redis]:
        """Initialise la connexion Redis pour le cache"""
        try:
            redis_url = os.getenv('REDIS_URL', 'redis://redis:6379/2')
            client = redis.from_url(redis_url, decode_responses=True)
            client.ping()
            logger.info("✅ Redis connecté pour cache LLM")
            return client
        except Exception as e:
            logger.warning(f"⚠️ Redis non disponible pour cache: {e}")
            return None
    
    def _generate_cache_key(self, prompt: str, context: Dict) -> str:
        """Génère une clé de cache unique basée sur le prompt et le contexte"""
        cache_data = {
            'prompt': prompt,
            'context': json.dumps(context, sort_keys=True)
        }
        cache_string = json.dumps(cache_data, sort_keys=True)
        return f"llm_cache:{hashlib.md5(cache_string.encode()).hexdigest()}"
    
    def _should_use_advanced_model(self, task_type: str, complexity: Dict) -> bool:
        """Détermine si on doit utiliser un modèle avancé"""
        # Cas nécessitant GPT-4o-mini
        advanced_cases = [
            'multi_agent_orchestration',  # Orchestration multi-agents
            'personality_simulation',      # Simulation de personnalités
            'complex_reasoning',           # Raisonnement complexe
            'creative_storytelling',       # Narration créative
            'debate_moderation'           # Modération de débats
        ]
        
        if task_type in advanced_cases:
            return True
            
        # Analyse de complexité
        if complexity.get('num_agents', 1) > 1:
            return True
        if complexity.get('interaction_depth', 0) > 2:
            return True
        if complexity.get('context_length', 0) > 1000:
            return True
            
        return False
    
    async def get_optimized_response(
        self,
        messages: List[Dict[str, str]],
        task_type: str = 'simple_conversation',
        complexity: Optional[Dict] = None,
        use_cache: bool = True,
        cache_ttl: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Obtient une réponse LLM optimisée avec cache et sélection de modèle
        
        Args:
            messages: Messages de la conversation
            task_type: Type de tâche (simple_conversation, multi_agent_orchestration, etc.)
            complexity: Métriques de complexité
            use_cache: Utiliser le cache Redis
            cache_ttl: Durée de vie du cache en secondes
        
        Returns:
            Dict contenant la réponse et les métadonnées
        """
        complexity = complexity or {}
        cache_ttl = cache_ttl or self.cache_ttl
        
        # Vérifier le cache si activé
        if use_cache and self.redis_client:
            # Utiliser TOUT le contenu des messages (system + user) pour la clé de cache
            # afin d'éviter de réutiliser une réponse générique sur « Génère ta réaction ... »
            compound_prompt = "\n".join(
                [f"{m.get('role','')}::{m.get('content','')}" for m in messages]
            ) if messages else ''
            cache_key = self._generate_cache_key(
                compound_prompt,
                {'task_type': task_type, 'complexity': complexity}
            )
            
            cached_response = self._get_cached_response(cache_key)
            if cached_response:
                self.usage_stats['cache_hits'] += 1
                logger.debug(f"✅ Cache hit pour {task_type}")
                return cached_response
            else:
                self.usage_stats['cache_misses'] += 1
        
        # Sélection intelligente du modèle
        use_advanced = self._should_use_advanced_model(task_type, complexity)
        model = 'gpt-4o-mini' if use_advanced else 'gpt-3.5-turbo'
        
        # Optimisation des prompts pour réduire les tokens
        optimized_messages = self._optimize_messages(messages, task_type)
        
        try:
            # Appel API OpenAI
            client = openai_client.OpenAI(api_key=self.api_key)
            
            # Paramètres optimisés selon le type de tâche
            temperature = self._get_optimal_temperature(task_type)
            max_tokens = self._get_optimal_max_tokens(task_type)
            
            response = client.chat.completions.create(
                model=model,
                messages=optimized_messages,
                temperature=temperature,
                max_tokens=max_tokens
            )
            
            # Statistiques d'utilisation
            if use_advanced:
                self.usage_stats['gpt_4_mini_calls'] += 1
            else:
                self.usage_stats['gpt_35_calls'] += 1
            
            # Calcul des économies
            if not use_advanced:
                # Économie en utilisant GPT-3.5 au lieu de GPT-4o-mini
                tokens_used = response.usage.total_tokens if hasattr(response, 'usage') else 100
                cost_difference = (
                    self.model_costs['gpt-4o-mini']['input'] - 
                    self.model_costs['gpt-3.5-turbo']['input']
                ) * tokens_used / 1000
                self.usage_stats['cost_saved'] += cost_difference
                self.usage_stats['tokens_saved'] += tokens_used
            
            result = {
                'response': response.choices[0].message.content,
                'model': model,
                'task_type': task_type,
                'cached': False,
                'timestamp': datetime.now().isoformat(),
                'usage': {
                    'prompt_tokens': response.usage.prompt_tokens if hasattr(response, 'usage') else 0,
                    'completion_tokens': response.usage.completion_tokens if hasattr(response, 'usage') else 0,
                    'total_tokens': response.usage.total_tokens if hasattr(response, 'usage') else 0
                }
            }
            
            # Mettre en cache si activé
            if use_cache and self.redis_client and 'cache_key' in locals():
                self._cache_response(cache_key, result, cache_ttl)
            
            return result
            
        except Exception as e:
            logger.error(f"❌ Erreur appel LLM optimisé: {e}")
            raise
    
    def _optimize_messages(self, messages: List[Dict[str, str]], task_type: str) -> List[Dict[str, str]]:
        """Optimise les messages pour réduire les tokens"""
        optimized = []
        
        for msg in messages:
            content = msg['content']
            
            # Compression du contexte pour les tâches simples
            if task_type == 'simple_conversation' and len(content) > 500:
                # Garder seulement l'essentiel pour les conversations simples
                content = self._compress_text(content, max_length=500)
            
            # Suppression des répétitions
            content = self._remove_redundancies(content)
            
            optimized.append({
                'role': msg['role'],
                'content': content
            })
        
        return optimized
    
    def _compress_text(self, text: str, max_length: int = 500) -> str:
        """Compresse le texte en gardant l'essentiel"""
        if len(text) <= max_length:
            return text
            
        # Garder le début et la fin qui sont souvent les plus importants
        start = text[:max_length//2]
        end = text[-max_length//2:]
        return f"{start}... [texte condensé] ...{end}"
    
    def _remove_redundancies(self, text: str) -> str:
        """Supprime les répétitions et redondances"""
        lines = text.split('\n')
        unique_lines = []
        seen = set()
        
        for line in lines:
            line_clean = line.strip()
            if line_clean and line_clean not in seen:
                unique_lines.append(line)
                seen.add(line_clean)
        
        return '\n'.join(unique_lines)
    
    def _get_optimal_temperature(self, task_type: str) -> float:
        """Retourne la température optimale selon le type de tâche"""
        temperatures = {
            'simple_conversation': 0.7,
            'multi_agent_orchestration': 0.85,  # + créativité orchestrée
            'personality_simulation': 0.9,
            'complex_reasoning': 0.75,          # Sarah plus créative/affirmée
            'creative_storytelling': 0.9,
            'debate_moderation': 0.65,          # Michel un peu plus vivant
            'technical_explanation': 0.45       # Marcus neutre mais moins froid
        }
        return temperatures.get(task_type, 0.7)
    
    def _get_optimal_max_tokens(self, task_type: str) -> int:
        """Retourne le nombre optimal de tokens selon le type de tâche"""
        max_tokens = {
            'simple_conversation': 100,      # Réponses courtes
            'multi_agent_orchestration': 200, # Plus de contexte
            'personality_simulation': 150,    # Personnalités détaillées
            'complex_reasoning': 300,         # Explications longues
            'creative_storytelling': 250,     # Narration
            'debate_moderation': 150,         # Modération concise
            'technical_explanation': 200      # Explications techniques
        }
        return max_tokens.get(task_type, 150)
    
    def _get_cached_response(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """Récupère une réponse du cache"""
        try:
            if not self.redis_client:
                return None
                
            cached = self.redis_client.get(cache_key)
            if cached:
                result = json.loads(cached)
                result['cached'] = True
                logger.debug(f"✅ Réponse récupérée du cache: {cache_key[:20]}...")
                return result
        except Exception as e:
            logger.warning(f"⚠️ Erreur lecture cache: {e}")
        return None
    
    def _cache_response(self, cache_key: str, response: Dict[str, Any], ttl: int):
        """Met en cache une réponse"""
        try:
            if not self.redis_client:
                return
                
            self.redis_client.setex(
                cache_key,
                ttl,
                json.dumps(response)
            )
            logger.debug(f"✅ Réponse mise en cache: {cache_key[:20]}... (TTL: {ttl}s)")
        except Exception as e:
            logger.warning(f"⚠️ Erreur écriture cache: {e}")
    
    def get_usage_statistics(self) -> Dict[str, Any]:
        """Retourne les statistiques d'utilisation"""
        total_calls = self.usage_stats['gpt_35_calls'] + self.usage_stats['gpt_4_mini_calls']
        cache_rate = (
            self.usage_stats['cache_hits'] / 
            max(self.usage_stats['cache_hits'] + self.usage_stats['cache_misses'], 1)
        ) * 100
        
        return {
            'total_calls': total_calls,
            'cache_hits': self.usage_stats['cache_hits'],
            'cache_misses': self.usage_stats['cache_misses'],
            'cache_hit_rate': f"{cache_rate:.1f}%",
            'gpt_35_calls': self.usage_stats['gpt_35_calls'],
            'gpt_4_mini_calls': self.usage_stats['gpt_4_mini_calls'],
            'tokens_saved': self.usage_stats['tokens_saved'],
            'estimated_cost_saved': f"${self.usage_stats['cost_saved']:.4f}",
            'optimization_rate': f"{(self.usage_stats['gpt_35_calls'] / max(total_calls, 1)) * 100:.1f}%"
        }
    
    def reset_statistics(self):
        """Réinitialise les statistiques"""
        self.usage_stats = {
            'cache_hits': 0,
            'cache_misses': 0,
            'gpt_35_calls': 0,
            'gpt_4_mini_calls': 0,
            'tokens_saved': 0,
            'cost_saved': 0.0
        }
        logger.info("📊 Statistiques LLM réinitialisées")


# Instance globale de l'optimiseur
llm_optimizer = LLMOptimizer()

async def get_optimized_llm_response(
    prompt: str,
    context: str = "",
    task_type: str = "simple_conversation",
    agent_name: Optional[str] = None
) -> str:
    """
    Interface simplifiée pour obtenir une réponse LLM optimisée
    
    Args:
        prompt: Le prompt utilisateur
        context: Contexte additionnel
        task_type: Type de tâche
        agent_name: Nom de l'agent (pour multi-agents)
    
    Returns:
        La réponse générée
    """
    messages = []
    
    # Construire les messages selon le contexte
    if context:
        messages.append({"role": "system", "content": context})
    
    messages.append({"role": "user", "content": prompt})
    
    # Déterminer la complexité
    complexity = {
        'num_agents': 1 if not agent_name else 3,  # Estimation pour multi-agents
        'context_length': len(context),
        'interaction_depth': 1
    }
    
    # Ajuster le type de tâche pour les multi-agents
    if agent_name and 'studio' in task_type.lower():
        task_type = 'multi_agent_orchestration'
    
    try:
        result = await llm_optimizer.get_optimized_response(
            messages=messages,
            task_type=task_type,
            complexity=complexity,
            use_cache=True
        )
        
        # Log des statistiques périodiquement
        if llm_optimizer.usage_stats['total_calls'] % 10 == 0:
            stats = llm_optimizer.get_usage_statistics()
            logger.info(f"📊 Stats LLM: {stats}")
        
        return result['response']
        
    except Exception as e:
        logger.error(f"❌ Erreur optimisation LLM: {e}")
        # Fallback direct sans optimisation
        client = openai_client.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0.7,
            max_tokens=150
        )
        return response.choices[0].message.content