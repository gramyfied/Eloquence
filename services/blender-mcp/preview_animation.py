#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Outil de prévisualisation des animations Blender MCP avant intégration
Permet de voir le code généré et optionnellement l'ouvrir dans Blender
"""

import sys
import os
import subprocess
import json
from pathlib import Path
from datetime import datetime

# Ajouter le dossier parent au PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent))

from eloquence_blender_tools import AnimationTemplates, PromptParser


def preview_prompt(prompt: str, show_code: bool = True, open_blender: bool = False):
    """
    Prévisualise une animation à partir d'un prompt
    
    Args:
        prompt: Le prompt en langage naturel
        show_code: Afficher le code Python Blender généré
        open_blender: Ouvrir automatiquement dans Blender
    """
    print("=" * 80)
    print(f"PREVISUALISATION : {prompt}")
    print("=" * 80)
    
    # 1. Analyser le prompt
    parser = PromptParser()
    try:
        result = parser.parse_prompt(prompt)
        print(f"✅ Type détecté : {result['type']}")
        print(f"📋 Paramètres : {result['params']}")
        print()
        
        # 2. Générer le code correspondant
        templates = AnimationTemplates()
        params = result.get("params", {})
        code = None
        
        if result["type"] == "virelangue_roulette":
            code = templates.create_virelangue_roulette(
                segments=params.get("segments", 8)
            )
            print("🎰 ROULETTE DES VIRELANGUES ELOQUENCE")
            print(f"   • {params.get('segments', 8)} segments")
            print("   • Couleurs Flutter intégrées")
            print("   • Virelangues français")
            print("   • Animation 180 frames")
            
        elif result["type"] == "roulette":
            code = templates.create_spinning_roulette(
                segments=params.get("segments", 6),
                colors=params.get("colors")
            )
            print("🎰 ROULETTE CASINO")
            print(f"   • {params.get('segments', 6)} segments")
            if params.get('colors'):
                print(f"   • Couleurs : {params['colors']}")
            print("   • Animation 120 frames")
            
        elif result["type"] == "bouncing_cube":
            code = templates.create_bouncing_cube(
                bounces=params.get("bounces", 3)
            )
            print("🧊 CUBE REBONDISSANT")
            print(f"   • {params.get('bounces', 3)} rebonds")
            print("   • Couleur orange par défaut")
            print("   • Physique réaliste")
            
        elif result["type"] == "logo_text":
            code = templates.create_rotating_logo_text(
                text=params.get("text", "ELOQUENCE")
            )
            print("✨ LOGO TEXTE 3D")
            print(f"   • Texte : '{params.get('text', 'ELOQUENCE')}'")
            print("   • Matériau doré")
            print("   • Animation apparition + rotation")
            
        else:
            print("❌ Type d'animation non reconnu")
            return
        
        print(f"📏 Code généré : {len(code)} caractères")
        print()
        
        # 3. Afficher le code si demandé
        if show_code:
            print("=" * 80)
            print("🐍 CODE PYTHON BLENDER GÉNÉRÉ")
            print("=" * 80)
            print(code)
            print("=" * 80)
            print()
        
        # 4. Sauvegarder dans un fichier temporaire
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"preview_{result['type']}_{timestamp}.py"
        filepath = Path(__file__).parent / "temp" / filename
        
        # Créer le dossier temp s'il n'existe pas
        filepath.parent.mkdir(exist_ok=True)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(code)
        
        print(f"💾 Code sauvegardé : {filepath}")
        
        # 5. Ouvrir dans Blender si demandé
        if open_blender:
            try:
                blender_cmd = ["blender", "--python", str(filepath)]
                print(f"🚀 Ouverture dans Blender...")
                subprocess.Popen(blender_cmd)
                print("✅ Blender lancé avec le script !")
            except FileNotFoundError:
                print("❌ Blender non trouvé. Installez Blender ou ajoutez-le au PATH")
                print(f"   Vous pouvez exécuter manuellement : blender --python {filepath}")
        
        return {
            "type": result["type"],
            "params": params,
            "code_length": len(code),
            "filepath": str(filepath)
        }
        
    except Exception as e:
        print(f"❌ Erreur lors de la prévisualisation : {e}")
        return None


def interactive_preview():
    """Mode interactif pour tester plusieurs prompts"""
    print("🎨 OUTIL DE PRÉVISUALISATION BLENDER MCP ELOQUENCE")
    print("=" * 60)
    print()
    print("Entrez vos prompts pour voir les animations générées.")
    print("Commandes spéciales :")
    print("  'exit' ou 'quit' - Quitter")
    print("  'blender' - Ouvrir la dernière animation dans Blender")
    print("  'examples' - Voir des exemples de prompts")
    print()
    
    last_result = None
    
    while True:
        try:
            prompt = input("🎯 Prompt > ").strip()
            
            if prompt.lower() in ['exit', 'quit', 'q']:
                print("👋 Au revoir !")
                break
                
            elif prompt.lower() == 'blender':
                if last_result and last_result.get('filepath'):
                    try:
                        subprocess.Popen(["blender", "--python", last_result['filepath']])
                        print("🚀 Blender lancé !")
                    except FileNotFoundError:
                        print("❌ Blender non trouvé")
                else:
                    print("❌ Aucune animation à ouvrir")
                continue
                
            elif prompt.lower() == 'examples':
                print_examples()
                continue
                
            elif not prompt:
                continue
            
            # Prévisualiser le prompt
            print()
            last_result = preview_prompt(prompt, show_code=False)
            print()
            
        except KeyboardInterrupt:
            print("\n👋 Au revoir !")
            break
        except EOFError:
            break


def print_examples():
    """Affiche des exemples de prompts"""
    print("💡 EXEMPLES DE PROMPTS")
    print("=" * 40)
    print()
    print("🎰 VIRELANGUES ELOQUENCE :")
    print('   "Roulette des virelangues magiques"')
    print('   "Tongue twister wheel Eloquence"')
    print('   "Virelangue roulette avec 6 segments"')
    print()
    print("🎰 ROULETTES CASINO :")
    print('   "Roulette casino 8 segments"')
    print('   "Roue rouge et noire 6 parts"')
    print('   "Wheel coloré 12 segments"')
    print()
    print("🧊 CUBES REBONDISSANTS :")
    print('   "Cube orange qui rebondit 3 fois"')
    print('   "Box rouge qui saute 5 fois"')
    print('   "Cube rebondissant bleu"')
    print()
    print("✨ LOGOS 3D :")
    print('   "Logo ELOQUENCE doré qui tourne"')
    print('   "Texte \'BONJOUR\' qui apparaît"')
    print('   "Logo métallique qui brille"')
    print()


def batch_preview(prompts_file: str):
    """Prévisualise plusieurs prompts depuis un fichier JSON"""
    try:
        with open(prompts_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        prompts = data.get('prompts', [])
        print(f"📋 Prévisualisation de {len(prompts)} prompts...")
        print()
        
        results = []
        for i, prompt in enumerate(prompts, 1):
            print(f"[{i}/{len(prompts)}]")
            result = preview_prompt(prompt, show_code=False)
            if result:
                results.append({"prompt": prompt, "result": result})
            print("-" * 60)
        
        # Sauvegarder le rapport
        report_file = Path(prompts_file).with_suffix('.report.json')
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        print(f"📊 Rapport sauvegardé : {report_file}")
        
    except Exception as e:
        print(f"❌ Erreur lors du traitement batch : {e}")


def main():
    """Fonction principale"""
    if len(sys.argv) > 1:
        if sys.argv[1] == '--interactive':
            interactive_preview()
        elif sys.argv[1] == '--batch' and len(sys.argv) > 2:
            batch_preview(sys.argv[2])
        else:
            # Prompt direct en argument
            prompt = ' '.join(sys.argv[1:])
            preview_prompt(prompt, show_code=True, open_blender=False)
    else:
        # Mode interactif par défaut
        interactive_preview()


if __name__ == "__main__":
    main()