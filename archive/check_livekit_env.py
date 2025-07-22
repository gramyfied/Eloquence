import os
from dotenv import load_dotenv

load_dotenv()

print("\n[VERIFICATION] Verification des variables d'environnement LiveKit:")
print(f"LIVEKIT_API_KEY: {os.getenv('LIVEKIT_API_KEY', 'NON DÉFINI')}")
print(f"LIVEKIT_API_SECRET: {'*' * 32 if os.getenv('LIVEKIT_API_SECRET') else 'NON DÉFINI'}")
print(f"LIVEKIT_URL: {os.getenv('LIVEKIT_URL', 'NON DÉFINI')}")
