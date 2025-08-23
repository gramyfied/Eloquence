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
# EXERCICES SITUATIONS PRO - Multi-agents LiveKit pour immersion totale
MULTI_AGENT_EXERCISES = {
    # Simulations de situations professionnelles multi-agents
    'studio_debate_tv',           # Débat plateau TV (Michel, Sarah, Marcus)
    'studio_debatPlateau',        # Alias pour débat plateau TV
    'studio_job_interview',       # Entretien d'embauche multi-agents
    'studio_entretienEmbauche',   # Alias pour entretien d'embauche
    'studio_boardroom',           # Réunion de direction
    'studio_reunionDirection',    # Alias pour réunion de direction
    'studio_sales_conference',    # Conférence de vente
    'studio_conferenceVente',     # Alias pour conférence de vente
    'studio_keynote',             # Conférence publique
    'studio_conferencePublique',  # Alias pour conférence publique
    'studio_situations_pro',      # Coaching général (Thomas, Sophie, Marc)
    
    # Anciens exercices (à migrer vers la nouvelle structure)
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
}

# EXERCICES INDIVIDUELS - Agent unique pour développement personnel
INDIVIDUAL_EXERCISES = {
    'confidence_boost',           # Boost de confiance avec agent unique
    'tribunal_idees_impossibles', # Défense d'idées impossibles
    'cosmic_voice_control',       # Contrôle vocal
    'job_interview'               # Entretien d'embauche individuel
}


