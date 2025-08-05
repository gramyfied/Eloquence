#!/usr/bin/env python3
"""
🎯 Générateur Automatique d'Exercices Vocaux pour Eloquence
============================================================

Ce générateur permet de créer automatiquement de nouveaux exercices
à partir d'une simple description en français.

Services disponibles :
- stt_service (Speech-to-Text) : transcribe
- audio_analysis_service : analyze_prosody, analyze_text  
- tts_service (Text-to-Speech) : synthesize
- livekit : health

Utilisation :
python exercise_generator.py "Je veux un exercice qui transcrit la voix, analyse la prosodie et donne un retour vocal"
"""

import json
import re
import sys
from typing import Dict, List, Any, Optional
from datetime import datetime
import uuid


class EloquenceExerciseGenerator:
    """Générateur intelligent d'exercices vocaux pour Eloquence"""
    
    def __init__(self):
        self.available_services = {
            "stt_service": {
                "endpoints": ["transcribe"],
                "description": "Service de transcription audio vers texte"
            },
            "audio_analysis_service": {
                "endpoints": ["analyze_prosody", "analyze_text"],
                "description": "Service d'analyse audio et textuelle"
            },
            "tts_service": {
                "endpoints": ["synthesize"],
                "description": "Service de synthèse vocale"
            },
            "livekit": {
                "endpoints": ["health"],
                "description": "Service de communication temps réel"
            }
        }
        
        self.exercise_patterns = {
            "transcription": ["transcrit", "speech-to-text", "stt", "reconnaissance vocale"],
            "analysis_prosody": ["prosodie", "intonation", "rythme", "pauses", "analyse vocale"],
            "analysis_text": ["analyse texte", "mots de remplissage", "clarté", "contenu"],
            "synthesis": ["retour vocal", "synthèse", "tts", "réponse audio", "feedback vocal"],
            "realtime": ["temps réel", "live", "streaming", "direct", "instantané"]
        }
        
        self.gamification_templates = {
            "xp_rewards": {
                "completion": 100,
                "perfect_score": 150,
                "improvement": 50,
                "streak_bonus": 25
            },
            "badges": [
                {"id": "first_attempt", "name": "Premier Essai", "condition": "total_sessions >= 1"},
                {"id": "streak_master", "name": "Maître des Séries", "condition": "current_streak >= 7"},
                {"id": "perfect_speech", "name": "Orateur Parfait", "condition": "score >= 95"},
                {"id": "improvement_champion", "name": "Champion du Progrès", "condition": "improvement >= 20"}
            ]
        }

    def generate_exercise_id(self, description: str) -> str:
        """Génère un ID unique pour l'exercice basé sur la description"""
        # Extraire les mots clés principaux
        words = re.findall(r'\b\w+\b', description.lower())
        key_words = [w for w in words if len(w) > 3 and w not in ['pour', 'avec', 'dans', 'exercice', 'qui', 'puis', 'analyse']]
        
        if len(key_words) >= 2:
            exercise_id = "_".join(key_words[:3])
        else:
            exercise_id = f"exercice_{uuid.uuid4().hex[:8]}"
            
        return exercise_id

    def analyze_description(self, description: str) -> Dict[str, bool]:
        """Analyse la description pour identifier les services nécessaires"""
        desc_lower = description.lower()
        
        needs = {
            "transcription": False,
            "prosody_analysis": False,
            "text_analysis": False,
            "synthesis": False,
            "realtime": False
        }
        
        # Détecter les besoins basés sur les mots-clés
        for need, patterns in self.exercise_patterns.items():
            for pattern in patterns:
                if pattern in desc_lower:
                    if need == "analysis_prosody":
                        needs["prosody_analysis"] = True
                    elif need == "analysis_text":
                        needs["text_analysis"] = True
                    else:
                        needs[need] = True
                    break
        
        # Si analyse mentionnée sans spécification, inclure les deux
        if "analyse" in desc_lower and not (needs["prosody_analysis"] or needs["text_analysis"]):
            needs["prosody_analysis"] = True
            needs["text_analysis"] = True
            
        return needs

    def generate_steps(self, needs: Dict[str, bool]) -> List[Dict[str, str]]:
        """Génère les étapes du workflow basées sur les besoins détectés"""
        steps = []
        
        # Vérification de connexion temps réel (toujours en premier si nécessaire)
        if needs["realtime"]:
            steps.append({
                "service": "livekit",
                "endpoint": "health"
            })
        
        # Transcription (généralement en premier)
        if needs["transcription"]:
            steps.append({
                "service": "stt_service", 
                "endpoint": "transcribe"
            })
        
        # Analyses (après transcription)
        if needs["prosody_analysis"]:
            steps.append({
                "service": "audio_analysis_service",
                "endpoint": "analyze_prosody"
            })
            
        if needs["text_analysis"]:
            steps.append({
                "service": "audio_analysis_service", 
                "endpoint": "analyze_text"
            })
        
        # Synthèse vocale (généralement en dernier)
        if needs["synthesis"]:
            steps.append({
                "service": "tts_service",
                "endpoint": "synthesize"
            })
            
        return steps

    def determine_exercise_type(self, description: str, needs: Dict[str, bool]) -> str:
        """Détermine le type d'exercice basé sur la description"""
        desc_lower = description.lower()
        
        # Mots-clés pour chaque type
        conversation_keywords = ["conversation", "dialogue", "discussion", "chat", "interaction"]
        articulation_keywords = ["articulation", "pronunciation", "virelangue", "diction", "élocution"]
        speaking_keywords = ["présentation", "discours", "pitch", "parole", "oral"]
        breathing_keywords = ["respiration", "souffle", "breathing", "relaxation"]
        
        for keyword in conversation_keywords:
            if keyword in desc_lower:
                return "conversation"
                
        for keyword in articulation_keywords:
            if keyword in desc_lower:
                return "articulation"
                
        for keyword in speaking_keywords:
            if keyword in desc_lower:
                return "speaking"
                
        for keyword in breathing_keywords:
            if keyword in desc_lower:
                return "breathing"
        
        # Par défaut, type speaking si analyse de texte ou conversation si interaction
        if needs["text_analysis"] or "feedback" in desc_lower:
            return "speaking"
        elif needs["realtime"] or "temps réel" in desc_lower:
            return "conversation"
        else:
            return "speaking"

    def determine_difficulty(self, description: str, steps_count: int) -> str:
        """Détermine la difficulté basée sur la complexité"""
        desc_lower = description.lower()
        
        # Mots-clés explicites de difficulté
        if any(word in desc_lower for word in ["débutant", "facile", "simple", "basique"]):
            return "beginner"
        elif any(word in desc_lower for word in ["avancé", "complexe", "difficile", "expert"]):
            return "advanced"
        elif any(word in desc_lower for word in ["intermédiaire", "moyen"]):
            return "intermediate"
        
        # Basé sur la complexité (nombre d'étapes)
        if steps_count <= 2:
            return "beginner"
        elif steps_count <= 4:
            return "intermediate"
        else:
            return "advanced"

    def extract_focus_areas(self, description: str, exercise_type: str) -> List[str]:
        """Extrait les domaines de focus de la description"""
        desc_lower = description.lower()
        focus_areas = []
        
        # Mapping des mots-clés vers les domaines
        focus_mapping = {
            "confiance": ["confiance", "assurance", "stress", "anxiété"],
            "articulation": ["articulation", "pronunciation", "diction", "élocution"],
            "fluency": ["fluidité", "fluency", "aisance", "naturel"],
            "persuasion": ["persuasion", "convaincre", "argumenter", "influence"],
            "structure": ["structure", "organisation", "plan", "logique"],
            "engagement": ["engagement", "captiver", "intérêt", "audience"],
            "clarity": ["clarté", "précision", "compréhension", "limpide"],
            "prosody": ["prosodie", "intonation", "rythme", "mélodie"],
            "breathing": ["respiration", "souffle", "breathing", "pause"]
        }
        
        for focus, keywords in focus_mapping.items():
            if any(keyword in desc_lower for keyword in keywords):
                focus_areas.append(focus)
        
        # Focus par défaut selon le type d'exercice
        if not focus_areas:
            default_focus = {
                "conversation": ["confiance", "fluency"],
                "articulation": ["articulation", "clarity"],
                "speaking": ["structure", "persuasion"],
                "breathing": ["breathing", "confiance"]
            }
            focus_areas = default_focus.get(exercise_type, ["confiance"])
            
        return focus_areas

    def generate_gamification_config(self, exercise_type: str, difficulty: str) -> Dict[str, Any]:
        """Génère la configuration de gamification automatique"""
        base_xp = {"beginner": 80, "intermediate": 120, "advanced": 180}
        
        config = {
            "xp_rewards": {
                "completion": base_xp[difficulty],
                "perfect_score": base_xp[difficulty] + 50,
                "improvement": base_xp[difficulty] // 2,
                "streak_bonus": 25,
                "time_bonus": 20
            },
            "badges": self.gamification_templates["badges"].copy(),
            "levels": {
                "unlock_condition": f"completed_{exercise_type}_exercises >= 1",
                "progression_multiplier": 1.2 if difficulty == "advanced" else 1.0
            },
            "achievements": [
                {"name": "Premier Succès", "condition": "completion_rate >= 100"},
                {"name": "Perfectionniste", "condition": "average_score >= 90"},
                {"name": "Persévérant", "condition": "total_attempts >= 5"}
            ]
        }
        
        return config

    def generate_exercise_json(self, description: str) -> Dict[str, Any]:
        """Génère le JSON complet de l'exercice à partir de la description"""
        
        # Analyse de la description
        needs = self.analyze_description(description)
        steps = self.generate_steps(needs)
        exercise_id = self.generate_exercise_id(description)
        exercise_type = self.determine_exercise_type(description, needs)
        difficulty = self.determine_difficulty(description, len(steps))
        focus_areas = self.extract_focus_areas(description, exercise_type)
        
        # Génération du nom et description intelligents
        name = self.generate_smart_name(description, exercise_type)
        smart_description = self.generate_smart_description(description, steps)
        
        # Configuration de gamification
        gamification = self.generate_gamification_config(exercise_type, difficulty)
        
        # Structure JSON finale
        exercise_json = {
            exercise_id: {
                "name": name,
                "description": smart_description,
                "type": exercise_type,
                "difficulty": difficulty,
                "focus_areas": focus_areas,
                "duration": self.estimate_duration(steps, difficulty),
                "gamification": gamification,
                "realtime_enabled": needs["realtime"],
                "steps": steps,
                "metadata": {
                    "generated_at": datetime.now().isoformat(),
                    "generator_version": "1.0.0",
                    "original_description": description,
                    "auto_generated": True
                }
            }
        }
        
        return exercise_json

    def generate_smart_name(self, description: str, exercise_type: str) -> str:
        """Génère un nom intelligent pour l'exercice"""
        desc_lower = description.lower()
        
        # Noms spécialisés basés sur les mots-clés
        if "pitch" in desc_lower or "présentation" in desc_lower:
            return "Maîtrise du Pitch Elevator"
        elif "virelangue" in desc_lower:
            return "Défi des Virelangues"
        elif "conversation" in desc_lower:
            return "Conversation Interactive"
        elif "respiration" in desc_lower:
            return "Respiration et Relaxation"
        elif "prosodie" in desc_lower or "intonation" in desc_lower:
            return "Maîtrise de la Prosodie"
        elif "feedback" in desc_lower or "retour" in desc_lower:
            return "Exercice avec Retour Intelligent"
        else:
            type_names = {
                "conversation": "Conversation Guidée",
                "articulation": "Perfectionnement Articulatoire", 
                "speaking": "Expression Orale Avancée",
                "breathing": "Respiration et Confiance"
            }
            return type_names.get(exercise_type, "Exercice Vocal Personnalisé")

    def generate_smart_description(self, original_desc: str, steps: List[Dict]) -> str:
        """Génère une description professionnelle de l'exercice"""
        step_descriptions = {
            ("livekit", "health"): "vérification de la connexion temps réel",
            ("stt_service", "transcribe"): "transcription automatique de votre discours",
            ("audio_analysis_service", "analyze_prosody"): "analyse de votre intonation, rythme et pauses",
            ("audio_analysis_service", "analyze_text"): "évaluation de la clarté et du contenu textuel",
            ("tts_service", "synthesize"): "génération d'un retour vocal personnalisé"
        }
        
        workflow_desc = []
        for step in steps:
            key = (step["service"], step["endpoint"])
            if key in step_descriptions:
                workflow_desc.append(step_descriptions[key])
        
        if workflow_desc:
            workflow_text = ", puis ".join(workflow_desc)
            return f"Exercice vocal intelligent incluant : {workflow_text}. Cet exercice vous permet d'améliorer vos compétences oratoires grâce à une analyse complète et un feedback adaptatif."
        else:
            return "Exercice vocal personnalisé pour améliorer vos compétences en art oratoire."

    def estimate_duration(self, steps: List[Dict], difficulty: str) -> int:
        """Estime la durée de l'exercice en secondes"""
        base_duration = {"beginner": 180, "intermediate": 300, "advanced": 600}
        step_time = len(steps) * 30  # 30 secondes par étape supplémentaire
        return base_duration[difficulty] + step_time

    def validate_exercise(self, exercise_json: Dict[str, Any]) -> Dict[str, Any]:
        """Valide et optimise la configuration d'exercice générée"""
        exercise_id = list(exercise_json.keys())[0]
        exercise = exercise_json[exercise_id]
        
        validation_result = {
            "valid": True,
            "warnings": [],
            "optimizations": []
        }
        
        # Validation des étapes
        if not exercise["steps"]:
            validation_result["valid"] = False
            validation_result["warnings"].append("Aucune étape définie")
            
        # Vérification des services
        for step in exercise["steps"]:
            service = step["service"]
            endpoint = step["endpoint"]
            
            if service not in self.available_services:
                validation_result["warnings"].append(f"Service inconnu: {service}")
            elif endpoint not in self.available_services[service]["endpoints"]:
                validation_result["warnings"].append(f"Endpoint inconnu: {endpoint} pour {service}")
        
        # Optimisations suggérées
        step_services = [step["service"] for step in exercise["steps"]]
        
        if "stt_service" in step_services and "tts_service" in step_services:
            if "audio_analysis_service" not in step_services:
                validation_result["optimizations"].append("Ajouter une analyse audio entre transcription et synthèse")
        
        if exercise["realtime_enabled"] and "livekit" not in step_services:
            validation_result["optimizations"].append("Ajouter vérification LiveKit pour le temps réel")
            
        return validation_result

    def save_exercise(self, exercise_json: Dict[str, Any], output_path: str = "exercises_config.json"):
        """Sauvegarde l'exercice dans un fichier JSON"""
        try:
            # Charger le fichier existant ou créer un nouveau
            try:
                with open(output_path, 'r', encoding='utf-8') as f:
                    existing_exercises = json.load(f)
            except FileNotFoundError:
                existing_exercises = {}
            
            # Ajouter le nouvel exercice
            existing_exercises.update(exercise_json)
            
            # Sauvegarder
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(existing_exercises, f, indent=2, ensure_ascii=False)
                
            print(f"[+] Exercice sauvegarde dans {output_path}")
            
        except Exception as e:
            print(f"[!] Erreur lors de la sauvegarde: {e}")

    def generate_from_description(self, description: str, save_to_file: bool = True) -> Dict[str, Any]:
        """Fonction principale : génère un exercice complet à partir d'une description"""
        print(f"[*] Generation d'exercice a partir de: '{description}'")
        print("-" * 60)
        
        # Génération
        exercise_json = self.generate_exercise_json(description)
        exercise_id = list(exercise_json.keys())[0]
        exercise = exercise_json[exercise_id]
        
        # Validation
        validation = self.validate_exercise(exercise_json)
        
        # Affichage des résultats
        print(f"[+] Exercice genere: {exercise['name']}")
        print(f"[*] Type: {exercise['type']} | Difficulte: {exercise['difficulty']}")
        print(f"[*] Duree estimee: {exercise['duration']}s")
        print(f"[*] Focus: {', '.join(exercise['focus_areas'])}")
        print(f"[*] Etapes du workflow:")
        
        for i, step in enumerate(exercise['steps'], 1):
            print(f"   {i}. {step['service']} -> {step['endpoint']}")
            
        print(f"\n[*] Gamification:")
        print(f"   XP completion: {exercise['gamification']['xp_rewards']['completion']}")
        print(f"   Badges disponibles: {len(exercise['gamification']['badges'])}")
        
        if validation["warnings"]:
            print(f"\n[!] Avertissements: {validation['warnings']}")
        if validation["optimizations"]:
            print(f"\n[+] Optimisations suggerees: {validation['optimizations']}")
            
        # Sauvegarde
        if save_to_file:
            self.save_exercise(exercise_json)
            
        return exercise_json


def main():
    """Fonction principale du générateur"""
    if len(sys.argv) < 2:
        print("Usage: python exercise_generator.py \"Description de l'exercice\"")
        print("\nExemples:")
        print("python exercise_generator.py \"Je veux un exercice qui transcrit la voix et donne un feedback vocal\"")
        print("python exercise_generator.py \"Exercice de conversation temps réel avec analyse de prosodie\"")
        print("python exercise_generator.py \"Entraînement à la présentation avec analyse complète\"")
        return
    
    description = sys.argv[1]
    generator = EloquenceExerciseGenerator()
    
    try:
        exercise_json = generator.generate_from_description(description)
        
        # Affichage du JSON final
        print("\n" + "="*60)
        print("[*] JSON GENERE:")
        print("="*60)
        print(json.dumps(exercise_json, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"[!] Erreur lors de la generation: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()