# Script de test de connectivité réseau PC ↔ mobile

## 1. Depuis le PC (Windows) :  
Ouvre PowerShell et exécute :

```powershell
# Test du port 8000 en écoute sur toutes les interfaces
netstat -ano | findstr :8000

# Affiche l’IP locale du PC
ipconfig

# Test ping vers le mobile (remplace 192.168.1.XX par l’IP de ton mobile)
ping 192.168.1.XX
```

## 2. Depuis le mobile :

### a) Application “Ping” (Android/iOS) :
- Installe une app “Ping” gratuite.
- Ping l’IP du PC (ex : 192.168.1.44).
- Note si le ping passe ou non.

### b) Application “HTTP Request” ou navigateur :
- Installe une app “HTTP Request” ou “REST Client” (ex : “RESTer”, “HTTP Request Shortcuts”).
- Fais une requête GET sur :  
  `http://192.168.1.44:8000/health`
- Note le code retour (200 attendu) ou l’erreur.

### c) Test navigateur :
- Ouvre Chrome/Firefox sur le mobile.
- Tape l’URL :  
  `http://192.168.1.44:8000/health`
- Si la page reste blanche, essaye en navigation privée ou avec un autre navigateur.

---

## 3. Si le ping ou la requête échoue :
- Désactive temporairement le firewall Windows (ou autorise Python/port 8000 en entrée).
- Vérifie que le PC et le mobile sont bien sur le même réseau WiFi (même plage d’IP).
- Vérifie que l’IP du PC n’a pas changé (`ipconfig`).

---

## 4. Pour aller plus loin :
- Depuis le PC, installe “Wireshark” ou “TCPView” pour voir si une connexion arrive du mobile.
- Depuis le mobile, essaye une app “Port Scanner” pour scanner le port 8000 du PC.

---

**Résume les résultats de chaque étape pour cibler le problème (connectivité, firewall, NAT, etc.).**