async def detect_exercise_from_context(ctx):
    """Détection robuste de l'exercice avec support multi-agents"""

    room_name = ctx.room.name.lower()
    exercise_type = None

    logger.info("🔍 DIAGNOSTIC: Détection d'exercice en cours...")
    logger.info(f"🏠 Nom de room: {room_name}")

    # Méthode 1: Métadonnées de la room (priorité haute mais sans retour immédiat)
    if hasattr(ctx.room, 'metadata') and ctx.room.metadata:
        try:
            metadata = json.loads(ctx.room.metadata)
            if 'exercise_type' in metadata:
                exercise_type = metadata['exercise_type']
                # Normaliser immédiatement les alias connus
                exercise_type = _normalize_exercise_type(str(exercise_type), room_name)
                logger.info(f"✅ Exercice depuis métadonnées room: {exercise_type}")
                logger.info(f"🎯 PRIORITÉ MÉTADONNÉES ROOM (sans retour immédiat)")
        except json.JSONDecodeError:
            logger.warning("⚠️ Métadonnées room JSON invalides")

    # Méthode 2: Métadonnées des participants (priorité haute, sans retour immédiat)
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
                        logger.info(f"🎯 PRIORITÉ MÉTADONNÉES PARTICIPANT (sans retour immédiat)")
                        break
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

    # ✅ DIAGNOSTIC SPÉCIFIQUE DÉBAT
    room_lower = room_name.lower()
    debat_indicators = {
        'debatplateau': 'debatplateau' in room_lower,
        'debat_plateau': 'debat_plateau' in room_lower,
        'debat': 'debat' in room_lower,
        'debate': 'debate' in room_lower,
        'plateau': 'plateau' in room_lower,
        'studio': 'studio' in room_lower
    }

    logger.info(f"🎯 DIAGNOSTIC DÉBAT: {debat_indicators}")

    # Prédiction logique
    if debat_indicators['debatplateau'] or (debat_indicators['debat'] and debat_indicators['plateau']):
        logger.info("🎯 PRÉDICTION: Devrait être studio_debate_tv")
    elif debat_indicators['studio'] and not any([debat_indicators['debat'], debat_indicators['debate'], debat_indicators['plateau']]):
        logger.info("🎯 PRÉDICTION: Devrait être studio_situations_pro")

    # ✅ DÉTECTION SPÉCIFIQUE DÉBAT PLATEAU EN PREMIER (SITUATION PRO)
    if 'debatplateau' in room_name.lower():
        exercise_type = 'studio_debate_tv'
        logger.info(f"🎯 DÉBAT PLATEAU DÉTECTÉ DIRECTEMENT: {exercise_type}")
    # ✅ DÉTECTION EXERCICES INDIVIDUELS
    elif 'confidence_boost' in room_name:
        exercise_type = 'confidence_boost'
    elif 'tribunal' in room_name or 'idees' in room_name:
        exercise_type = 'tribunal_idees_impossibles'
    elif 'cosmic' in room_name or 'voice_control' in room_name:
        exercise_type = 'cosmic_voice_control'
    elif 'job_interview' in room_name and 'studio' not in room_name:
        exercise_type = 'job_interview'  # Exercice individuel
    # ✅ DÉTECTION SITUATIONS PRO MULTI-AGENTS
    elif 'studio_job_interview' in room_name or ('studio' in room_name and 'interview' in room_name):
        exercise_type = 'studio_job_interview'  # Situation pro multi-agents
    elif 'studio_boardroom' in room_name or ('studio' in room_name and 'reunion' in room_name):
        exercise_type = 'studio_boardroom'  # Situation pro multi-agents
    elif 'studio_sales' in room_name or ('studio' in room_name and 'vente' in room_name):
        exercise_type = 'studio_sales_conference'  # Situation pro multi-agents
    elif 'studio_keynote' in room_name or ('studio' in room_name and 'conference' in room_name):
        exercise_type = 'studio_keynote'  # Situation pro multi-agents
    # ✅ DÉTECTION GÉNÉRALE DÉBAT (SITUATION PRO)
    elif any(keyword in room_name for keyword in ['debat', 'debate', 'plateau']):
        exercise_type = 'studio_debate_tv'
        logger.info(f"🎯 DÉBAT GÉNÉRIQUE DÉTECTÉ: {exercise_type}")
    # ✅ DÉTECTION SITUATIONS PRO GÉNÉRIQUES
    elif 'studio' in room_name or 'situation' in room_name:
        exercise_type = 'studio_situations_pro'
        logger.info(f"🎯 STUDIO GÉNÉRIQUE DÉTECTÉ: {exercise_type}")
    # ✅ DÉTECTION ANCIENS EXERCICES (à migrer)
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

    # Normalisation finale (sécurité)
    if exercise_type:
        exercise_type = _normalize_exercise_type(str(exercise_type), room_name)

    # Méthode 4: Fallback par défaut
    if not exercise_type:
        exercise_type = 'studio_debate_tv'  # ✅ Fallback vers débat TV pour éviter erreurs silencieuses
        logger.warning("⚠️ Aucune détection, fallback vers studio_debate_tv")

    logger.info(f"✅ Exercice détecté: {exercise_type}")
    logger.info(f"🔍 EST MULTI-AGENT: {exercise_type in MULTI_AGENT_EXERCISES}")
    logger.info(f"🔍 EST INDIVIDUAL: {exercise_type in INDIVIDUAL_EXERCISES}")

    # ✅ VALIDATION ÉLARGIE POUR TOUS LES CAS DE DÉBAT
    room_lower = room_name.lower()
    should_be_debate = (
        'debatplateau' in room_lower or 
        'debat_plateau' in room_lower or 
        ('debat' in room_lower and 'plateau' in room_lower) or
        ('debate' in room_lower and 'tv' in room_lower) or
        ('studio' in room_lower and 'debat' in room_lower)
    )

    if should_be_debate and exercise_type != 'studio_debate_tv':
        logger.error(f"❌ ERREUR DÉTECTION CRITIQUE: Room '{room_name}' devrait être 'studio_debate_tv' mais détectée comme '{exercise_type}'")
        logger.error(f"🔍 ANALYSE: room_lower='{room_lower}', should_be_debate={should_be_debate}")
        logger.error("🔧 CORRECTION AUTOMATIQUE FORCÉE: Forçage vers studio_debate_tv")
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

    # Sécurité supplémentaire côté routage: forcer débat si les indicateurs sont présents
    room_lower_route = (ctx.room.name or "").lower()
    route_should_be_debate = (
        'debatplateau' in room_lower_route or
        'debat_plateau' in room_lower_route or
        ('debat' in room_lower_route and 'plateau' in room_lower_route) or
        ('debate' in room_lower_route and 'tv' in room_lower_route) or
        ('studio' in room_lower_route and 'debat' in room_lower_route)
    )
    if route_should_be_debate and exercise_type != 'studio_debate_tv':
        logger.error(
            f"❌ ROUTE FIX: Room '{ctx.room.name}' devrait être 'studio_debate_tv' mais '{exercise_type}' détecté. Forçage côté routage."
        )
        exercise_type = 'studio_debate_tv'
        logger.info(f"✅ ROUTE FIX APPLIQUÉ: {exercise_type}")
    
    # Routage vers le bon système
    if exercise_type in MULTI_AGENT_EXERCISES:
        logger.info(f"🎭 Routage vers MULTI-AGENT pour {exercise_type}")
        
        # ✅ TRANSMISSION EXERCISE_TYPE AU CONTEXTE
        ctx.exercise_type = exercise_type
        logger.info(f"🔗 EXERCISE_TYPE TRANSMIS AU CONTEXTE: {exercise_type}")
        
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
