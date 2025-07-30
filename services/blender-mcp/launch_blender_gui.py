#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lanceur Blender GUI pour visualisation interactive
Ouvre Blender avec l'interface graphique et la création chargée
"""

import sys
import os
import tempfile
import subprocess
from pathlib import Path

# Configuration encoding pour Windows
import io
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except:
        pass

# Importer les classes nécessaires
sys.path.append(os.path.dirname(__file__))
from eloquence_blender_tools import AnimationTemplates, PromptParser

def safe_print(text):
    """Impression sécurisée pour Windows"""
    try:
        print(text)
    except UnicodeEncodeError:
        safe_text = text.encode('ascii', 'replace').decode('ascii')
        print(safe_text)

def launch_blender_gui(prompt):
    """Lance Blender GUI avec la création basée sur le prompt"""
    
    safe_print("=" * 80)
    safe_print("LANCEUR BLENDER GUI - VISUALISATION INTERACTIVE")
    safe_print("=" * 80)
    safe_print(f"Prompt: {prompt}")
    safe_print("")
    
    # Créer le répertoire temporaire
    temp_dir = Path(tempfile.gettempdir()) / "eloquence_blender_gui"
    temp_dir.mkdir(exist_ok=True)
    
    try:
        # Parser le prompt pour déterminer le type d'animation
        animation_params = PromptParser.parse_animation_prompt(prompt)
        safe_print(f"[OK] Type detecte: {animation_params['type']}")
        safe_print(f"[INFO] Parametres: {animation_params['params']}")
        safe_print("")
        
        # Générer le script Blender approprié
        params = animation_params.get("params", {})
        if animation_params["type"] == "roulette":
            script_content = AnimationTemplates.create_spinning_roulette(
                segments=params.get("segments", 6),
                colors=params.get("colors")
            )
            description = f"ROULETTE CASINO - {params.get('segments', 6)} segments"
        elif animation_params["type"] == "virelangue_roulette":
            script_content = AnimationTemplates.create_virelangue_roulette(
                segments=params.get("segments", 8)
            )
            description = f"ROULETTE VIRELANGUES - {params.get('segments', 8)} segments avec couleurs Flutter"
        elif animation_params["type"] == "bouncing_cube":
            script_content = AnimationTemplates.create_bouncing_cube(
                bounces=params.get("bounces", 3)
            )
            description = f"CUBE REBONDISSANT - {params.get('bounces', 3)} rebonds"
        elif animation_params["type"] == "dragon_fire":
            script_content = AnimationTemplates.create_dragon_fire_breathing(
                scale=params.get("scale", 1.0),
                fire_intensity=params.get("fire_intensity", 10.0)
            )
            description = f"DRAGON CRACHEUR DE FLAMMES - Échelle: {params.get('scale', 1.0)}, Intensité: {params.get('fire_intensity', 10.0)}"
        elif animation_params["type"] == "logo_text":
            script_content = AnimationTemplates.create_rotating_logo_text(
                text=params.get("text", "ELOQUENCE")
            )
            description = f"LOGO 3D - Texte: {params.get('text', 'ELOQUENCE')}"
        else:
            # Par défaut, roulette simple
            script_content = AnimationTemplates.create_spinning_roulette(segments=6)
            description = "ROULETTE SIMPLE - 6 segments"
        
        safe_print(f"[OK] Script genere ({len(script_content)} caracteres)")
        safe_print(f"[INFO] {description}")
        safe_print("")
        
        # Sauvegarder le script
        script_path = temp_dir / "interactive_script.py"
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        safe_print(f"[OK] Script sauve: {script_path}")
        
        # Lancer Blender GUI
        blender_path = r"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
        
        safe_print(f"[INFO] Lancement Blender GUI: {blender_path}")
        safe_print("[INFO] Blender va s'ouvrir avec votre creation...")
        safe_print("")
        
        # Lancer Blender en mode GUI avec le script
        subprocess.Popen([
            blender_path, "--python", str(script_path)
        ], creationflags=subprocess.CREATE_NEW_CONSOLE if hasattr(subprocess, 'CREATE_NEW_CONSOLE') else 0)
        
        safe_print("🎉 BLENDER GUI LANCE AVEC SUCCES!")
        safe_print("")
        safe_print("📋 CONTROLES BLENDER:")
        safe_print("  🖱️  Bouton du milieu + glisser = Rotation de la vue")
        safe_print("  🔍 Molette = Zoom/Dezoom")
        safe_print("  ⏯️  ESPACE = Lancer/Arreter l'animation")
        safe_print("  🎥 F12 = Rendre une image haute qualite")
        safe_print("  🎬 CTRL+F12 = Rendre une animation complete")
        safe_print("  📁 CTRL+S = Sauvegarder le fichier .blend")
        safe_print("")
        safe_print("✨ Votre creation est maintenant visible en 3D interactif!")
        
        return True
        
    except Exception as e:
        safe_print(f"[ERREUR] {e}")
        return False

def main():
    if len(sys.argv) < 2:
        safe_print("Usage: python launch_blender_gui.py \"votre prompt\"")
        safe_print("")
        safe_print("Exemples:")
        safe_print("  python launch_blender_gui.py \"Roulette des virelangues coloree\"")
        safe_print("  python launch_blender_gui.py \"Cube rebondissant avec 5 rebonds\"")
        safe_print("  python launch_blender_gui.py \"Logo ELOQUENCE en 3D\"")
        return
    
    prompt = " ".join(sys.argv[1:])
    launch_blender_gui(prompt)

if __name__ == "__main__":
    main()