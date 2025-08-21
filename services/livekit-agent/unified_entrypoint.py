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

# Configuration du logging (niveau ajustable via LOG_LEVEL)
_log_level = os.getenv("LOG_LEVEL", "DEBUG").upper()
logging.basicConfig(
    level=getattr(logging, _log_level, logging.DEBUG),
    format='%(asctime)s.%(msecs)03d %(levelname)s [%(name)s] %(filename)s:%(lineno)d - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
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
    'vente_produit',
    # Exercices Studio Situations Pro multi-agents
    'studio_debate_tv',
    'studio_debatPlateau',
    'studio_job_interview',
    'studio_entretienEmbauche',
    'studio_boardroom',
    'studio_reunionDirection',
    'studio_sales_conference',
    'studio_conferenceVente',
    'studio_keynote',
    'studio_conferencePublique',
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

    # Méthode 1: Métadonnées de la room (priorité ABSOLUE)
    if hasattr(ctx.room, 'metadata') and ctx.room.metadata:
        try:
            metadata = json.loads(ctx.room.metadata)
            if 'exercise_type' in metadata:
                exercise_type = metadata['exercise_type']
                # Normaliser immédiatement les alias connus
                exercise_type = _normalize_exercise_type(str(exercise_type), room_name)
                logger.info(f"✅ Exercice depuis métadonnées room: {exercise_type}")
                # RETOURNER IMMÉDIATEMENT si trouvé dans les métadonnées room
                logger.info(f"🎯 PRIORITÉ MÉTADONNÉES ROOM: {exercise_type}")
                return exercise_type
        except json.JSONDecodeError:
            logger.warning("⚠️ Métadonnées room JSON invalides")

    # Méthode 2: Métadonnées des participants (priorité haute)
    if hasattr(ctx.room, 'remote_participants'):
        participants = ctx.room.remote_participants
        try:
            # LiveKit Python expose souvent un dict {id: Participant}
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
                        # RETOURNER IMMÉDIATEMENT si trouvé dans les métadonnées participant
                        logger.info(f"🎯 PRIORITÉ MÉTADONNÉES PARTICIPANT: {exercise_type}")
                        return exercise_type
                except json.JSONDecodeError:
                    continue

    # Méthode 3: Analyse du nom de room (patterns) - SEULEMENT si aucune métadonnée trouvée
    logger.info("🔍 Aucune métadonnée trouvée, analyse du nom de room...")
    logger.info(f"🔍 ANALYSE DÉTAILLÉE: '{room_name}'")

    # Analyse par mots-clés pour diagnostic
    keywords_found = []
    if 'confidence_boost' in room_name:
        keywords_found.append('confidence_boost')
    if 'tribunal' in room_name or 'idees' in room_name:
        keywords_found.append('tribunal/idees')
    if 'cosmic' in room_name or 'voice_control' in room_name:
        keywords_found.append('cosmic/voice_control')
    if 'job_interview' in room_name:
        keywords_found.append('job_interview')
    if any(keyword in room_name for keyword in ['debat', 'debate', 'plateau']):
        keywords_found.append('debat/debate/plateau')
    if 'entretien' in room_name or 'interview' in room_name:
        keywords_found.append('entretien/interview')
    if 'negociation' in room_name:
        keywords_found.append('negociation')
    if 'presentation' in room_name or 'investisseurs' in room_name:
        keywords_found.append('presentation/investisseurs')
    if 'reunion' in room_name or 'boardroom' in room_name:
        keywords_found.append('reunion/boardroom')
    if 'conference' in room_name or 'keynote' in room_name:
        keywords_found.append('conference/keynote')
    if 'sales' in room_name or 'vente' in room_name:
        keywords_found.append('sales/vente')
    if 'studio' in room_name:
        keywords_found.append('studio')
    if 'situation' in room_name:
        keywords_found.append('situation')

    logger.info(f"🔍 MOTS-CLÉS TROUVÉS: {keywords_found}")

    # ✅ LOGIQUE RÉORGANISÉE AVEC PRIORITÉ CORRECTE
    if 'confidence_boost' in room_name:
        exercise_type = 'confidence_boost'
    elif 'tribunal' in room_name or 'idees' in room_name:
        exercise_type = 'tribunal_idees_impossibles'
    elif 'cosmic' in room_name or 'voice_control' in room_name:
        exercise_type = 'cosmic_voice_control'
    elif 'job_interview' in room_name:
        exercise_type = 'job_interview'
    # ✅ PRIORITÉ ABSOLUE : DÉBAT TV (avant 'studio' générique)
    elif any(keyword in room_name for keyword in ['debat', 'debate', 'plateau']):
        exercise_type = 'studio_debate_tv'  # ✅ PRIORITÉ DÉBAT TV
    elif 'entretien' in room_name or 'interview' in room_name:
        exercise_type = 'simulation_entretien'
    elif 'negociation' in room_name:
        exercise_type = 'negociation_commerciale'
    elif 'presentation' in room_name or 'investisseurs' in room_name:
        exercise_type = 'presentation_investisseurs'
    elif 'reunion' in room_name or 'boardroom' in room_name:
        exercise_type = 'studio_boardroom'
    elif 'conference' in room_name or 'keynote' in room_name:
        exercise_type = 'studio_keynote'
    elif 'sales' in room_name or 'vente' in room_name:
        exercise_type = 'studio_sales_conference'
    # ✅ 'studio' générique EN DERNIER (fallback pour autres studios)
    elif 'studio' in room_name or 'situation' in room_name:
        exercise_type = 'studio_situations_pro'

    # Normalisation finale (sécurité)
    if exercise_type:
        exercise_type = _normalize_exercise_type(str(exercise_type), room_name)

    # Méthode 4: Fallback par défaut
    if not exercise_type:
        exercise_type = 'confidence_boost'  # ✅ Fallback INDIVIDUEL par défaut
        logger.warning("⚠️ Aucune détection, fallback vers confidence_boost")

    logger.info(f"✅ Exercice détecté: {exercise_type}")
    logger.info(f"🔍 EST MULTI-AGENT: {exercise_type in MULTI_AGENT_EXERCISES}")
    logger.info(f"🔍 EST INDIVIDUAL: {exercise_type in INDIVIDUAL_EXERCISES}")

    # ✅ VALIDATION SPÉCIFIQUE POUR DÉBAT PLATEAU
    if 'debatplateau' in room_name.lower() and exercise_type != 'studio_debate_tv':
        logger.error(f"❌ ERREUR DÉTECTION: Room '{room_name}' devrait être 'studio_debate_tv' mais détectée comme '{exercise_type}'")
        logger.error("🔧 CORRECTION AUTOMATIQUE: Forçage vers studio_debate_tv")
        exercise_type = 'studio_debate_tv'
        logger.info(f"✅ CORRECTION APPLIQUÉE: {exercise_type}")

    return exercise_type

def _normalize_exercise_type(exercise_type: str, room_name: str) -> str:
    """Normalise les alias vers des IDs canoniques pour le routage.

    - Tous les alias de débat TV → studio_debate_tv
    - Alias débat contradictoire → debat_contradictoire
    """
    et = exercise_type.strip().lower()
    alias_map = {
        # Débat TV et ses alias (PRIORITÉ ABSOLUE)
        'studio_debate_tv': 'studio_debate_tv',
        'studio-debate-tv': 'studio_debate_tv',
        'studio_debat_tv': 'studio_debate_tv',
        'studio-debat-tv': 'studio_debate_tv',
        'studio_debatplateau': 'studio_debate_tv',  # ✅ AJOUTÉ
        'studio-debatplateau': 'studio_debate_tv',  # ✅ AJOUTÉ
        'debatplateau': 'studio_debate_tv',         # ✅ AJOUTÉ
        'debat_plateau': 'studio_debate_tv',
        'debat-plateau': 'studio_debate_tv',
        'debat_tv': 'studio_debate_tv',
        'debate_tv': 'studio_debate_tv',
        'debate-tv': 'studio_debate_tv',
        
        # Studio Situations Pro (générique)
        'studio_situations_pro': 'studio_situations_pro',
        
        # Entretien d'embauche
        'studio_job_interview': 'studio_job_interview',
        'studio_entretienEmbauche': 'studio_job_interview',
        
        # Réunion de direction
        'studio_boardroom': 'studio_boardroom',
        'studio_reunionDirection': 'studio_boardroom',
        
        # Conférence de vente
        'studio_sales_conference': 'studio_sales_conference',
        'studio_conferenceVente': 'studio_sales_conference',
        
        # Conférence publique
        'studio_keynote': 'studio_keynote',
        'studio_conferencePublique': 'studio_keynote',
        
        # Débat contradictoire
        'debatcontradictoire': 'debat_contradictoire',
        'debat_contradictoire': 'debat_contradictoire',
        'contradictoire': 'debat_contradictoire',
    }
    # Correspondance exacte via alias_map
    if et in alias_map:
        return alias_map[et]
    
    # ✅ HEURISTIQUE SPÉCIFIQUE POUR DÉBAT PLATEAU
    rn = (room_name or '').lower()
    if 'debatplateau' in rn or 'debat_plateau' in rn:
        return 'studio_debate_tv'
    if (('debat' in rn) or ('debate' in rn)) and (('tv' in rn) or ('plateau' in rn) or ('studio' in rn)):
        return 'studio_debate_tv'
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
