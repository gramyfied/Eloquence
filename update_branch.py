#!/usr/bin/env python3
"""
Script de mise à jour de la branche git
"""
import subprocess
import sys
import os

def run_command(command, description):
    """Exécute une commande git et affiche le résultat"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, cwd=os.getcwd())
        if result.returncode == 0:
            print(f"✅ {description} réussi")
            if result.stdout:
                print(result.stdout)
        else:
            print(f"❌ {description} échoué")
            if result.stderr:
                print(result.stderr)
            return False
    except Exception as e:
        print(f"❌ Erreur lors de {description}: {e}")
        return False
    return True

def main():
    print("🚀 Mise à jour de la branche cursor/fix-livekit-bidirectional-ai-connection-cf4b")
    print("=" * 70)
    
    # Sauvegarde des modifications
    if not run_command("git stash push -m \"Sauvegarde avant mise à jour avec cursor/fix-livekit-bidirectional-ai-connection-cf4b\"", "Sauvegarde des modifications"):
        print("❌ Impossible de sauvegarder les modifications")
        return
    
    # Récupération de la nouvelle branche
    if not run_command("git fetch origin", "Récupération des dernières modifications"):
        print("❌ Impossible de récupérer les dernières modifications")
        return
    
    if not run_command("git checkout -b cursor/fix-livekit-bidirectional-ai-connection-cf4b origin/cursor/fix-livekit-bidirectional-ai-connection-cf4b", "Changement vers la nouvelle branche"):
        print("❌ Impossible de changer vers la nouvelle branche")
        return
    
    print("\n🎉 Mise à jour terminée avec succès !")
    print("📋 Pour récupérer vos modifications: git stash pop")
    print("📋 Pour voir le statut: git status")

if __name__ == "__main__":
    main()
