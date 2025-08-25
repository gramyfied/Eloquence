Développement local – Configuration réseau stable

1) Copier le fichier d'environnement
- Copiez `.env.example` en `.env` à la racine de `frontend/flutter_app/`
- Remplacez `MOBILE_HOST_IP` par l'IP locale de votre machine (ex: 192.168.1.X)

2) Ports à utiliser (Docker)
- LIVEKIT_URL → ws://IP:8780 (via HAProxy)
- LIVEKIT_TOKEN_URL → http://IP:8804 (service token)
- Vérifier que ces ports sont ouverts (Windows Firewall)

3) Vérifier la connectivité (PowerShell)
```
Test-NetConnection IP -Port 8780
Test-NetConnection IP -Port 8804
```

4) Pourquoi cette config est stable
- Le code lit les URLs dans `.env` et remplace `localhost` intelligemment en debug
- Aucun IP n'est hardcodé en dur; un `git pull` ne casse pas la config locale

5) Astuce
- Si vous changez de réseau/IP, modifiez uniquement `.env`

