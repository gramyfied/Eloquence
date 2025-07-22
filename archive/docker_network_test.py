import socket
import os

def check_connection(host, port):
    print(f"--- Test de connexion pour {host}:{port} ---")
    try:
        # Tenter de résoudre le nom d'hôte
        ip = socket.gethostbyname(host)
        print(f"[+] DNS resolu: {host} -> {ip}")

        # Tenter une connexion TCP
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()

        if result == 0:
            print(f"[+] Port TCP {port} accessible.")
            return True
        else:
            print(f"[x] Port TCP {port} NON accessible (code: {result}).")
            return False
    except socket.gaierror:
        print(f"[x] Erreur DNS: Impossible de resoudre le nom d'hote '{host}'.")
        return False
    except Exception as e:
        print(f"[x] Erreur inattendue: {e}")
        return False

if __name__ == "__main__":
    print("=== DEBUT DU TEST DE RESEAU DOCKER ===")
    
    # Test 1: Nom de service Docker
    livekit_host_docker = "livekit"
    livekit_port = 7880
    print(f"\n[1] Test avec le nom de service Docker '{livekit_host_docker}'...")
    check_connection(livekit_host_docker, livekit_port)

    # Test 2: Adresse IP locale (ne devrait pas fonctionner depuis le conteneur)
    livekit_host_local = "192.168.1.44"
    print(f"\n[2] Test avec l'adresse IP locale '{livekit_host_local}'...")
    check_connection(livekit_host_local, livekit_port)
    
    # Test 3: Localhost (ne devrait pas fonctionner)
    livekit_host_localhost = "localhost"
    print(f"\n[3] Test avec 'localhost'...")
    check_connection(livekit_host_localhost, livekit_port)

    print("\n=== FIN DU TEST DE RESEAU DOCKER ===")
