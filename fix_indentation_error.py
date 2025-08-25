#!/usr/bin/env python3
"""
Script pour corriger l'erreur d'indentation dans multi_agent_main.py
"""

import os

def fix_indentation_error():
    """Corrige l'erreur d'indentation dans multi_agent_main.py ligne 1751-1752"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    print("🔧 CORRECTION ERREUR INDENTATION")
    print(f"📁 Fichier: {file_path}")
    
    try:
        # Lire le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        print(f"📊 Fichier lu: {len(lines)} lignes")
        
        # Trouver et corriger l'erreur d'indentation autour de la ligne 1751
        for i in range(len(lines)):
            line_num = i + 1
            line = lines[i]
            
            # Chercher la ligne problématique
            if line_num >= 1750 and line_num <= 1755:
                print(f"🔍 Ligne {line_num}: {repr(line)}")
                
                # Corriger l'indentation si nécessaire
                if "try:" in line and not line.strip().endswith(":"):
                    # Ajouter le : manquant
                    lines[i] = line.rstrip() + ":\n"
                    print(f"✅ Ligne {line_num} corrigée: ajout de ':'")
                
                elif "if 'manager' in locals() and manager:" in line:
                    # Vérifier l'indentation
                    if not line.startswith("        "):  # 8 espaces pour être dans le try
                        lines[i] = "        " + line.lstrip()
                        print(f"✅ Ligne {line_num} corrigée: indentation ajustée")
        
        # Réécrire le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        
        print("✅ Fichier corrigé avec succès")
        return True
        
    except Exception as e:
        print(f"❌ Erreur correction indentation: {e}")
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
    
    print("🚀 CORRECTION ERREUR INDENTATION MULTI_AGENT_MAIN")
    print("=" * 60)
    
    success = True
    
    # Correction indentation
    if not fix_indentation_error():
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

