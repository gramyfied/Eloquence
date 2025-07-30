#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Prévisualisation visuelle Blender MCP Eloquence
Génère des images de rendu pour voir le résultat graphique avant validation
"""

import sys
import os
import tempfile
import subprocess
import webbrowser
from pathlib import Path
from eloquence_blender_tools import AnimationTemplates, PromptParser

class VisualPreview:
    def __init__(self):
        self.temp_dir = Path(tempfile.gettempdir()) / "eloquence_blender_preview"
        self.temp_dir.mkdir(exist_ok=True)
        
    def generate_visual_preview(self, prompt):
        """Génère une prévisualisation visuelle avec rendu d'image"""
        try:
            print("=" * 80)
            print("PREVISUALISATION VISUELLE BLENDER MCP ELOQUENCE")
            print("=" * 80)
            print(f"Prompt: {prompt}")
            print()
            
            # Parser le prompt pour déterminer le type d'animation
            animation_params = PromptParser.parse_animation_prompt(prompt)
            print(f"🎯 Type détecté: {animation_params['type']}")
            print(f"⚙️ Paramètres: {animation_params['params']}")
            print()
            
            # Générer le script Blender approprié
            params = animation_params.get("params", {})
            if animation_params["type"] == "roulette":
                script_content = AnimationTemplates.create_spinning_roulette(
                    segments=params.get("segments", 6),
                    colors=params.get("colors")
                )
                animation_description = f"ROULETTE CASINO\n   - {params.get('segments', 6)} segments\n   - Animation 120 frames"
            elif animation_params["type"] == "bouncing_cube":
                script_content = AnimationTemplates.create_bouncing_cube(
                    bounces=params.get("bounces", 3)
                )
                animation_description = f"CUBE REBONDISSANT\n   - {params.get('bounces', 3)} rebonds\n   - Animation physique"
            elif animation_params["type"] == "virelangue_roulette":
                script_content = AnimationTemplates.create_virelangue_roulette(
                    segments=params.get("segments", 8)
                )
                animation_description = f"ROULETTE VIRELANGUES ELOQUENCE\n   - {params.get('segments', 8)} segments\n   - Couleurs Flutter\n   - Virelangues français"
            elif animation_params["type"] == "logo_text":
                script_content = AnimationTemplates.create_rotating_logo_text(
                    text=params.get("text", "ELOQUENCE")
                )
                animation_description = f"LOGO TEXTE 3D\n   - Texte: {params.get('text', 'ELOQUENCE')}\n   - Animation d'apparition et rotation"
            else:
                print(f"❌ Type d'animation non reconnu: {animation_params['type']}")
                return False
                
            print(f"✅ Script généré ({len(script_content)} caractères)")
            print(f"📋 {animation_description}")
            
            # Ajouter le code de rendu d'image au script
            render_script = self._add_render_code(script_content)
            
            # Sauvegarder le script
            script_path = self.temp_dir / "preview_script.py"
            with open(script_path, 'w', encoding='utf-8') as f:
                f.write(render_script)
            
            print(f"📁 Script sauvé: {script_path}")
            
            # Tenter le rendu avec Blender si disponible
            image_path = self._render_with_blender(script_path)
            
            result_data = {
                'animation_type': animation_params['type'],
                'parameters': animation_params['params'],
                'script_length': len(script_content),
                'description': animation_description
            }
            
            if image_path and image_path.exists():
                print(f"🖼️ Image générée: {image_path}")
                self._create_html_preview(image_path, prompt, result_data)
                return True
            else:
                print("⚠️ Rendu Blender non disponible, génération HTML uniquement")
                self._create_html_preview(None, prompt, result_data)
                return True
                
        except Exception as e:
            print(f"❌ Erreur: {e}")
            return False
    
    def _add_render_code(self, script_content):
        """Ajoute le code de rendu d'image au script Blender"""
        render_code = f"""

# Configuration de rendu pour prévisualisation
import bpy

# Configurer la caméra
bpy.ops.object.camera_add(location=(7, -7, 5))
camera = bpy.context.active_object
camera.rotation_euler = (1.1, 0, 0.785)

# Configurer l'éclairage
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
sun = bpy.context.active_object
sun.data.energy = 3

# Configurer le rendu
scene = bpy.context.scene
scene.camera = camera
scene.render.resolution_x = 800
scene.render.resolution_y = 600
scene.render.filepath = r"{self.temp_dir / 'preview.png'}"
scene.render.image_settings.file_format = 'PNG'

# Effectuer le rendu
bpy.ops.render.render(write_still=True)
print("Rendu terminé!")
"""
        return script_content + render_code
    
    def _render_with_blender(self, script_path):
        """Tente d'exécuter le rendu avec Blender"""
        blender_commands = [
            "blender",
            "blender.exe", 
            r"C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
            r"C:\Program Files\Blender Foundation\Blender 3.6\blender.exe"
        ]
        
        for cmd in blender_commands:
            try:
                image_path = self.temp_dir / "preview.png"
                if image_path.exists():
                    image_path.unlink()
                
                subprocess.run([
                    cmd, "--background", "--python", str(script_path)
                ], timeout=30, capture_output=True)
                
                if image_path.exists():
                    print(f"✅ Rendu réussi avec: {cmd}")
                    return image_path
                    
            except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.SubprocessError):
                continue
        
        return None
    
    def _create_html_preview(self, image_path, prompt, result):
        """Crée une page HTML de prévisualisation"""
        html_content = f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prévisualisation Eloquence - {prompt}</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }}
        
        .container {{
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }}
        
        .header {{
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(45deg, #00BCD4, #9C27B0);
            color: white;
            border-radius: 10px;
        }}
        
        .preview-section {{
            margin: 20px 0;
            padding: 20px;
            border: 2px solid #00BCD4;
            border-radius: 10px;
            background: #f8f9fa;
        }}
        
        .prompt-display {{
            font-size: 1.2em;
            font-weight: bold;
            color: #9C27B0;
            margin-bottom: 15px;
        }}
        
        .image-container {{
            text-align: center;
            margin: 20px 0;
        }}
        
        .preview-image {{
            max-width: 100%;
            border: 3px solid #00BCD4;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }}
        
        .no-image {{
            padding: 40px;
            text-align: center;
            background: #f0f0f0;
            border-radius: 10px;
            color: #666;
        }}
        
        .details {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }}
        
        .detail-card {{
            padding: 15px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #00BCD4;
        }}
        
        .actions {{
            text-align: center;
            margin-top: 30px;
        }}
        
        .btn {{
            display: inline-block;
            padding: 12px 24px;
            margin: 0 10px;
            background: #00BCD4;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s;
            cursor: pointer;
            border: none;
        }}
        
        .btn:hover {{
            background: #0097A7;
            transform: translateY(-2px);
        }}
        
        .btn-secondary {{
            background: #9C27B0;
        }}
        
        .btn-secondary:hover {{
            background: #7B1FA2;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎨 Prévisualisation Eloquence</h1>
            <p>Animation 3D générée par IA</p>
        </div>
        
        <div class="preview-section">
            <div class="prompt-display">📝 Prompt: "{prompt}"</div>
            
            <div class="image-container">
                {"<img src='preview.png' alt='Prévisualisation' class='preview-image'>" if image_path and image_path.exists() else "<div class='no-image'>🔄 Rendu en cours...<br>Image sera disponible après installation de Blender<br><br>📋 Informations disponibles :<br>" + result.get('description', '').replace('\\n', '<br>') + "</div>"}
            </div>
            
            <div class="details">
                <div class="detail-card">
                    <h3>🎯 Type détecté</h3>
                    <p>{result.get('animation_type', 'N/A')}</p>
                </div>
                
                <div class="detail-card">
                    <h3>⚙️ Paramètres</h3>
                    <p>{str(result.get('parameters', {}))}</p>
                </div>
                
                <div class="detail-card">
                    <h3>📊 Script généré</h3>
                    <p>{result.get('script_length', 0)} caractères</p>
                </div>
                
                <div class="detail-card">
                    <h3>🎬 Status</h3>
                    <p>{"✅ Image rendue" if image_path and image_path.exists() else "⚠️ Rendu nécessite Blender"}</p>
                </div>
            </div>
        </div>
        
        <div class="actions">
            <button onclick="location.reload()" class="btn">🔄 Actualiser</button>
            <button onclick="alert('Pour intégrer dans RooCode :\\n\\n1. Ouvrez VS Code\\n2. Tapez votre prompt dans RooCode\\n3. Le serveur MCP génèrera l\\'animation')" class="btn btn-secondary">✅ Intégrer dans RooCode</button>
        </div>
    </div>
    
    <script>
        // Animation d'apparition
        document.addEventListener('DOMContentLoaded', function() {{
            document.querySelector('.container').style.opacity = '0';
            document.querySelector('.container').style.transform = 'translateY(20px)';
            setTimeout(() => {{
                document.querySelector('.container').style.transition = 'all 0.5s';
                document.querySelector('.container').style.opacity = '1';
                document.querySelector('.container').style.transform = 'translateY(0)';
            }}, 100);
        }});
    </script>
</body>
</html>
        """
        
        html_path = self.temp_dir / "preview.html"
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        # Copier l'image si elle existe
        if image_path and image_path.exists():
            import shutil
            shutil.copy2(image_path, self.temp_dir / "preview.png")
        
        print(f"🌐 Prévisualisation HTML: {html_path}")
        
        # Ouvrir dans le navigateur
        try:
            webbrowser.open(f"file:///{html_path}")
            print("🚀 Ouverture dans le navigateur...")
        except:
            print("⚠️ Impossible d'ouvrir automatiquement le navigateur")
            print(f"Ouvrez manuellement: file:///{html_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python preview_visual.py \"votre prompt\"")
        print("Exemple: python preview_visual.py \"Roulette des virelangues magiques\"")
        return
    
    prompt = " ".join(sys.argv[1:])
    preview = VisualPreview()
    preview.generate_visual_preview(prompt)

if __name__ == "__main__":
    main()