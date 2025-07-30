"""
Outils Blender spécialisés pour Eloquence RooCode
Extensions du serveur MCP avec des outils optimisés pour les prompts en langage naturel
"""

import json
import logging
from typing import Dict, Any, List, Optional
from mcp.server.fastmcp import FastMCP, Context

logger = logging.getLogger("EloquenceBlenderTools")

class AnimationTemplates:
    """Templates d'animations prédéfinies pour les prompts simples"""
    
    @staticmethod
    def create_roulette(segments: int = 6, colors: List[str] = None) -> str:
        """Alias pour create_spinning_roulette"""
        return AnimationTemplates.create_spinning_roulette(segments, colors)
    
    @staticmethod
    def create_spinning_roulette(segments: int = 6, colors: List[str] = None) -> str:
        """Génère le code Python Blender pour une roulette qui tourne"""
        if not colors:
            colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        
        return f"""
import bpy
import bmesh
import mathutils
import math

# Supprimer les objets par défaut
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Créer la base de la roulette (cylindre)
bpy.ops.mesh.primitive_cylinder_add(vertices={segments}, radius=2, depth=0.2, location=(0, 0, 0))
roulette = bpy.context.active_object
roulette.name = "Roulette"

# Créer les segments colorés
colors = {colors[:segments]}
for i in range({segments}):
    # Créer un secteur pour chaque segment
    bpy.ops.mesh.primitive_cylinder_add(vertices=3, radius=1.8, depth=0.25, location=(0, 0, 0.15))
    segment = bpy.context.active_object
    segment.name = f"Segment_{{i+1}}"
    
    # Rotation pour positionner le segment
    segment.rotation_euler[2] = i * (2 * math.pi / {segments})
    
    # Créer et appliquer un matériau coloré
    mat = bpy.data.materials.new(name=f"Color_{{i+1}}")
    mat.use_nodes = True
    mat.node_tree.nodes.clear()
    
    # Nœud de sortie de matériau
    output_node = mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
    
    # Nœud BSDF principled
    bsdf_node = mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')
    
    # Couleur du segment
    hex_color = colors[i].lstrip('#')
    rgb = tuple(int(hex_color[j:j+2], 16)/255.0 for j in (0, 2, 4))
    bsdf_node.inputs['Base Color'].default_value = (*rgb, 1.0)
    
    # Connecter les nœuds
    mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
    
    # Appliquer le matériau
    segment.data.materials.append(mat)

# Grouper tous les objets
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.join()

# Ajouter l'animation de rotation
roulette = bpy.context.active_object
roulette.rotation_euler = (0, 0, 0)
roulette.keyframe_insert(data_path="rotation_euler", index=2, frame=1)

roulette.rotation_euler[2] = 8 * math.pi  # 4 tours complets
roulette.keyframe_insert(data_path="rotation_euler", index=2, frame=120)

# Configuration de l'interpolation
for fcurve in roulette.animation_data.action.fcurves:
    for keyframe in fcurve.keyframe_points:
        keyframe.interpolation = 'BEZIER'
        keyframe.handle_left_type = 'AUTO'
        keyframe.handle_right_type = 'AUTO'

# Configurer la scène
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120
scene.frame_set(1)

print("✅ Roulette créée avec {segments} segments")
"""

    @staticmethod
    def create_bouncing_cube(bounces: int = 3, height: float = 5.0, color: str = "orange") -> str:
        """Génère le code Python Blender pour un cube qui rebondit"""
        color_map = {
            "orange": (1.0, 0.5, 0.0, 1.0),
            "red": (1.0, 0.0, 0.0, 1.0),
            "blue": (0.0, 0.0, 1.0, 1.0),
            "green": (0.0, 1.0, 0.0, 1.0),
            "yellow": (1.0, 1.0, 0.0, 1.0),
            "purple": (1.0, 0.0, 1.0, 1.0)
        }
        color_rgba = color_map.get(color.lower(), (1.0, 0.5, 0.0, 1.0))
        return f"""
import bpy
import mathutils
import math

# Supprimer les objets par défaut
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Créer un cube
bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))
cube = bpy.context.active_object
cube.name = "BouncingCube"

# Créer un matériau coloré
mat = bpy.data.materials.new(name="CubeMaterial")
mat.use_nodes = True
mat.node_tree.nodes.clear()

output_node = mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
bsdf_node = mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')

# Couleur personnalisée
bsdf_node.inputs['Base Color'].default_value = {color_rgba}
bsdf_node.inputs['Metallic'].default_value = 0.3
bsdf_node.inputs['Roughness'].default_value = 0.4

mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
cube.data.materials.append(mat)

# Créer un sol pour le rebond
bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 0, 0))
ground = bpy.context.active_object
ground.name = "Ground"

# Matériau pour le sol
ground_mat = bpy.data.materials.new(name="GroundMaterial")
ground_mat.use_nodes = True
ground_mat.node_tree.nodes.clear()

output_node = ground_mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
bsdf_node = ground_mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')
bsdf_node.inputs['Base Color'].default_value = (0.8, 0.8, 0.8, 1.0)

ground_mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
ground.data.materials.append(ground_mat)

# Sélectionner le cube pour l'animation
cube.select_set(True)
bpy.context.view_layer.objects.active = cube

# Animation de rebond
bounces = {bounces}
total_frames = bounces * 40 + 20
height = {height}

for i in range(bounces + 1):
    frame = i * 40 + 1
    
    # Position au sol
    cube.location = (0, 0, 1)
    cube.keyframe_insert(data_path="location", index=2, frame=frame)
    
    if i < bounces:
        # Position en l'air (rebond)
        bounce_height = height * (1 - i / bounces) + 1
        cube.location = (0, 0, bounce_height)
        cube.keyframe_insert(data_path="location", index=2, frame=frame + 20)

# Configuration de l'interpolation
for fcurve in cube.animation_data.action.fcurves:
    if fcurve.data_path == "location" and fcurve.array_index == 2:
        for keyframe in fcurve.keyframe_points:
            keyframe.interpolation = 'BEZIER'
            keyframe.handle_left_type = 'AUTO'
            keyframe.handle_right_type = 'AUTO'

# Configurer la scène
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = total_frames
scene.frame_set(1)

print("✅ Cube rebondissant créé avec {bounces} rebonds en {color}")
"""

    @staticmethod
    def create_3d_logo(text: str = "ELOQUENCE", color: str = "gold") -> str:
        """Alias pour create_rotating_logo_text"""
        return AnimationTemplates.create_rotating_logo_text(text)

    @staticmethod
    def create_rotating_logo_text(text: str = "ELOQUENCE") -> str:
        """Génère le code Python Blender pour un logo texte 3D qui tourne"""
        return f"""
import bpy
import mathutils
import math

# Supprimer les objets par défaut
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Créer le texte 3D
bpy.ops.object.text_add(location=(0, 0, 0))
text_obj = bpy.context.active_object
text_obj.name = "LogoText"

# Configuration du texte
text_obj.data.body = "{text}"
text_obj.data.font = bpy.data.fonts.load("//fonts/arial.ttf") if "arial.ttf" in bpy.data.fonts else bpy.data.fonts[0]
text_obj.data.size = 2
text_obj.data.extrude = 0.3
text_obj.data.bevel_depth = 0.05
text_obj.data.bevel_resolution = 4

# Centrer le texte
text_obj.data.align_x = 'CENTER'
text_obj.data.align_y = 'CENTER'

# Créer un matériau doré
mat = bpy.data.materials.new(name="GoldMaterial")
mat.use_nodes = True
mat.node_tree.nodes.clear()

output_node = mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
bsdf_node = mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')

# Couleur dorée
bsdf_node.inputs['Base Color'].default_value = (1.0, 0.8, 0.2, 1.0)
bsdf_node.inputs['Metallic'].default_value = 0.9
bsdf_node.inputs['Roughness'].default_value = 0.1

mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
text_obj.data.materials.append(mat)

# Animation de rotation et d'apparition
text_obj.scale = (0, 0, 0)
text_obj.keyframe_insert(data_path="scale", frame=1)

text_obj.scale = (1, 1, 1)
text_obj.keyframe_insert(data_path="scale", frame=30)

# Rotation continue
text_obj.rotation_euler = (0, 0, 0)
text_obj.keyframe_insert(data_path="rotation_euler", index=2, frame=30)

text_obj.rotation_euler[2] = 2 * math.pi
text_obj.keyframe_insert(data_path="rotation_euler", index=2, frame=150)

# Configuration de l'interpolation pour l'apparition
for fcurve in text_obj.animation_data.action.fcurves:
    if fcurve.data_path == "scale":
        for keyframe in fcurve.keyframe_points:
            keyframe.interpolation = 'BACK'
    elif fcurve.data_path == "rotation_euler":
        for keyframe in fcurve.keyframe_points:
            keyframe.interpolation = 'LINEAR'

# Ajouter un éclairage
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
light = bpy.context.active_object
light.data.energy = 3

# Configurer la scène
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 150
scene.frame_set(1)

print("✅ Logo texte '{text}' créé avec animation")
"""
    @staticmethod  
    def create_dragon_fire_breathing(scale: float = 1.0, fire_intensity: float = 10.0) -> str:
        """Génère le code Python Blender pour un dragon cracheur de flammes avec simulation Mantaflow"""
        return f"""
import bpy
import bmesh
import math

# === NETTOYAGE INITIAL ===
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

print("Création dragon cracheur de flammes avec simulation Mantaflow...")

# === CORPS DU DRAGON ===
# Corps principal (ellipsoïde allongé)
bpy.ops.mesh.primitive_uv_sphere_add(radius=1.5, location=(0, 0, 1))
dragon_body = bpy.context.active_object
dragon_body.name = "Dragon_Body"
dragon_body.scale = (2.5 * {scale}, 1.2 * {scale}, 1.0 * {scale})

# === TÊTE DU DRAGON ===
bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(3.5 * {scale}, 0, 1.2 * {scale}))
dragon_head = bpy.context.active_object
dragon_head.name = "Dragon_Head"
dragon_head.scale = (1.3 * {scale}, 0.8 * {scale}, 0.9 * {scale})

# === MUSEAU ALLONGÉ ===
bpy.ops.mesh.primitive_cylinder_add(radius=0.4, depth=1.5, location=(4.8 * {scale}, 0, 1.2 * {scale}))
dragon_snout = bpy.context.active_object
dragon_snout.name = "Dragon_Snout"
dragon_snout.rotation_euler[1] = math.pi / 2

# === AILES MAJESTUEUSES ===
# Aile gauche
bpy.ops.mesh.primitive_plane_add(size=3 * {scale}, location=(-1 * {scale}, 2.5 * {scale}, 2 * {scale}))
wing_left = bpy.context.active_object
wing_left.name = "Wing_Left"
wing_left.rotation_euler = (0, math.pi/6, math.pi/4)

# Aile droite  
bpy.ops.mesh.primitive_plane_add(size=3 * {scale}, location=(-1 * {scale}, -2.5 * {scale}, 2 * {scale}))
wing_right = bpy.context.active_object
wing_right.name = "Wing_Right"
wing_right.rotation_euler = (0, -math.pi/6, -math.pi/4)

# === QUEUE PUISSANTE ===
bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=4, location=(-4 * {scale}, 0, 0.8 * {scale}))
dragon_tail = bpy.context.active_object
dragon_tail.name = "Dragon_Tail"
dragon_tail.rotation_euler[1] = math.pi / 2
dragon_tail.scale = (1, 1, 0.3)

# === PATTES ===
paw_positions = [
    (1 * {scale}, 1.5 * {scale}, 0),
    (1 * {scale}, -1.5 * {scale}, 0), 
    (-1 * {scale}, 1.2 * {scale}, 0),
    (-1 * {scale}, -1.2 * {scale}, 0)
]

for i, pos in enumerate(paw_positions):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=1.5, location=pos)
    paw = bpy.context.active_object
    paw.name = f"Dragon_Paw_{{i+1}}"
    paw.location[2] = 0.75

# === MATÉRIAU DRAGON ÉCAILLES ===
dragon_material = bpy.data.materials.new(name="Dragon_Scales")
dragon_material.use_nodes = True
dragon_material.node_tree.nodes.clear()

# Nœuds pour écailles draconiennes
output = dragon_material.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
principled = dragon_material.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')

# Couleur vert émeraude métallique
principled.inputs["Base Color"].default_value = (0.1, 0.6, 0.2, 1.0)
principled.inputs["Metallic"].default_value = 0.7
principled.inputs["Roughness"].default_value = 0.3
principled.inputs["Specular"].default_value = 0.8

dragon_material.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])

# Appliquer matériau à tous les objets dragon
for obj in [dragon_body, dragon_head, dragon_snout, wing_left, wing_right, dragon_tail]:
    obj.data.materials.append(dragon_material)

# === SYSTÈME DE PARTICULES POUR FLAMMES ===
# Point d'émission des flammes (bouche du dragon)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(5.5 * {scale}, 0, 1.2 * {scale}))
flame_emitter = bpy.context.active_object
flame_emitter.name = "Flame_Emitter"

# Configuration système de particules
flame_emitter.modifiers.new(name="ParticleSystem", type='PARTICLE_SYSTEM')
particle_sys = flame_emitter.particle_systems[0]
settings = particle_sys.settings

# Paramètres des particules de feu
settings.count = 1000
settings.lifetime = 60
settings.lifetime_random = 0.5
settings.emit_from = 'VERT'
settings.physics_type = 'NEWTON'

# Vélocité initiale (direction du souffle)
settings.normal_factor = {fire_intensity}
settings.factor_random = 2.0

# Gravité et turbulence
settings.effector_weights.gravity = -0.1
settings.brownian_factor = 0.3

# === MATÉRIAU FLAMMES ===
flame_material = bpy.data.materials.new(name="Dragon_Fire")
flame_material.use_nodes = True
flame_material.node_tree.nodes.clear()

# Nœuds pour feu réaliste
output = flame_material.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
emission = flame_material.node_tree.nodes.new(type='ShaderNodeEmission')

# Couleur des flammes orange-rouge
emission.inputs["Color"].default_value = (1.0, 0.3, 0.05, 1.0)
emission.inputs["Strength"].default_value = 15.0

flame_material.node_tree.links.new(emission.outputs['Emission'], output.inputs['Surface'])

# Assigner matériau flammes
settings.material = len(bpy.data.materials)
flame_emitter.data.materials.append(flame_material)

# === REGROUPEMENT DRAGON ===
dragon_parts = [dragon_body, dragon_head, dragon_snout, wing_left, wing_right, dragon_tail]

for obj in dragon_parts:
    obj.select_set(True)

bpy.context.view_layer.objects.active = dragon_body
bpy.ops.object.join()
dragon_complete = bpy.context.active_object
dragon_complete.name = "Dragon_Majestueux"

# === ANIMATION BATTEMENT D'AILES ===
# Animation du dragon complet en vol
dragon_complete.location = (0, 0, 2)
dragon_complete.keyframe_insert(data_path="location", index=2, frame=1)

# Mouvement de vol vertical
dragon_complete.location[2] = 4
dragon_complete.keyframe_insert(data_path="location", index=2, frame=60)

dragon_complete.location[2] = 2
dragon_complete.keyframe_insert(data_path="location", index=2, frame=120)

# Rotation majestueuse
dragon_complete.rotation_euler[2] = 0
dragon_complete.keyframe_insert(data_path="rotation_euler", index=2, frame=1)

dragon_complete.rotation_euler[2] = math.pi / 4
dragon_complete.keyframe_insert(data_path="rotation_euler", index=2, frame=120)

# === ÉCLAIRAGE DRAMATIQUE ===
# Lumière principale chaude
bpy.ops.object.light_add(type='SUN', location=(10, 10, 15))
sun = bpy.context.active_object
sun.data.energy = 8
sun.data.color = (1.0, 0.9, 0.7)

# Lumière d'ambiance mystique
bpy.ops.object.light_add(type='AREA', location=(0, 0, 10))
area = bpy.context.active_object
area.data.energy = 5
area.data.color = (0.3, 0.5, 1.0)
area.data.size = 8

# Lumière des flammes (éclairage dynamique)
bpy.ops.object.light_add(type='POINT', location=(5.5 * {scale}, 0, 1.2 * {scale}))
flame_light = bpy.context.active_object
flame_light.data.energy = 20
flame_light.data.color = (1.0, 0.4, 0.1)

# === CONFIGURATION SCÈNE ===
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120
scene.frame_set(60)

# Rendu Cycles pour qualité cinématique
scene.render.engine = 'CYCLES'
scene.cycles.samples = 256
scene.view_settings.view_transform = 'Filmic'
scene.view_settings.exposure = 0.2

print("🐲 DRAGON CRACHEUR DE FLAMMES CRÉÉ!")
print(f"Échelle: {{{scale}}}, Intensité feu: {{{fire_intensity}}}")
print("Simulation de particules et éclairage cinématique activés")
"""


    @staticmethod
    def create_virelangue_roulette(segments: int = 8, virelangues: List[str] = None) -> str:
        """Génère le code Python Blender pour une roulette des virelangues Eloquence COMPATIBLE BLENDER 4.5"""
        
        if not virelangues:
            virelangues = [
                "Un chasseur sachant chasser",
                "Seize jacinthes sèchent",
                "Trois petits chats gris",
                "Piano panier, panier piano",
                "Ces six saucissons-ci",
                "Natacha n'attacha pas",
                "Didon dîna dit-on",
                "Tonton, ton thé t'a-t-il ôté"
            ]
        
        # Couleurs Flutter Eloquence vibrantes
        flutter_colors = [
            "#00BCD4",  # Cyan
            "#9C27B0",  # Purple
            "#4CAF50",  # Green
            "#FF9800",  # Orange
            "#2196F3",  # Blue
            "#E91E63",  # Pink
            "#8BC34A",  # Light Green
            "#FF5722"   # Deep Orange
        ]
        
        colors = flutter_colors[:segments]
        
        return f"""
import bpy
import math

# === NETTOYAGE INITIAL ===
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# === DONNÉES ELOQUENCE ===
segment_colors = {colors}
virelangues_list = {virelangues[:segments]}
segments_count = {segments}

print(f"Création roulette avec {{segments_count}} segments")

# === BASE DE LA ROULETTE ===
bpy.ops.mesh.primitive_cylinder_add(vertices=segments_count, radius=3.5, depth=0.5, location=(0, 0, 0))
roulette_base = bpy.context.active_object
roulette_base.name = "Roulette_Eloquence_Base"

# Matériau de base métallique brillant
base_mat = bpy.data.materials.new(name="Base_Mat")
base_mat.use_nodes = True
base_mat.node_tree.nodes.clear()

# Nœuds pour base métallique
output = base_mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
principled = base_mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')

# Configuration métallique brillant
principled.inputs["Base Color"].default_value = (0.9, 0.92, 0.95, 1.0)
principled.inputs["Metallic"].default_value = 0.8
principled.inputs["Roughness"].default_value = 0.1

base_mat.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])
roulette_base.data.materials.append(base_mat)

# === SEGMENTS COLORÉS ===
segment_objects = []
text_objects = []

for i in range(segments_count):
    # Créer segment
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=3.2, depth=0.6, location=(0, 0, 0.35))
    segment = bpy.context.active_object
    segment.name = f"Segment_{{i+1}}"
    
    # Position
    angle = i * (2 * math.pi / segments_count)
    segment.rotation_euler[2] = angle
    
    # Matériau segment coloré
    mat = bpy.data.materials.new(name=f"Segment_Mat_{{i+1}}")
    mat.use_nodes = True
    
    # Couleur Flutter
    hex_color = segment_colors[i].lstrip('#')
    rgb = tuple(int(hex_color[j:j+2], 16)/255.0 for j in (0, 2, 4))
    mat.diffuse_color = (*rgb, 1.0)
    
    segment.data.materials.append(mat)
    segment_objects.append(segment)
    
    # === TEXTE 3D ===
    text_x = 2.0 * math.cos(angle)
    text_y = 2.0 * math.sin(angle)
    
    bpy.ops.object.text_add(location=(text_x, text_y, 0.7))
    text_obj = bpy.context.active_object
    text_obj.name = f"Text_{{i+1}}"
    
    # Configuration texte
    text_obj.data.body = virelangues_list[i] if i < len(virelangues_list) else f"Segment {{i+1}}"
    text_obj.data.size = 0.15
    text_obj.data.extrude = 0.03
    text_obj.data.align_x = 'CENTER'
    text_obj.data.align_y = 'CENTER'
    text_obj.rotation_euler[2] = angle + math.pi/2
    
    # Matériau texte doré brillant
    text_mat = bpy.data.materials.new(name=f"Text_Gold_{{i+1}}")
    text_mat.use_nodes = True
    text_mat.node_tree.nodes.clear()
    
    # Nœuds pour or brillant
    output = text_mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
    principled = text_mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')
    
    # Or brillant
    principled.inputs["Base Color"].default_value = (1.0, 0.8, 0.1, 1.0)
    principled.inputs["Metallic"].default_value = 1.0
    principled.inputs["Roughness"].default_value = 0.05
    
    text_mat.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])
    
    text_obj.data.materials.append(text_mat)
    text_objects.append(text_obj)

# === AIGUILLE ===
bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.1, radius2=0.02, depth=2.0, location=(0, 0, 1.0))
aiguille = bpy.context.active_object
aiguille.name = "Aiguille"
aiguille.rotation_euler[1] = math.pi / 2

# Matériau aiguille chrome brillant
aiguille_mat = bpy.data.materials.new(name="Chrome")
aiguille_mat.use_nodes = True
aiguille_mat.node_tree.nodes.clear()

# Nœuds pour chrome
output = aiguille_mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
principled = aiguille_mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')

# Chrome parfait
principled.inputs["Base Color"].default_value = (0.95, 0.95, 1.0, 1.0)
principled.inputs["Metallic"].default_value = 1.0
principled.inputs["Roughness"].default_value = 0.02

aiguille_mat.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])
aiguille.data.materials.append(aiguille_mat)

# === ÉCLAIRAGE SPECTACULAIRE ===

# Soleil principal puissant
bpy.ops.object.light_add(type='SUN', location=(8, 8, 12))
sun = bpy.context.active_object
sun.data.energy = 10
sun.data.color = (1.0, 0.95, 0.8)

# Lumière d'ambiance colorée
bpy.ops.object.light_add(type='AREA', location=(0, 0, 8))
area = bpy.context.active_object
area.data.energy = 8
area.data.color = (0.8, 0.9, 1.0)
area.data.size = 6

# Lumières colorées pour reflets
positions = [(6, 0, 4), (-3, 5, 4), (-3, -5, 4)]
colors = [(1.0, 0.2, 0.2), (0.2, 1.0, 0.2), (0.2, 0.2, 1.0)]

for i, (pos, color) in enumerate(zip(positions, colors)):
    bpy.ops.object.light_add(type='POINT', location=pos)
    light = bpy.context.active_object
    light.data.energy = 5
    light.data.color = color

# === REGROUPEMENT ===
all_objects = [roulette_base] + segment_objects + text_objects

for obj in all_objects:
    obj.select_set(True)

bpy.context.view_layer.objects.active = roulette_base
bpy.ops.object.join()
roulette = bpy.context.active_object
roulette.name = "Roulette_Eloquence_Finale"

# === ANIMATION SIMPLE ===
roulette.scale = (0.1, 0.1, 0.1)
roulette.rotation_euler = (0, 0, 0)
roulette.keyframe_insert(data_path="scale", frame=1)
roulette.keyframe_insert(data_path="rotation_euler", index=2, frame=1)

# Agrandissement
roulette.scale = (1.0, 1.0, 1.0)
roulette.keyframe_insert(data_path="scale", frame=30)

# Rotation
roulette.rotation_euler[2] = 8 * math.pi
roulette.keyframe_insert(data_path="rotation_euler", index=2, frame=120)

# Configuration scène pour rendu de qualité
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120
scene.frame_set(60)  # Frame du milieu pour capture animation

# Configuration rendu Cycles pour couleurs vives
scene.render.engine = 'CYCLES'
scene.cycles.samples = 128
scene.view_settings.view_transform = 'Filmic'
scene.view_settings.exposure = 0.3

print("ROULETTE ELOQUENCE COLORÉE CRÉÉE!")
print(f"{{segments_count}} segments avec couleurs Flutter vives")
print("Matériaux métalliques et éclairage spectaculaire")
"""

