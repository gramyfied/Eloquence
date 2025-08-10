#!/usr/bin/env python3
"""
Client LLM robuste avec fallbacks automatiques pour Eloquence
"""

import os
import asyncio
import aiohttp
import logging
from typing import Optional, Dict, Any, List
from dotenv import load_dotenv

# Charger l'environnement
load_dotenv()

# Configuration logging
logger = logging.getLogger(__name__)

class RobustLLMClient:
    """Client LLM robuste avec fallbacks automatiques"""
    
    def __init__(self):
        self.openai_client = None
        self.mistral_url = os.getenv('MISTRAL_BASE_URL')
        self.mistral_key = os.getenv('MISTRAL_API_KEY')
        
        # Initialiser OpenAI si clé disponible
        openai_key = os.getenv('OPENAI_API_KEY')
        if openai_key and openai_key.startswith('sk-'):
            try:
                from openai import AsyncOpenAI
                self.openai_client = AsyncOpenAI(api_key=openai_key)
                logger.info("✅ Client OpenAI initialisé")
            except ImportError:
                logger.warning("⚠️ Module openai non disponible")
        else:
            logger.warning("⚠️ Clé OpenAI manquante ou invalide")
    
    async def generate_response(self, messages: List[Dict[str, str]], max_tokens: int = 150) -> Optional[str]:
        """Génère une réponse avec fallback automatique"""
        
        # Tentative 1: OpenAI (priorité)
        if self.openai_client:
            try:
                logger.info("🤖 Tentative OpenAI...")
                response = await self.openai_client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=0.7
                )
                result = response.choices[0].message.content
                logger.info("✅ Réponse OpenAI générée")
                return result
            
            except Exception as e:
                logger.error(f"❌ Erreur OpenAI: {e}")
        
        # Tentative 2: Mistral Scaleway (fallback)
        if self.mistral_url and self.mistral_key:
            try:
                logger.info("🤖 Tentative Mistral Scaleway...")
                
                payload = {
                    "model": "mistral-7b-instruct",
                    "messages": messages,
                    "max_tokens": max_tokens,
                    "temperature": 0.7
                }
                
                headers = {
                    "Authorization": f"Bearer {self.mistral_key}",
                    "Content-Type": "application/json"
                }
                
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        self.mistral_url, 
                        json=payload, 
                        headers=headers,
                        timeout=aiohttp.ClientTimeout(total=10)
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            result = data['choices'][0]['message']['content']
                            logger.info("✅ Réponse Mistral générée")
                            return result
                        else:
                            logger.error(f"❌ Erreur Mistral HTTP: {response.status}")
            
            except Exception as e:
                logger.error(f"❌ Erreur Mistral: {e}")
        
        # Tentative 3: Réponse de fallback
        logger.warning("⚠️ Tous les LLM ont échoué, utilisation du fallback")
        return "Je vous entends bien ! Pouvez-vous répéter ou reformuler votre question ?"

# Instance globale
llm_client = RobustLLMClient()