# -*- coding: utf-8 -*-
import requests
import os
import re
from dotenv import load_dotenv
import socket

# --- Configuration ---
# Charger les variables d'environnement du fichier .env à la racine
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

# Extraire l'adresse IP de LLM_SERVICE_URL
llm_service_url = os.getenv("LLM_SERVICE_URL")
if not llm_service_url:
    print("[-] Erreur critique: LLM_SERVICE_URL n'est pas défini dans le fichier .env.")
    exit(1)

# Utilisation d'une expression régulière pour extraire l'IP ou le nom d'hôte
match = re.search(r'http://([^:]+)', llm_service_url)
if not match:
    print(f"[-] Erreur critique: Impossible d'extraire l'adresse IP de LLM_SERVICE_URL ('{llm_service_url}').")
    exit(1)

TARGET_IP = match.group(1)
API_BACKEND_PORT = 8000
WHISPER_STREAMING_PORT = 8006

# Endpoints à vérifier
EXPECTED_ENDPOINTS = {
    API_BACKEND_PORT: "/api/confidence-analysis",
    WHISPER_STREAMING_PORT: "/streaming/session"
}
NEW_CONFIDENCE_ENDPOINT = "/api/confidence-analysis"

# --- Fonctions de diagnostic ---

def check_port(ip, port):
    """Vérifie si un port est ouvert sur une IP donnée."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)  # Timeout de 2 secondes
    result = sock.connect_ex((ip, port))
    sock.close()
    return result == 0

def get_available_routes_from_fastapi(ip, port):
    """
    Tente de récupérer les routes disponibles depuis l'endpoint /docs de FastAPI.
    C'est une méthode courante pour l'introspection d'API FastAPI.
    """
    docs_url = f"http://{ip}:{port}/docs"
    try:
        print(f"\n[*] Tentative de récupération des routes depuis {docs_url}...")
        response = requests.get(docs_url, timeout=5)
        
        if response.status_code == 200:
            # L'endpoint /docs de FastAPI contient généralement le JSON de la spec OpenAPI
            # dans une variable JavaScript. Nous allons l'extraire.
            # C'est une heuristique, mais souvent efficace.
            openapi_spec_match = re.search(r'const\s+ui\s*=\s*SwaggerUIBundle\(\{\s*spec:\s*(\{.*\}),\s*dom_id:', response.text, re.DOTALL)
            if openapi_spec_match:
                 # Ceci est une chaîne, pas un vrai JSON, nous allons donc extraire les chemins avec une regex
                paths_text = openapi_spec_match.group(1)
                # Regex pour trouver toutes les clés de chemin (ex: "/api/v1/users")
                routes = re.findall(r'"(/[^"]+)"\s*:', paths_text)
                # Nettoyage et dédoublonnage
                unique_routes = sorted(list(set(routes)))
                print(f"[+] Routes extraites avec succès depuis {docs_url}")
                return unique_routes
            else:
                # Si la spec n'est pas trouvée, on tente de trouver les routes dans le HTML
                routes_from_html = re.findall(r'<span class="opblock-summary-path".*?>\s*<a.*?href="#/.*?/(.*?)"><span>(.*?)</span></a>', response.text)
                if routes_from_html:
                    unique_routes = sorted(list(set([r[1] for r in routes_from_html])))
                    print(f"[+] Routes extraites (méthode alternative) depuis {docs_url}")
                    return unique_routes
                
                print("[-] L'endpoint /docs est accessible, mais la spécification OpenAPI n'a pas pu être extraite automatiquement.")
                return None

        elif response.status_code == 404:
            print(f"INFO: L'endpoint /docs n'existe pas sur {ip}:{port}. Ce n'est pas forcément une erreur.")
            return None
        else:
            print(f"[-] Réponse inattendue de {docs_url}: {response.status_code}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"[-] Erreur de connexion à {docs_url}: {e}")
        return None

# --- Exécution du diagnostic ---

print("--- Début du Diagnostic des Routes Backend ---")
print(f"Adresse IP cible: {TARGET_IP}")
print("-" * 40)

# 1. Diagnostic du Backend Principal (API)
print(f"\n--- Service API Backend (Port {API_BACKEND_PORT}) ---")
if check_port(TARGET_IP, API_BACKEND_PORT):
    print(f"[+] Le port {API_BACKEND_PORT} est ouvert et le service répond.")
    
    # Vérification du health check
    try:
        health_response = requests.get(f"http://{TARGET_IP}:{API_BACKEND_PORT}/health", timeout=3)
        if health_response.status_code == 200:
            print("[+] L'endpoint /health répond correctement (Status 200).")
        else:
            print(f"[-] L'endpoint /health a répondu avec un code inattendu: {health_response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"[-] Erreur lors de la requête à /health: {e}")

    # Récupération des routes
    available_routes = get_available_routes_from_fastapi(TARGET_IP, API_BACKEND_PORT)
    
    if available_routes:
        print("\nRoutes disponibles sur le service API:")
        for route in available_routes:
            print(f"  - {route}")
        
        # Vérification de l'endpoint attendu
        expected = EXPECTED_ENDPOINTS[API_BACKEND_PORT]
        if expected in available_routes:
            print(f"\n[+] L'endpoint attendu '{expected}' EST PRÉSENT sur le service.")
        else:
            print(f"\n[-] DIAGNOSTIC CLÉ: L'endpoint attendu '{expected}' EST MANQUANT sur le service !")
            print("   Cause probable: La version du code backend déployée ne contient pas cette route, ou elle a été renommée.")
    else:
        print("\n[-] Impossible de lister les routes du service API. Tentative de test direct de l'endpoint.")
        try:
            confidence_response = requests.post(f"http://{TARGET_IP}:{API_BACKEND_PORT}{NEW_CONFIDENCE_ENDPOINT}", json={}, timeout=3)
            if confidence_response.status_code == 200:
                print(f"[+] L'endpoint '{NEW_CONFIDENCE_ENDPOINT}' a répondu avec succès (200).")
            else:
                print(f"[-] L'endpoint '{NEW_CONFIDENCE_ENDPOINT}' a répondu avec une erreur : {confidence_response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"[-] Erreur lors du test direct de '{NEW_CONFIDENCE_ENDPOINT}': {e}")

else:
    print(f"[-] Le port {API_BACKEND_PORT} est fermé. Le service API Backend ne semble pas fonctionner.")

# 2. Diagnostic du Service Whisper Streaming
print(f"\n--- Service Whisper Streaming (Port {WHISPER_STREAMING_PORT}) ---")
if check_port(TARGET_IP, WHISPER_STREAMING_PORT):
    print(f"[+] Le port {WHISPER_STREAMING_PORT} est ouvert et le service répond.")
    
    # Puisqu'il s'agit d'un service de streaming (potentiellement WebSocket),
    # on vérifie simplement si une requête HTTP simple obtient une réponse (même une erreur)
    try:
        response = requests.get(f"http://{TARGET_IP}:{WHISPER_STREAMING_PORT}/", timeout=3)
        print(f"INFO: Le service a répondu à une requête HTTP avec le code {response.status_code}. Cela confirme qu'un service est à l'écoute.")
        
        expected = EXPECTED_ENDPOINTS[WHISPER_STREAMING_PORT]
        # On ne peut pas lister les routes, mais on peut tester l'endpoint directement
        session_response = requests.post(f"http://{TARGET_IP}:{WHISPER_STREAMING_PORT}{expected}", json={}, timeout=3)
        if session_response.status_code != 404:
             print(f"[+] L'endpoint '{expected}' semble exister (réponse: {session_response.status_code}).")
        else:
             print(f"[-] DIAGNOSTIC CLÉ: L'endpoint '{expected}' n'existe pas (404 Not Found).")

    except requests.exceptions.RequestException as e:
        print(f"[-] Le service sur le port {WHISPER_STREAMING_PORT} n'a pas répondu à une requête HTTP simple: {e}")
        print("   Cela peut être normal pour un service purement WebSocket, mais indique un problème si une API REST est attendue.")

else:
    print(f"[-] Le port {WHISPER_STREAMING_PORT} est fermé. Le service Whisper Streaming est INACTIF.")
    print("   Cause probable: Le service n'est pas démarré dans la configuration Docker Compose ou a échoué au démarrage.")

print("\n--- Fin du Diagnostic ---")