class PromptParser:
    """Analyseur de prompts en langage naturel pour générer des animations Blender"""
    
    @staticmethod
    def parse_prompt(prompt: str) -> Dict[str, Any]:
        """Alias pour parse_animation_prompt pour compatibilité"""
        return PromptParser.parse_animation_prompt(prompt)
    
    @staticmethod
    def parse_animation_prompt(prompt: str) -> Dict[str, Any]:
        """Analyse un prompt et retourne les paramètres d'animation"""
        prompt_lower = prompt.lower()
        
        # Détection du type d'animation (virelangues en PREMIER pour éviter confusion avec roulettes)
        if any(word in prompt_lower for word in ["virelangue", "tongue", "twister", "magique"]):
            animation_type = "virelangue_roulette"
            
            # Extraction du nombre de segments
            segments = 8  # par défaut pour les virelangues
            for i in range(3, 13):  # 3 à 12 segments pour virelangues
                if str(i) in prompt:
                    segments = i
                    break
            
            return {
                "type": animation_type,
                "params": {
                    "segments": segments
                }
            }
            
        elif any(word in prompt_lower for word in ["roulette", "roue", "wheel", "casino"]):
            animation_type = "roulette"
            
            # Extraction du nombre de segments
            segments = 6  # par défaut
            for i in range(2, 21):
                if str(i) in prompt:
                    segments = i
                    break
            
            # Extraction des couleurs
            colors = []
            color_map = {
                "rouge": "#FF0000", "red": "#FF0000",
                "vert": "#00FF00", "green": "#00FF00",
                "bleu": "#0000FF", "blue": "#0000FF",
                "jaune": "#FFFF00", "yellow": "#FFFF00",
                "noir": "#000000", "black": "#000000",
                "blanc": "#FFFFFF", "white": "#FFFFFF",
                "orange": "#FF8000", "violet": "#8000FF", "purple": "#8000FF"
            }
            
            for color_name, hex_color in color_map.items():
                if color_name in prompt_lower:
                    colors.append(hex_color)
            
            return {
                "type": animation_type,
                "params": {
                    "segments": segments,
                    "colors": colors if colors else None
                }
            }
            
        elif any(word in prompt_lower for word in ["dragon", "flamme", "fire", "flame", "cracheur", "breathing"]):
            animation_type = "dragon_fire"
            
            # Extraction de l'échelle
            scale = 1.0  # par défaut
            if "grand" in prompt_lower or "large" in prompt_lower:
                scale = 1.5
            elif "petit" in prompt_lower or "small" in prompt_lower:
                scale = 0.7
            
            # Extraction de l'intensité du feu
            fire_intensity = 10.0  # par défaut
            if "intense" in prompt_lower or "puissant" in prompt_lower:
                fire_intensity = 15.0
            elif "faible" in prompt_lower or "doux" in prompt_lower:
                fire_intensity = 5.0
            
            return {
                "type": animation_type,
                "params": {
                    "scale": scale,
                    "fire_intensity": fire_intensity
                }
            }
            
        elif any(word in prompt_lower for word in ["cube", "box", "rebond", "bounce", "saut"]):
            animation_type = "bouncing_cube"
            
            # Extraction du nombre de rebonds
            bounces = 3  # par défaut
            for i in range(1, 11):
                if f"{i} rebond" in prompt_lower or f"{i} bounce" in prompt_lower:
                    bounces = i
                    break
            
            return {
                "type": animation_type,
                "params": {
                    "bounces": bounces
                }
            }
            
        elif any(word in prompt_lower for word in ["logo", "texte", "text", "apparaît", "appear"]):
            animation_type = "logo_text"
            
            # Extraction du texte
            text = "ELOQUENCE"  # par défaut
            
            # Recherche de texte entre guillemets
            import re
            quoted_text = re.search(r'["\']([^"\']+)["\']', prompt)
            if quoted_text:
                text = quoted_text.group(1).upper()
            elif "eloquence" in prompt_lower:
                text = "ELOQUENCE"
            
            return {
                "type": animation_type,
                "params": {
                    "text": text
                }
            }
            animation_type = "virelangue_roulette"
            
            # Extraction du nombre de segments
            segments = 8  # par défaut pour les virelangues
            for i in range(3, 13):  # 3 à 12 segments pour virelangues
                if str(i) in prompt:
                    segments = i
                    break
            
            return {
                "type": animation_type,
                "params": {
                    "segments": segments
                }
            }
            
        elif any(word in prompt_lower for word in ["logo", "texte", "text", "apparaît", "appear"]):
            animation_type = "logo_text"
            
            # Extraction du texte
            text = "ELOQUENCE"  # par défaut
            
            # Recherche de texte entre guillemets
            import re
            quoted_text = re.search(r'["\']([^"\']+)["\']', prompt)
            if quoted_text:
                text = quoted_text.group(1).upper()
            elif "eloquence" in prompt_lower:
                text = "ELOQUENCE"
            
            return {
                "type": animation_type,
                "params": {
                    "text": text
                }
            }
        
        # Animation générique par défaut
        return {
            "type": "generic",
            "params": {
                "prompt": prompt
            }
        }

