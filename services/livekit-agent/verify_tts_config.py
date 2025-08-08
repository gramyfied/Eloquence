#!/usr/bin/env python3
"""
Script pour vérifier que chaque agent a sa propre voix TTS configurée
"""

from multi_agent_config import ExerciseTemplates, StudioPersonalities


def verify_tts_configurations():
    """Vérifie les configurations TTS de tous les agents"""
    
    print("\n" + "="*80)
    print("🎭 VÉRIFICATION DES VOIX TTS MULTI-AGENTS")
    print("="*80 + "\n")
    
    exercises = {
        "DÉBAT TV": ExerciseTemplates.studio_debate_tv(),
        "ENTRETIEN": ExerciseTemplates.studio_job_interview(),
        "BOARDROOM": ExerciseTemplates.studio_boardroom(),
        "COMMERCIAL": ExerciseTemplates.studio_sales_conference(),
        "KEYNOTE": ExerciseTemplates.studio_keynote()
    }
    
    all_configs = []
    voice_stats = {}
    
    for name, config in exercises.items():
        print(f"\n📺 {name} ({config.exercise_id})")
        print("-" * 40)
        
        for agent in config.agents:
            voice = agent.voice_config.get('voice', 'N/A')
            speed = agent.voice_config.get('speed', 1.0)
            pitch = agent.voice_config.get('pitch', 'normal')
            
            print(f"👤 {agent.name:20s} | Voice: {voice:8s} | Speed: {speed:4.2f} | Pitch: {pitch}")
            
            # Collecter les stats
            config_key = f"{voice}_{speed}_{pitch}"
            all_configs.append({
                'agent': agent.name,
                'voice': voice,
                'speed': speed,
                'pitch': pitch,
                'config_key': config_key
            })
            
            if voice not in voice_stats:
                voice_stats[voice] = 0
            voice_stats[voice] += 1
    
    # Analyser l'unicité
    unique_configs = set([c['config_key'] for c in all_configs])
    
    print("\n" + "="*80)
    print("📊 ANALYSE DES CONFIGURATIONS")
    print("="*80 + "\n")
    
    print(f"✅ Nombre total d'agents : {len(all_configs)}")
    print(f"✅ Configurations uniques : {len(unique_configs)}")
    print(f"✅ Taux d'unicité : {len(unique_configs)/len(all_configs)*100:.1f}%")
    
    print("\n📈 Distribution des voix :")
    for voice, count in sorted(voice_stats.items(), key=lambda x: x[1], reverse=True):
        bar = "█" * count
        percentage = count / len(all_configs) * 100
        print(f"   {voice:8s}: {bar:12s} ({count} agents, {percentage:.1f}%)")
    
    # Vérifier les duplications exactes
    print("\n🔍 Analyse des duplications :")
    config_groups = {}
    for conf in all_configs:
        key = conf['config_key']
        if key not in config_groups:
            config_groups[key] = []
        config_groups[key].append(conf['agent'])
    
    duplicates_found = False
    for key, agents in config_groups.items():
        if len(agents) > 1:
            duplicates_found = True
            voice, speed, pitch = key.split('_')
            print(f"   ⚠️ Configuration partagée ({voice}, speed={speed}, pitch={pitch}):")
            for agent in agents:
                print(f"      - {agent}")
    
    if not duplicates_found:
        print("   ✅ Aucune duplication exacte trouvée!")
    
    # Conclusion
    print("\n" + "="*80)
    print("📝 CONCLUSION")
    print("="*80 + "\n")
    
    if len(unique_configs) == len(all_configs):
        print("✅ PARFAIT : Chaque agent a une configuration vocale TOTALEMENT unique!")
    elif len(unique_configs) >= len(all_configs) * 0.75:
        print("✅ EXCELLENT : La majorité des agents ont des voix distinctes!")
        print("   Quelques agents partagent des configurations similaires,")
        print("   mais cela peut être intentionnel pour des rôles similaires.")
    elif len(unique_configs) >= len(all_configs) * 0.5:
        print("⚠️ ACCEPTABLE : Plus de la moitié des agents ont des voix uniques.")
        print("   Considérez d'ajouter plus de variations pour une meilleure immersion.")
    else:
        print("❌ AMÉLIORATION NÉCESSAIRE : Trop de voix identiques.")
        print("   Les agents manquent de distinction vocale.")
    
    # Recommandations
    print("\n💡 RECOMMANDATIONS :")
    if voice_stats.get('fable', 0) == 0:
        print("   - La voix 'fable' n'est pas utilisée, considérez l'ajouter")
    
    max_voice = max(voice_stats.values())
    if max_voice > len(all_configs) / 3:
        print("   - Certaines voix sont sur-utilisées, diversifiez davantage")
    
    print("   - Utilisez des variations de pitch pour différencier les agents similaires")
    print("   - Ajustez la vitesse selon la personnalité (rapide=énergique, lent=réfléchi)")
    
    return len(unique_configs) == len(all_configs)


if __name__ == "__main__":
    all_unique = verify_tts_configurations()
    exit(0 if all_unique else 1)