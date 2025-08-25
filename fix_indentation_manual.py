#!/usr/bin/env python3
"""
Script pour corriger manuellement l'indentation dans multi_agent_main.py
"""

import os

def fix_indentation_manual():
    """Corrige manuellement l'indentation dans multi_agent_main.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    print("🔧 CORRECTION MANUELLE INDENTATION")
    
    try:
        # Lire le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer le bloc problématique
        old_block = """            try:
        if 'manager' in locals() and manager:
            intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
        else:
            logger.error("❌ Manager non initialisé pour introduction")
            return
    except Exception as e:
        logger.error(f"❌ Erreur génération introduction: {e}")
        return"""
        
        new_block = """            try:
                if 'manager' in locals() and manager:
                    intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
                else:
                    logger.error("❌ Manager non initialisé pour introduction")
                    return
            except Exception as e:
                logger.error(f"❌ Erreur génération introduction: {e}")
                return"""
        
        # Remplacer dans le contenu
        if old_block in content:
            content = content.replace(old_block, new_block)
            print("✅ Bloc problématique remplacé")
        else:
            print("⚠️ Bloc problématique non trouvé, correction ligne par ligne")
            
            # Correction ligne par ligne
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if "if 'manager' in locals() and manager:" in line and not line.startswith("                "):
                    lines[i] = "                " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
                elif "intro_text, intro_audio = await manager.generate_introduction" in line and not line.startswith("                    "):
                    lines[i] = "                    " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
                elif 'logger.error("❌ Manager non initialisé pour introduction")' in line and not line.startswith("                    "):
                    lines[i] = "                    " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
                elif "return" in line and i > 1750 and i < 1760 and not line.startswith("                    "):
                    lines[i] = "                    " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
                elif "except Exception as e:" in line and i > 1750 and i < 1760 and not line.startswith("            "):
                    lines[i] = "            " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
                elif 'logger.error(f"❌ Erreur génération introduction: {e}")' in line and not line.startswith("                "):
                    lines[i] = "                " + line.lstrip()
                    print(f"✅ Ligne {i+1} corrigée")
            
            content = '\n'.join(lines)
        
        # Réécrire le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ Fichier corrigé avec succès")
        return True
        
    except Exception as e:
        print(f"❌ Erreur correction: {e}")
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
    
    print("🚀 CORRECTION MANUELLE INDENTATION")
    print("=" * 50)
    
    success = True
    
    # Correction indentation
    if not fix_indentation_manual():
        success = False
    
    # Vérification syntaxe
    if not verify_syntax():
        success = False
    
    if success:
        print("\n✅ CORRECTION RÉUSSIE !")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Committer et pousser la correction")
        print("2. Redémarrer les services Docker")
        print("3. Tester avec une nouvelle room")
    else:
        print("\n❌ CORRECTION ÉCHOUÉE")
        print("Vérifiez les erreurs ci-dessus")
    
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

