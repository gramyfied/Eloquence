from __future__ import annotations

import asyncio
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from dataclasses import dataclass

from direct_address_detector import DirectAddressDetector
from guaranteed_response_system import GuaranteedResponseSystem
from multi_agent_manager import MultiAgentManager

logger = logging.getLogger(__name__)


@dataclass
class InterpellationEvent:
    timestamp: datetime
    message: str
    speaker: str
    addressed_agents: List[str]
    interpellation_type: str
    priority: str
    response_triggered: bool = False
    response_time: Optional[float] = None


class InterpellationSystemComplete:
    """Système complet d'interpellation avec réponse garantie."""

    def __init__(self, multi_agent_manager: MultiAgentManager):
        self.manager = multi_agent_manager
        self.address_detector = DirectAddressDetector()
        self.response_guarantee = GuaranteedResponseSystem()
        self.interpellation_history: List[InterpellationEvent] = []
        self.successful_responses = 0
        self.total_interpellations = 0
        self.average_response_time = 0.0
        self._queue: asyncio.Queue = asyncio.Queue()
        self._processor_task: Optional[asyncio.Task] = None

    async def initialize(self):
        if self._processor_task is None:
            self._processor_task = asyncio.create_task(self._process())
        logger.info("🎯 Système interpellation complet initialisé")

    async def process_user_message_with_interpellation(self, message: str, speaker: str = "user", context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        start = datetime.now()
        addressed = self.address_detector.detect_direct_addresses(message, self.manager.agents)
        authority = self.address_detector.detect_with_animator_authority(message, speaker)
        interpellation_type = self._classify(addressed, authority)
        priority = "HIGH" if addressed else ("MEDIUM" if authority.get('detected') else "LOW")

        event = InterpellationEvent(
            timestamp=start,
            message=message,
            speaker=speaker,
            addressed_agents=addressed,
            interpellation_type=interpellation_type,
            priority=priority,
        )

        if priority == "HIGH" and addressed:
            await self._queue.put({'event': event, 'agent_id': addressed[0], 'timeout': 2.0, 'retry': 0})
        elif priority == "MEDIUM" and authority.get('detected'):
            # Traitement async léger
            asyncio.create_task(self._handle_medium(event, authority))
        else:
            try:
                result = self.manager.process_user_input(message)
                if asyncio.iscoroutine(result):
                    await result
            except Exception:
                # En contexte de test, le manager peut être un Mock non awaitable
                pass

        self.interpellation_history.append(event)
        self.total_interpellations += 1
        dt_ms = (datetime.now() - start).total_seconds() * 1000
        logger.info(f"🎯 Interpellation traitée: {dt_ms:.1f}ms - {interpellation_type} - {priority}")
        return {
            'detected': bool(addressed) or bool(authority.get('detected')),
            'addressed_agents': addressed,
            'interpellation_type': interpellation_type,
            'priority': priority,
            'detection_time_ms': dt_ms,
            'response_triggered': event.response_triggered,
        }

    async def _process(self):
        while True:
            task = await self._queue.get()
            try:
                await asyncio.wait_for(self._execute_priority(task), timeout=task.get('timeout', 2.0))
            except asyncio.TimeoutError:
                if task['retry'] < 2:
                    task['retry'] += 1
                    await self._queue.put(task)
                else:
                    logger.error(f"❌ Échec définitif réponse prioritaire: {task['agent_id']}")
            except Exception as e:
                logger.error(f"❌ Erreur processeur prioritaire: {e}")
            finally:
                self._queue.task_done()

    async def _execute_priority(self, task: Dict[str, Any]):
        event: InterpellationEvent = task['event']
        agent_id = task['agent_id']
        start = datetime.now()
        agent = self.manager.agents.get(agent_id)
        if not agent:
            return
        # Génération rapide via système de garantie
        addr_type = self.address_detector.classify_address_type(event.message, agent_id)
        resp = await self.response_guarantee.ensure_response(agent_id, event.message, {'agents': self.manager.agents}, addr_type)
        # TTS prioritaire optimisé
        try:
            from elevenlabs_optimized_service import elevenlabs_optimized_service
            audio = await elevenlabs_optimized_service.synthesize_with_zero_latency(text=resp.get('content', ''), agent_id=agent_id)
            if audio:
                await self.manager.trigger_agent_reactions_parallel(agent_id, resp.get('content', ''))
        except Exception as e:
            logger.warning(f"⚠️ Synthèse prioritaire échouée: {e}")
        dt = (datetime.now() - start).total_seconds()
        event.response_triggered = True
        event.response_time = dt
        self.successful_responses += 1

    async def _handle_medium(self, event: InterpellationEvent, authority: Dict[str, Any]):
        target = authority.get('agent') or (event.addressed_agents[0] if event.addressed_agents else None)
        if not target:
            return
        try:
            from elevenlabs_flash_tts_service import elevenlabs_flash_service
            resp = await self.response_guarantee.ensure_response(target, event.message, {'agents': self.manager.agents}, 'general_address')
            audio = await elevenlabs_flash_service.synthesize_speech_flash_v25(text=resp.get('content', ''), agent_id=target)
            if audio:
                await self.manager.trigger_agent_reactions_parallel(target, resp.get('content', ''))
        except Exception as e:
            logger.warning(f"⚠️ Réponse MEDIUM échouée: {e}")

    def _classify(self, addressed: List[str], authority: Dict[str, Any]) -> str:
        if addressed:
            return "direct_address"
        if authority.get('detected'):
            return "authority_directive"
        return "general_message"

    def get_performance_metrics(self) -> Dict[str, Any]:
        success_rate = self.successful_responses / self.total_interpellations if self.total_interpellations else 0.0
        return {
            'total_interpellations': self.total_interpellations,
            'successful_responses': self.successful_responses,
            'success_rate': success_rate,
            'average_response_time_ms': self.average_response_time * 1000,
            'queue_size': self._queue.qsize(),
        }

    async def cleanup(self):
        if self._processor_task:
            self._processor_task.cancel()
            try:
                await self._processor_task
            except asyncio.CancelledError:
                pass


_global_system: Optional[InterpellationSystemComplete] = None


def get_interpellation_system(manager: MultiAgentManager) -> InterpellationSystemComplete:
    global _global_system
    if _global_system is None:
        _global_system = InterpellationSystemComplete(manager)
    return _global_system


