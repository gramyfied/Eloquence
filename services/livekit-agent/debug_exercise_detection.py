#!/usr/bin/env python3
"""
Script de débogage pour vérifier la détection d'exercice
"""

import asyncio
import json
import logging
from typing import Dict, Any

# Configuration du logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s | %(levelname)s [%(name)s] %(filename)s:%(lineno)d - %(message)s')
logger = logging.getLogger(__name__)

# Simuler le contexte de room
class MockRoom:
    def __init__(self, name: str, metadata: str = None):
        self.name = name
        self.metadata = metadata
        self.remote_participants = {}

class MockContext:
    def __init__(self, room_name: str, room_metadata: str = None):
        self.room = MockRoom(room_name, room_metadata)

# Copier la logique de détection depuis unified_entrypoint.py
MULTI_AGENT_EXERCISES = {
    'studio_situations_pro',
    'simulation_entretien',
    'negociation_commerciale',
    'presentation_investisseurs',
    'reunion_equipe',
    'pitch_elevator',
    'conference_presse',
    'debat_contradictoire',
    'mediation_conflit',
    'formation_equipe',
    'entretien_evaluation',
    'vente_produit',
    'studio_debate_tv',
    'studio_debatPlateau',
}

def _normalize_exercise_type(exercise_type: str, room_name: str) -> str:
    """Normalise les alias vers des IDs canoniques pour le routage."""
    et = exercise_type.strip().lower()
    alias_map = {
        'studio_debate_tv': 'studio_debate_tv',
        'studio-debate-tv': 'studio_debate_tv',
        'studio_debat_tv': 'studio_debate_tv',
        'studio-debat-tv': 'studio_debate_tv',
        'studio_debatplateau': 'studio_debate_tv',
        'studio-debatplateau': 'studio_debate_tv',
        'debat_plateau': 'studio_debate_tv',
        'debat-plateau': 'studio_debate_tv',
        'debat_tv': 'studio_debate_tv',
        'debate_tv': 'studio_debate_tv',
        'debate-tv': 'studio_debate_tv',
        'debatcontradictoire': 'debat_contradictoire',
        'debat_contradictoire': 'debat_contradictoire',
        'contradictoire': 'debat_contradictoire',
    }
    if et in alias_map:
        return alias_map[et]
    rn = (room_name or '').lower()
    if (('debat' in rn) or ('debate' in rn)) and (('tv' in rn) or ('plateau' in rn) or ('studio' in rn)):
        return 'studio_debate_tv'
    return exercise_type

async def detect_exercise_from_context(ctx):
    """Détection robuste de l'exercice avec support multi-agents"""

    room_name = ctx.room.name.lower()
    exercise_type = None

    logger.info("🔍 DIAGNOSTIC: Détection d'exercice en cours...")
    logger.info(f"🏠 Nom de room: {room_name}")

    # Méthode 1: Métadonnées de la room (priorité)
    if hasattr(ctx.room, 'metadata') and ctx.room.metadata:
        try:
            metadata = json.loads(ctx.room.metadata)
            if 'exercise_type' in metadata:
                exercise_type = metadata['exercise_type']
                exercise_type = _normalize_exercise_type(str(exercise_type), room_name)
                logger.info(f"✅ Exercice depuis métadonnées room: {exercise_type}")
        except json.JSONDecodeError:
            logger.warning("⚠️ Métadonnées room JSON invalides")

    # Méthode 2: Métadonnées des participants
    if not exercise_type and hasattr(ctx.room, 'remote_participants'):
        participants = ctx.room.remote_participants
        try:
            iterable = participants.values() if isinstance(participants, dict) else participants
        except Exception:
            iterable = participants
        for participant in iterable:
            if hasattr(participant, 'metadata') and participant.metadata:
                try:
                    metadata = json.loads(participant.metadata)
                    if 'exercise_type' in metadata:
                        exercise_type = metadata['exercise_type']
                        exercise_type = _normalize_exercise_type(str(exercise_type), room_name)
                        logger.info(f"✅ Exercice depuis métadonnées participant: {exercise_type}")
                        break
                except json.JSONDecodeError:
                    continue

    # Méthode 3: Analyse du nom de room (patterns)
    if not exercise_type:
        if 'confidence_boost' in room_name:
            exercise_type = 'confidence_boost'
        elif 'tribunal' in room_name or 'idees' in room_name:
            exercise_type = 'tribunal_idees_impossibles'
        elif 'studio' in room_name or 'situation' in room_name:
            exercise_type = 'studio_situations_pro'
        elif 'entretien' in room_name or 'interview' in room_name:
            exercise_type = 'simulation_entretien'
        elif 'debat' in room_name or 'debate' in room_name or 'plateau' in room_name:
            if 'tv' in room_name or 'plateau' in room_name or 'studio' in room_name:
                exercise_type = 'studio_debate_tv'
            else:
                exercise_type = 'debat_contradictoire'

    # Normalisation finale (sécurité)
    if exercise_type:
        exercise_type = _normalize_exercise_type(str(exercise_type), room_name)

    # Méthode 4: Fallback par défaut
    if not exercise_type:
        exercise_type = 'confidence_boost'
        logger.warning("⚠️ Aucune détection, fallback vers confidence_boost")

    logger.info(f"✅ Exercice détecté: {exercise_type}")
    return exercise_type

async def test_exercise_detection():
    """Test de la détection d'exercice avec différents noms de room"""
    
    test_cases = [
        # Noms de room qui devraient détecter studio_debate_tv
        ("studio-debat-tv", None),
        ("studio_debat_tv", None),
        ("debat-plateau", None),
        ("debat_tv", None),
        ("debate-tv", None),
        ("studio-debatplateau", None),
        
        # Noms de room avec métadonnées
        ("test-room", '{"exercise_type": "studio_debate_tv"}'),
        ("test-room", '{"exercise_type": "studio-debat-tv"}'),
        
        # Noms de room qui devraient détecter confidence_boost
        ("confidence-boost", None),
        ("test-confidence", None),
        ("random-room", None),  # Fallback par défaut
    ]
    
    logger.info("🧪 TEST DE DÉTECTION D'EXERCICE")
    logger.info("="*50)
    
    for room_name, metadata in test_cases:
        ctx = MockContext(room_name, metadata)
        exercise_type = await detect_exercise_from_context(ctx)
        
        is_multi_agent = exercise_type in MULTI_AGENT_EXERCISES
        system_used = "🎭 MULTI-AGENT (GPT-4o)" if is_multi_agent else "👤 INDIVIDUAL (gpt-4o-mini)"
        
        logger.info(f"🏠 Room: '{room_name}' | Metadata: '{metadata}'")
        logger.info(f"   → Détecté: {exercise_type} | {system_used}")
        logger.info("-" * 30)

if __name__ == "__main__":
    asyncio.run(test_exercise_detection())
