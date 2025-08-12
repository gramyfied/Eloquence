#!/usr/bin/env python3
import asyncio
import logging
import os
import random

from multi_agent_config import ExerciseTemplates
from multi_agent_manager import MultiAgentManager


async def run_quick_test():
    logging.basicConfig(level=logging.INFO, format='%(message)s')
    logger = logging.getLogger(__name__)

    # Désactiver appels réseau LLM pour forcer les fallbacks
    os.environ.pop('OPENAI_API_KEY', None)

    # Configuration et manager
    config = ExerciseTemplates.studio_debate_tv()
    manager = MultiAgentManager(config)
    manager.initialize_session()

    random.seed(42)

    test_messages = [
        "Bonjour à tous, parlons d'intelligence artificielle et de ses impacts.",
        "Je pense que l'IA est toujours bénéfique, qu'en pensez-vous ?",
        "Pourquoi certains experts disent que c'est une révolution mais aussi un risque ?",
    ]

    for idx, user_msg in enumerate(test_messages, 1):
        logger.info(f"\n===== TOUR {idx} - UTILISATEUR =====")
        logger.info(f"User: {user_msg}")
        resp = await manager.handle_user_input(user_msg)

        primary_id = resp.get('primary_speaker')
        primary = resp.get('primary_response')
        secondary = resp.get('secondary_responses', [])

        primary_name = manager.agents[primary_id].name if primary_id in manager.agents else 'Inconnu'
        logger.info(f"\n🎤 Principal → {primary_name}: {primary}")

        if secondary:
            logger.info("\n🎭 Réactions secondaires:")
            for r in secondary:
                logger.info(f"  - {r['agent_name']} (delay {r['delay_ms']}ms): {r['reaction']}")
        else:
            logger.info("\n(aucune réaction secondaire)")

    logger.info("\n===== FIN TEST RAPIDE =====")


if __name__ == "__main__":
    asyncio.run(run_quick_test())


