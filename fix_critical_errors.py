#!/usr/bin/env python3
"""
Script pour corriger les erreurs critiques identifiées dans les logs
"""

import os
import re

def fix_import_re_error():
    """Corrige l'erreur 'name re is not defined' dans enhanced_multi_agent_manager.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    print("🔧 CORRECTION 1: Import 're' manquant")
    
    try:
        # Lire le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Vérifier si import re est déjà présent
        if 'import re' in content:
            print("✅ Import 're' déjà présent")
            return True
        
        # Ajouter import re après les autres imports
        lines = content.split('\n')
        
        # Trouver la ligne où ajouter l'import
        import_line_index = -1
        for i, line in enumerate(lines):
            if line.startswith('import ') or line.startswith('from '):
                import_line_index = i
        
        if import_line_index == -1:
            # Ajouter au début du fichier
            lines.insert(0, 'import re')
        else:
            # Ajouter après le dernier import
            lines.insert(import_line_index + 1, 'import re')
        
        # Réécrire le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        
        print("✅ Import 're' ajouté avec succès")
        return True
        
    except Exception as e:
        print(f"❌ Erreur correction import 're': {e}")
        return False

def fix_manager_scope_error():
    """Corrige l'erreur de scope de la variable manager dans multi_agent_main.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    print("🔧 CORRECTION 2: Scope variable manager")
    
    try:
        # Lire le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Chercher la fonction problématique
        pattern = r'(.*?)intro_text, intro_audio = await manager\.generate_introduction\(exercise_type, user_data\)'
        
        if re.search(pattern, content, re.DOTALL):
            # Remplacer par une version sécurisée
            replacement = '''try:
        if 'manager' in locals() and manager:
            intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
        else:
            logger.error("❌ Manager non initialisé pour introduction")
            return
    except Exception as e:
        logger.error(f"❌ Erreur génération introduction: {e}")
        return'''
            
            content = re.sub(
                r'intro_text, intro_audio = await manager\.generate_introduction\(exercise_type, user_data\)',
                replacement,
                content
            )
            
            # Réécrire le fichier
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print("✅ Scope variable manager corrigé")
            return True
        else:
            print("⚠️ Pattern manager.generate_introduction non trouvé")
            return False
        
    except Exception as e:
        print(f"❌ Erreur correction scope manager: {e}")
        return False

def verify_corrections():
    """Vérifie que les corrections ont été appliquées"""
    
    print("\n🧪 VÉRIFICATION DES CORRECTIONS")
    print("=" * 50)
    
    # Vérification 1: Import re
    file1 = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    try:
        with open(file1, 'r') as f:
            content1 = f.read()
        
        if 'import re' in content1:
            print("✅ Import 're' présent dans enhanced_multi_agent_manager.py")
        else:
            print("❌ Import 're' manquant dans enhanced_multi_agent_manager.py")
            return False
    except Exception as e:
        print(f"❌ Erreur vérification import re: {e}")
        return False
    
    # Vérification 2: Fonction clean_agent_names
    if 'def clean_agent_names' in content1:
        print("✅ Fonction clean_agent_names présente")
    else:
        print("❌ Fonction clean_agent_names manquante")
        return False
    
    # Vérification 3: Scope manager
    file2 = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    try:
        with open(file2, 'r') as f:
            content2 = f.read()
        
        if 'if \'manager\' in locals()' in content2:
            print("✅ Scope manager corrigé dans multi_agent_main.py")
        else:
            print("⚠️ Scope manager non modifié (peut-être déjà correct)")
    except Exception as e:
        print(f"❌ Erreur vérification scope manager: {e}")
        return False
    
    return True

def main():
    """Fonction principale"""
    
    print("🚀 CORRECTION ERREURS CRITIQUES ELOQUENCE")
    print("=" * 60)
    
    success = True
    
    # Correction 1: Import re
    if not fix_import_re_error():
        success = False
    
    # Correction 2: Scope manager
    if not fix_manager_scope_error():
        success = False
    
    # Vérification
    if not verify_corrections():
        success = False
    
    if success:
        print("\n✅ TOUTES LES CORRECTIONS APPLIQUÉES AVEC SUCCÈS !")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Committer et pousser les corrections")
        print("2. Redémarrer les services Docker")
        print("3. Tester avec une nouvelle room")
        print("4. Vérifier les logs pour :")
        print("   - ✅ Introduction générée")
        print("   - 🔍 RECHERCHE VOIX")
        print("   - ✅ MAPPING TROUVÉ")
        print("   - 🧹 Nom agent retiré")
    else:
        print("\n❌ CERTAINES CORRECTIONS ONT ÉCHOUÉ")
        print("Vérifiez les erreurs ci-dessus")
    
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

