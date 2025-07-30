#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Outil de prévisualisation simple des animations Blender MCP
Compatible Windows - sans emojis Unicode
"""

import sys
from pathlib import Path

# Ajouter le dossier parent au PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent))

from eloquence_blender_tools import AnimationTemplates, PromptParser


def preview_prompt(prompt: str):
    """Prévisualise une animation à partir d'un prompt"""
    print("=" * 80)
    print(f"PREVISUALISATION : {prompt}")
    print("=" * 80)
    
    # 1. Analyser le prompt
    parser = PromptParser()
    try:
        result = parser.parse_prompt(prompt)
        print(f"[OK] Type detecte : {result['type']}")
        print(f"[INFO] Parametres : {result['params']}")
        print()
        
        # 2. Générer le code correspondant
        templates = AnimationTemplates()
        params = result.get("params", {})
        code = None
        
        if result["type"] == "virelangue_roulette":
            code = templates.create_virelangue_roulette(
                segments=params.get("segments", 8)
            )
            print("ROULETTE DES VIRELANGUES ELOQUENCE")
            print(f"   - {params.get('segments', 8)} segments")
            print("   - Couleurs Flutter integrees")
            print("   - Virelangues francais")
            print("   - Animation 180 frames")
            
        elif result["type"] == "roulette":
            code = templates.create_spinning_roulette(
                segments=params.get("segments", 6),
                colors=params.get("colors")
            )
            print("ROULETTE CASINO")
            print(f"   - {params.get('segments', 6)} segments")
            if params.get('colors'):
                print(f"   - Couleurs : {params['colors']}")
            print("   - Animation 120 frames")
            
        elif result["type"] == "bouncing_cube":
            code = templates.create_bouncing_cube(
                bounces=params.get("bounces", 3)
            )
            print("CUBE REBONDISSANT")
            print(f"   - {params.get('bounces', 3)} rebonds")
            print("   - Couleur orange par defaut")
            print("   - Physique realiste")
            
        elif result["type"] == "logo_text":
            code = templates.create_rotating_logo_text(
                text=params.get("text", "ELOQUENCE")
            )
            print("LOGO TEXTE 3D")
            print(f"   - Texte : '{params.get('text', 'ELOQUENCE')}'")
            print("   - Materiau dore")
            print("   - Animation apparition + rotation")
            
        else:
            print("[ERREUR] Type d'animation non reconnu")
            return
        
        print(f"Code genere : {len(code)} caracteres")
        print()
        
        # 3. Afficher un extrait du code
        print("=" * 80)
        print("EXTRAIT DU CODE PYTHON BLENDER GENERE")
        print("=" * 80)
        lines = code.split('\n')
        for i, line in enumerate(lines[:20], 1):
            print(f"{i:3d} | {line}")
        
        if len(lines) > 20:
            print("...")
            print(f"    | Total : {len(lines)} lignes")
        
        print("=" * 80)
        
        return {
            "type": result["type"],
            "params": params,
            "code_length": len(code)
        }
        
    except Exception as e:
        print(f"[ERREUR] Erreur lors de la previsualisation : {e}")
        return None


def main():
    """Fonction principale"""
    if len(sys.argv) > 1:
        # Prompt direct en argument
        prompt = ' '.join(sys.argv[1:])
        preview_prompt(prompt)
    else:
        # Mode interactif simple
        print("OUTIL DE PREVISUALISATION BLENDER MCP ELOQUENCE")
        print("=" * 60)
        print()
        print("Exemples de prompts :")
        print('  "Roulette des virelangues magiques"')
        print('  "Cube orange qui rebondit 3 fois"')
        print('  "Logo ELOQUENCE dore qui tourne"')
        print()
        
        while True:
            try:
                prompt = input("Prompt > ").strip()
                if not prompt or prompt.lower() in ['exit', 'quit', 'q']:
                    break
                print()
                preview_prompt(prompt)
                print()
            except (KeyboardInterrupt, EOFError):
                break
        
        print("Au revoir !")


if __name__ == "__main__":
    main()