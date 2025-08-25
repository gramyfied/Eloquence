#!/usr/bin/env python3
"""
Script pour corriger définitivement le problème de scope du manager
"""

import os

def fix_manager_scope_final():
    """Corrige le problème de scope du manager dans multi_agent_main.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    print("🔧 CORRECTION SCOPE MANAGER FINAL")
    
    try:
        # Lire le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Identifier le problème : l'introduction est appelée AVANT que manager soit créé
        # PROBLÈME : ligne ~1750 appel introduction, ligne ~1771 création manager
        
        # SOLUTION : Déplacer l'appel d'introduction APRÈS la création du manager
        
        # Supprimer l'ancien bloc d'introduction (lignes ~1740-1765)
        old_intro_block = """        try:
            logging.getLogger(__name__).info("🎬 Génération introduction...")
            
            # Récupération user_data depuis le contexte
            user_data = {
                'user_name': getattr(ctx, 'user_name', 'notre invité'),
                'user_subject': getattr(ctx, 'user_subject', 'un sujet passionnant')
            }
            
            # Génération introduction avec manager
            try:
                if 'manager' in locals() and manager:
                    intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
                else:
                    logger.error("❌ Manager non initialisé pour introduction")
                    return
            except Exception as e:
                logger.error(f"❌ Erreur génération introduction: {e}")
                return
            logging.getLogger(__name__).info(f"✅ Introduction générée: {len(intro_text)} caractères")
            
            # Note: L'audio sera géré par le système TTS existant
            
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération introduction: {e}")
            # Continuer sans introduction
            pass"""
        
        # Remplacer par un commentaire simple
        new_intro_placeholder = """        # Introduction sera générée après initialisation du manager"""
        
        if old_intro_block in content:
            content = content.replace(old_intro_block, new_intro_placeholder)
            print("✅ Ancien bloc introduction supprimé")
        else:
            print("⚠️ Ancien bloc introduction non trouvé exactement, suppression ligne par ligne")
            
            # Supprimer ligne par ligne
            lines = content.split('\n')
            new_lines = []
            skip_lines = False
            
            for i, line in enumerate(lines):
                if "🎬 Génération introduction..." in line and "try:" in lines[i-1] if i > 0 else False:
                    skip_lines = True
                    new_lines.append("        # Introduction sera générée après initialisation du manager")
                    continue
                elif skip_lines and ("# 2. INITIALISATION DU MANAGER" in line or "logging.getLogger(__name__).info(f\"🎯 Initialisation système:" in line):
                    skip_lines = False
                    new_lines.append(line)
                elif not skip_lines:
                    new_lines.append(line)
            
            content = '\n'.join(new_lines)
        
        # Ajouter le nouveau bloc d'introduction APRÈS la création du manager
        manager_creation_line = "        manager = await initialize_multi_agent_system(exercise_type)"
        
        new_intro_block_after = """        manager = await initialize_multi_agent_system(exercise_type)
        
        # 3. GÉNÉRATION INTRODUCTION AVEC MANAGER INITIALISÉ
        try:
            logging.getLogger(__name__).info("🎬 Génération introduction...")
            
            # Récupération user_data depuis le contexte
            user_data = {
                'user_name': getattr(ctx, 'user_name', 'notre invité'),
                'user_subject': getattr(ctx, 'user_subject', 'un sujet passionnant')
            }
            
            # Génération introduction avec manager (maintenant initialisé)
            if manager:
                intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
                logging.getLogger(__name__).info(f"✅ Introduction générée: {len(intro_text)} caractères, {len(intro_audio) if intro_audio else 0} bytes audio")
            else:
                logging.getLogger(__name__).error("❌ Manager non initialisé après initialize_multi_agent_system")
                
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération introduction: {e}")
            # Continuer sans introduction"""
        
        if manager_creation_line in content:
            content = content.replace(manager_creation_line, new_intro_block_after)
            print("✅ Nouveau bloc introduction ajouté après création manager")
        else:
            print("❌ Ligne de création manager non trouvée")
            return False
        
        # Réécrire le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ Fichier corrigé avec succès")
        return True
        
    except Exception as e:
        print(f"❌ Erreur correction scope manager: {e}")
        return False

def verify_syntax():
    """Vérifie la syntaxe Python du fichier corrigé"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    print("\n🧪 VÉRIFICATION SYNTAXE PYTHON")
    
    try:
        # Compiler le fichier pour vérifier la syntaxe
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        compile(content, file_path, 'exec')
        print("✅ Syntaxe Python valide")
        return True
        
    except SyntaxError as e:
        print(f"❌ Erreur syntaxe: {e}")
        print(f"   Ligne {e.lineno}: {e.text}")
        return False
    except Exception as e:
        print(f"❌ Erreur vérification: {e}")
        return False

def main():
    """Fonction principale"""
    
    print("🚀 CORRECTION SCOPE MANAGER FINAL")
    print("=" * 50)
    
    success = True
    
    # Correction scope manager
    if not fix_manager_scope_final():
        success = False
    
    # Vérification syntaxe
    if not verify_syntax():
        success = False
    
    if success:
        print("\n✅ CORRECTION RÉUSSIE !")
        print("\n🎯 CHANGEMENTS APPLIQUÉS :")
        print("1. Ancien bloc introduction supprimé (avant création manager)")
        print("2. Nouveau bloc introduction ajouté (après création manager)")
        print("3. Manager maintenant accessible pour introduction")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Committer et pousser la correction")
        print("2. Redémarrer les services Docker")
        print("3. Tester avec une nouvelle room")
        print("4. Vérifier logs : '✅ Introduction générée: X caractères, X bytes audio'")
    else:
        print("\n❌ CORRECTION ÉCHOUÉE")
        print("Vérifiez les erreurs ci-dessus")
    
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