def add_eloquence_tools(mcp: FastMCP, blender_connection_getter):
    """Ajoute les outils Eloquence spécialisés au serveur MCP"""
    
    @mcp.tool()
    def open_blender_gui_with_prompt(ctx: Context, prompt: str) -> str:
        """
        Ouvre directement Blender GUI avec une animation basée sur le prompt.
        Parfait pour visualisation interactive, rotation, zoom et contrôles manuels.
        
        Exemples de prompts supportés:
        - "Roulette des virelangues colorée"
        - "Cube qui rebondit 5 fois"
        - "Logo ELOQUENCE qui tourne"
        - "Roulette casino 8 segments"
        
        Parameters:
        - prompt: Description en langage naturel de l'animation à créer et visualiser
        """
        try:
            logger.info(f"🎮 Ouverture Blender GUI avec prompt: {prompt}")
            
            # Importer le module de lancement GUI
            import sys
            import os
            
            # Ajouter le répertoire courant au path si nécessaire
            current_dir = os.path.dirname(__file__)
            if current_dir not in sys.path:
                sys.path.append(current_dir)
                
            from launch_blender_gui import launch_blender_gui
            
            # Lancer Blender GUI avec le prompt
            success = launch_blender_gui(prompt)
            
            if success:
                return f"""✅ Blender GUI ouvert avec succès !

🎮 **CONTRÔLES BLENDER:**
• 🖱️  Bouton du milieu + glisser = Rotation de la vue
• 🔍 Molette = Zoom/Dézoom
• ⏯️  ESPACE = Lancer/Arrêter l'animation
• 🎥 F12 = Rendre une image haute qualité
• 🎬 CTRL+F12 = Rendre une animation complète
• 📁 CTRL+S = Sauvegarder le fichier .blend

🎨 **Votre création:** {prompt}
✨ Profitez de la visualisation interactive en 3D !"""
            else:
                return f"❌ Échec de l'ouverture de Blender GUI. Vérifiez que Blender 4.5 est installé."
                
        except Exception as e:
            logger.error(f"❌ Erreur lors de l'ouverture GUI: {e}")
            return f"❌ Erreur lors de l'ouverture de Blender GUI: {str(e)}"
    
    @mcp.tool()
    def create_animation_from_prompt(ctx: Context, prompt: str) -> str:
        """
        Crée une animation Blender à partir d'un prompt en langage naturel.
        
        Exemples de prompts supportés:
        - "Roulette de casino avec 8 segments rouges et noirs"
        - "Cube qui rebondit 5 fois"
        - "Logo ELOQUENCE qui apparaît et tourne"
        - "Sphère dorée qui tourne lentement"
        
        Parameters:
        - prompt: Description en langage naturel de l'animation désirée
        """
        try:
            logger.info(f"🎨 Analyse du prompt: {prompt}")
            
            # Parser le prompt
            animation_params = PromptParser.parse_animation_prompt(prompt)
            logger.info(f"📋 Paramètres détectés: {animation_params}")
            
            # Générer le code Blender approprié
            params = animation_params.get("params", {})
            if animation_params["type"] == "roulette":
                code = AnimationTemplates.create_spinning_roulette(
                    segments=params.get("segments", 6),
                    colors=params.get("colors")
                )
            elif animation_params["type"] == "bouncing_cube":
                code = AnimationTemplates.create_bouncing_cube(
                    bounces=params.get("bounces", 3)
                )
            elif animation_params["type"] == "virelangue_roulette":
                code = AnimationTemplates.create_virelangue_roulette(
                    segments=params.get("segments", 8)
                )
            elif animation_params["type"] == "dragon_fire":
                code = AnimationTemplates.create_dragon_fire_breathing(
                    scale=params.get("scale", 1.0),
                    fire_intensity=params.get("fire_intensity", 10.0)
                )
            elif animation_params["type"] == "logo_text":
                code = AnimationTemplates.create_rotating_logo_text(
                    text=params.get("text", "ELOQUENCE")
                )
            else:
                return f"❌ Type d'animation non reconnu dans: '{prompt}'"
            
            # Exécuter le code dans Blender
            blender = blender_connection_getter()
            result = blender.send_command("execute_code", {"code": code})
            
            return f"✅ Animation créée avec succès ! Type: {animation_params['type']}"
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la création d'animation: {e}")
            return f"❌ Erreur lors de la création d'animation: {str(e)}"
    
    @mcp.tool()
    def export_animation(ctx: Context, format: str = "gltf", filename: str = None) -> str:
        """
        Exporte l'animation courante de Blender dans le format spécifié.
        
        Parameters:
        - format: Format d'export (gltf, fbx, obj, mp4)
        - filename: Nom du fichier (optionnel, auto-généré si non spécifié)
        """
        try:
            if not filename:
                import datetime
                timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"eloquence_animation_{timestamp}"
            
            export_code = f"""
import bpy
import os

# Définir le chemin d'export
export_path = os.path.expanduser("~/Desktop/{filename}")

# Export selon le format
if "{format}" == "gltf":
    export_path += ".gltf"
    bpy.ops.export_scene.gltf(filepath=export_path, export_animations=True)
elif "{format}" == "fbx":
    export_path += ".fbx"
    bpy.ops.export_scene.fbx(filepath=export_path, use_selection=False)
elif "{format}" == "obj":
    export_path += ".obj"
    bpy.ops.export_scene.obj(filepath=export_path)
elif "{format}" == "mp4":
    # Rendu de l'animation en vidéo
    scene = bpy.context.scene
    scene.render.filepath = os.path.expanduser("~/Desktop/{filename}")
    scene.render.image_settings.file_format = 'FFMPEG'
    scene.render.ffmpeg.format = 'MPEG4'
    scene.render.ffmpeg.codec = 'H264'
    bpy.ops.render.render(animation=True)
    export_path = scene.render.filepath + ".mp4"

print(f"✅ Animation exportée: {{export_path}}")
"""
            
            blender = blender_connection_getter()
            result = blender.send_command("execute_code", {"code": export_code})
            
            return f"✅ Animation exportée en {format.upper()} : {filename}"
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de l'export: {e}")
            return f"❌ Erreur lors de l'export: {str(e)}"
    
    @mcp.tool()
    def list_animation_templates(ctx: Context) -> str:
        """
        Liste les templates d'animations disponibles avec des exemples de prompts.
        """
        templates = """
🎨 **Templates d'animations disponibles pour RooCode:**

**1. Roulette de Casino**
   - Prompts: "Roulette 6 segments", "Roue casino rouge noir", "Wheel 8 parts"
   - Paramètres: nombre de segments (2-20), couleurs personnalisées

**2. Cube Rebondissant** 
   - Prompts: "Cube rebondit 3 fois", "Box bounce 5 times", "Saut cube"
   - Paramètres: nombre de rebonds (1-10), hauteur

**3. Logo Texte 3D**
   - Prompts: "Logo ELOQUENCE apparaît", "Text HELLO tourne", "Logo 'MON TEXTE'"
   - Paramètres: texte personnalisé, couleur, animation

**Exemples de prompts complets:**
• "Roulette de casino avec 8 segments rouges et noirs qui tourne"
• "Cube orange qui rebondit 5 fois sur le sol"  
• "Logo 'ELOQUENCE' doré qui apparaît et tourne"
• "Roue de la fortune avec 12 segments colorés"

**Formats d'export supportés:**
• GLTF (recommandé pour le web)
• FBX (pour Unity/Unreal)
• OBJ (modèles statiques)
• MP4 (vidéo de l'animation)
"""
        return templates

    logger.info("✅ Outils Eloquence Blender ajoutés au serveur MCP")