# Procédure de Capture des Logs en Direct (À suivre précisément)

Pour diagnostiquer le problème, nous avons absolument besoin de voir ce que fait l'agent PENDANT que vous utilisez l'application. Veuillez suivre ces étapes EXACTEMENT dans l'ordre :

1.  **Ouvrez deux terminaux (Terminal 1 et Terminal 2).**

2.  **Dans le Terminal 1,** assurez-vous d'être à la racine de votre projet Eloquence. Exécutez la commande suivante pour arrêter et supprimer tous les anciens conteneurs et repartir de zéro :
    ```bash
    docker compose down -v
    ```

3.  **Toujours dans le Terminal 1,** démarrez l'application :
    ```bash
    docker compose up
    ```
    Attendez que tous les services finissent de démarrer. Vous verrez beaucoup de lignes de log.

4.  **Passez maintenant au Terminal 2.** Exécutez la commande suivante. Elle se "connectera" au flux de logs de l'agent et attendra de nouvelles informations :
    ```bash
    docker compose logs -f --since 1m eloquence-agent-v1
    ```
    Il est normal que ce terminal n'affiche que peu de choses au début. Laissez-le tourner.

5.  **Maintenant, et seulement maintenant,** prenez votre application cliente (téléphone ou web) et **démarrez une session vocale** avec le coach.

6.  **Parlez dans l'application pendant au moins 10-15 secondes.** Pendant que vous parlez, observez le Terminal 2. Vous DEVRIEZ voir de nouvelles lignes apparaître, notamment celles contenant "INFO:root:..." que nous avons ajoutées.

7.  Après avoir parlé, **copiez l'intégralité du contenu du Terminal 2**, depuis le moment où vous avez lancé la commande jusqu'à la fin de votre interaction. C'est CE log qui est vital.