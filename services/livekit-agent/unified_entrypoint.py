#!/usr/bin/env python3
"""
Point d'entrée unifié pour router les exercices LiveKit
Détecte automatiquement le type d'exercice et route vers le bon système
"""

import os
import logging
import sys
from typing import Optional
from livekit import agents
from livekit.agents import AutoSubscribe, JobContext, JobRequest, WorkerOptions, cli

# Ajouter le répertoire courant au path pour les imports
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('unified_entrypoint')

import json
import logging

logger = logging.getLogger(__name__)

# Définition des listes d'exercices au niveau du module
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
    'vente_produit'
}

INDIVIDUAL_EXERCISES = {
    'confidence_boost',
    'tribunal_idees_impossibles',
    'cosmic_voice_control',
    'job_interview'
}


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
                logger.info(f"✅ Exercice depuis métadonnées room: {exercise_type}")
        except json.JSONDecodeError:
            logger.warning("⚠️ Métadonnées room JSON invalides")

    # Méthode 2: Métadonnées des participants
    if not exercise_type and hasattr(ctx.room, 'remote_participants'):
        for participant in ctx.room.remote_participants:
            if hasattr(participant, 'metadata') and participant.metadata:
                try:
                    metadata = json.loads(participant.metadata)
                    if 'exercise_type' in metadata:
                        exercise_type = metadata['exercise_type']
                        logger.info(f"✅ Exercice depuis métadonnées participant: {exercise_type}")
                        break
                except json.JSONDecodeError:
                    continue

    # ✅ CORRECTION CRITIQUE: Force multi-agents pour confidence_boost
    if exercise_type == 'confidence_boost':
        exercise_type = 'debat_contradictoire'  # Force débat TV
        logger.info("🧪 CORRECTION: confidence_boost → debat_contradictoire (force multi-agents)")

    # Méthode 3: Analyse du nom de room (patterns)
    if not exercise_type:
        if 'tribunal' in room_name or 'idees' in room_name:
            exercise_type = 'tribunal_idees_impossibles'
        elif 'studio' in room_name or 'situation' in room_name:
            exercise_type = 'studio_situations_pro'
        elif 'entretien' in room_name or 'interview' in room_name:
            exercise_type = 'simulation_entretien'
        elif 'debat' in room_name or 'contradictoire' in room_name:
            exercise_type = 'debat_contradictoire'

    # Méthode 4: Fallback par défaut
    if not exercise_type:
        exercise_type = 'debat_contradictoire'  # ✅ CHANGÉ: Multi-agents par défaut
        logger.warning("⚠️ Aucune détection, fallback vers debat_contradictoire")

    logger.info(f"✅ Exercice détecté: {exercise_type}")
    return exercise_type

async def unified_entrypoint(ctx):
    """Point d'entrée unifié avec routage intelligent"""
    
    logger.info("🚀 === UNIFIED ENTRYPOINT STARTED ===")
    logger.info(f"📍 Room: {ctx.room.name}")
    
    # Détection robuste de l'exercice
    exercise_type = await detect_exercise_from_context(ctx)
    
    # Routage vers le bon système
    if exercise_type in MULTI_AGENT_EXERCISES:
        logger.info(f"🎭 Routage vers MULTI-AGENT pour {exercise_type}")
        try:
            from multi_agent_main import multiagent_entrypoint
            await multiagent_entrypoint(ctx)
        except ImportError as e:
            logger.error(f"❌ Erreur import multi_agent_main: {e}")
            # Fallback vers individual
            from main import robust_entrypoint
            await robust_entrypoint(ctx)
    else:
        logger.info(f"👤 Routage vers INDIVIDUAL pour {exercise_type}")
        try:
            from main import robust_entrypoint
            await robust_entrypoint(ctx)
        except ImportError as e:
            logger.error(f"❌ Erreur import main: {e}")
            raise

async def request_fnc(req: JobRequest) -> None:
    """Accepter toutes les requêtes de job"""
    logger.info(f"Job request received for room: {req.room.name}")
    # Note: Dans LiveKit 1.2.4, accept() ne prend plus de paramètre
    # L'entrypoint est défini dans WorkerOptions
    await req.accept()

if __name__ == "__main__":
    # Configuration depuis les variables d'environnement
    livekit_url = os.getenv("LIVEKIT_URL", "ws://localhost:7880")
    api_key = os.getenv("LIVEKIT_API_KEY", "devkey")
    api_secret = os.getenv("LIVEKIT_API_SECRET", "devsecret123456789abcdef0123456789abcdef")
    
    logger.info("🚀 === UNIFIED LIVEKIT AGENT STARTING ===")
    logger.info("📌 MODE: UNIFIED ROUTER (Multi-Agents + Individual)")
    logger.info(f"🔗 LiveKit URL: {livekit_url}")
    logger.info(f"🔑 API Key: {api_key[:10]}...")
    logger.info("📋 Supported exercise types:")
    logger.info(f"  🎭 Multi-Agent ({len(MULTI_AGENT_EXERCISES)}): {MULTI_AGENT_EXERCISES}")
    logger.info(f"  👤 Individual ({len(INDIVIDUAL_EXERCISES)}): {INDIVIDUAL_EXERCISES}")
    logger.info("🎯 Router will automatically detect and route to correct system")
    logger.info("="*60)
    
    # Lancer le worker avec le point d'entrée unifié
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=unified_entrypoint,
            request_fnc=request_fnc,
            ws_url=livekit_url,
            api_key=api_key,
            api_secret=api_secret,
        )
    )
