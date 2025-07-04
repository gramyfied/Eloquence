# Diagnostic et Correction de l'Erreur Pydantic `ChatMessage`

## Contexte de l'Erreur

L'application Eloquence rencontre une erreur persistante liée à la validation Pydantic du champ `content` de la classe `livekit.agents.llm.ChatMessage`. Malgré les tentatives précédentes de formater le contenu en `[{"type": "text", "text": "..."}]`, le système LiveKit continue de générer des erreurs telles que :

```
5 validation errors for ChatMessage
content.0.ImageContent.type
  Input should be 'image_content' [type=literal_error, input_value='text', input_type=str]
content.0.ImageContent.image
  Field required [type=missing, input_value={'type': 'text', 'text': ...}, input_type=dict]
content.0.AudioContent.type
  Input should be 'audio_content' [type=literal_error, input_value='text', input_type=str]
content.0.AudioContent.frame
  Field required [type=missing, input_value={'type': 'text', 'text': ...}, input_type=dict]
content.0.str
  Input should be a valid string [type=string_type, input_value={'type': 'text', 'text': ...}, input_type=dict]
```

Cela indique que Pydantic tente de désérialiser le contenu texte en tant que `ImageContent` ou `AudioContent` (qui ont des champs obligatoires comme `image` ou `frame`) avant de reconnaître le format `TextContent` correct, ou que la spécification du `ChatMessage` dans la version actuelle de `livekit.agents` a une particularité.

## Parties du Code LLM où l'Erreur se Produit

L'erreur est principalement rencontrée lors de la préparation des messages pour le service LLM, spécifiquement au moment où le `llm.ChatMessage` est validé. Les points clés où les `ChatMessage` sont construites ou traitées sont :

1.  **Dans `_call_llm_service` (lignes 559-566 de `real_time_voice_agent_force_audio.py`)**:
    Initialisation des messages système et utilisateur avant le premier appel au LLM.

    ```python
    # services/api-backend/services/real_time_voice_agent_force_audio.py
    # ...
    553 |             # 1. Créer un ChatContext compatible avec le format liste requis
    554 |             chat_ctx = llm.ChatContext()
    555 |             
    556 |             # CORRECTION: Créer les messages avec le format LISTE requis par Pydantic validation
    557 |             system_msg = llm.ChatMessage(
    558 |                 role="system",
    559 |                 content=[{"type": "text", "text": "Tu es un coach vocal expert. Sois concis et encourageant."}]
    560 |             )
    561 |             user_msg = llm.ChatMessage(
    562 |                 role="user",
    563 |                 content=[{"type": "text", "text": transcription}]
    564 |             )
    565 |             
    566 |             # Ajouter les messages au contexte
    567 |             chat_ctx.messages = [system_msg, user_msg]
    # ...
    ```

2.  **Dans `process_with_llm` (lignes 1787-1791 de `real_time_voice_agent_force_audio.py`)**:
    Fonction utilitaire qui prépare également les messages pour le LLM dans le pipeline VAD -> STT -> LLM.

    ```python
    # services/api-backend/services/real_time_voice_agent_force_audio.py
    # ...
    1784 |         chat_ctx = agents.llm.ChatContext()
    1785 |         
    1786 |         # CORRECTION: Créer les messages avec le format LISTE requis par Pydantic validation
    1787 |         system_msg = agents.llm.ChatMessage(role="system", content=[{"type": "text", "text": "Tu es un assistant vocal. Réponds de manière concise et naturelle."}])
    1788 |         user_msg = agents.llm.ChatMessage(role="user", content=[{"type": "text", "text": text}])
    1789 |         
    1790 |         chat_ctx.messages = [system_msg, user_msg]
    # ...
    ```

3.  **Dans `CustomLLM.chat()` (lignes 890-906 de `real_time_voice_agent_force_audio.py`)**:
    La logique d'adaptation du contenu des messages est appliquée ici, où les `ChatMessage` transitent avant d'être envoyées au fournisseur Mistral. C'est visiblement là que les erreurs de validation Pydantic se manifestent, indiquant que même après cette conversion, le format final n'est pas celui attendu par la validation interne de `livekit.agents`.

    ```python
    # services/api-backend/services/real_time_voice_agent_force_audio.py
    # ...
    888 |         messages_from_ctx = []
    889 |         if hasattr(chat_ctx, 'messages'):
    890 |             for msg in chat_ctx.messages:
    891 |                 # Vérifier si msg.content est une chaîne ou une liste de dictionnaires
    892 |                 if isinstance(msg.content, str):
    893 |                     # Si c'est une chaîne, la transformer en format [{'type': 'text', 'text': '...'}]
    894 |                     processed_content = [{"type": "text", "text": msg.content}]
    895 |                 elif isinstance(msg.content, list):
    896 |                     # Si c'est une liste, vérifier si les éléments sont des dictionnaires valides
    897 |                     # Pour simplifier, nous allons supposer que c'est le format correct désiré
    898 |                     processed_content = msg.content
    899 |                 else:
    900 |                     # Gérer les cas inattendus, par exemple en retournant une chaîne vide ou en loggant une erreur
    901 |                     logger.warning(f"⚠️ Type de contenu inattendu pour ChatMessage: {type(msg.content)}")
    902 |                     processed_content = [{"type": "text", "text": str(msg.content)}] # Convertir en chaîne au cas où
    903 | 
    904 |                 messages_from_ctx.append({"role": str(msg.role), "content": processed_content})
    # ...
    ```

## Configuration du Service LLM (Mistral)

Le service LLM utilise l'API Mistral. Les paramètres de configuration sont définis via des variables d'environnement et utilisés dans la classe `CustomLLMStream`:

```python
# services/api-backend/services/real_time_voice_agent_force_audio.py
# ...
77 | MISTRAL_BASE_URL = os.environ.get("MISTRAL_BASE_URL")
78 | MISTRAL_API_KEY = os.environ.get("MISTRAL_API_KEY")
79 | MISTRAL_MODEL = os.environ.get("MISTRAL_MODEL", "mistral-nemo-instruct-2407")
# ...
1024 |             data = {
1025 |                 "model": MISTRAL_MODEL,
1026 |                 "messages": self._messages,
1027 |                 "temperature": self._temperature,
1028 |                 "stream": True
1029 |             }
# ...
```

## Formatage des Messages avant Envoi au LLM

L'objectif est d'assurer que le contenu des messages envoyés au LLM est toujours une liste de dictionnaires, où chaque dictionnaire spécifie le type de contenu (ex. `text`) et sa valeur. Le format attendu pour le contenu textuel est `[{"type": "text", "text": "Votre texte ici"}]`.

## Conversion STT → LLM

Le flux de conversion de la transcription (Speech-to-Text) vers l'appel au modèle de langage (LLM) est géré comme suit :

1.  **Dans `_process_chunk_with_whisper`**:
    Après que Whisper ait transcris l'audio (lignes 451-477), la transcription est passée à `_call_llm_service` (l. 495).

    ```python
    # services/api-backend/services/real_time_voice_agent_force_audio.py
    # ...
    495 |                         llm_response = await self._call_llm_service(transcription)
    # ...
    ```

2.  **Dans `process_with_llm`**:
    Cette fonction est appelée quand le VAD détecte la fin d'une parole. Elle prend la transcription et crée un `ChatContext` pour le LLM.

    ```python
    # services/api-backend/services/real_time_voice_agent_force_audio.py
    # ...
    1695 |                                 transcription = await transcribe_audio_with_whisper(wav_data)
    1696 |                                 
    1697 |                                 if transcription and transcription.strip():
    1698 |                                     logger.info(f"📝 [STT] Transcription: {transcription}")
    1699 |                                     
    1700 |                                     # Traitement LLM
    1701 |                                     response = await process_with_llm(transcription, llm)
    # ...
    ```

## Analyse Approfondie de l'Erreur Pydantic Persistante

L'erreur indiquant que Pydantic attend `'image_content'` ou `'audio_content'` mais reçoit `'text'` pour le champ `content.0.type` suggère un problème fondamental avec la manière dont `livekit.agents.llm.ChatMessage` (et ses composants `llm.Content`, `llm.TextContent`, `llm.ImageContent`, etc.) gère la validation des types.

**Hypothèse :** Il est probable que l'implémentation de Pydantic dans la version de `livekit.agents` utilisée tente de valider les éléments de `content` contre une union de types (`Union[TextContent, ImageContent, AudioContent, ...]`). Si les types `ImageContent` ou `AudioContent` sont prioritaires dans cette union, ou si leur validation est moins permissive, cela peut provoquer l'échec. Notre format `{"type": "text", "text": "..."}` devrait correspondre à `TextContent`, mais la validation échoue comme si elle forçait un autre type compatible.

## Proposition de Correction

Puisque la modification directe du code de `livekit.agents` n'est pas possible, la solution doit résider dans des ajustements de l'appel à la bibliothèque. Il y a plusieurs pistes :

1.  **Vérifier la version de `livekit.agents`**: S'assurer que nous utilisons une version stable et bien documentée, et rechercher spécifiquement tout `breaking change` concernant `llm.ChatMessage` et ses types de contenu. Une mise à jour ou un retour à une version précédente pourrait résoudre le problème si c'est un bug dans une version spécifique.

2.  **Double-vérifier les types `livekit.agents.llm`**: Examiner si des utilitaires sont fournis par `livekit.agents` pour construire ces messages de manière plus robuste ou si un format différent (ou une encapsulation) est nécessaire. Une introspection du module `livekit.agents.llm` dans un environnement Python peut révéler la structure exacte.

3.  **Encapsuler le contenu de manière plus explicite (si le SDK le permet)**: Si `llm.ChatMessage` a une méthode `add_text` ou équivalente, l'utiliser pourrait contourner la validation directe de `content`. Cependant, l'inspection montre que `ChatMessage` est un modèle Pydantic où `content` est un champ direct.

4.  **Considérer un contournement temporaire**: Si le temps presse et qu'aucune solution directe n'est trouvée, un contournement au niveau de l'API Mistral pourrait être d'envoyer un simple string comme contenu au lieu de la liste de dictionnaires, si l'API Mistral le permet, mais cela irait à l'encontre de la spécification de `livekit.agents`.

**Action Recommandée :**

La première étape la plus logique est de tenter de forcer la validation des types de contenu dans `CustomLLM.chat()` en utilisant explicitement les classes de types de contenu de LiveKit. Si `livekit.agents.llm.TextContent` est réellement la classe attendue, l'instancier directement pourrait résoudre le problème.

```python
# services/api-backend/services/real_time_voice_agent_force_audio.py
# ... dans CustomLLM.chat()
                for msg in chat_ctx.messages:
                    processed_content = []
                    if isinstance(msg.content, str):
                        # Créer explicitement un TextContent de livekit.agents.llm
                        processed_content = [llm.TextContent(text=msg.content)]
                    elif isinstance(msg.content, list):
                        for item in msg.content:
                            if isinstance(item, dict) and item.get("type") == "text":
                                processed_content.append(llm.TextContent(text=item["text"]))
                            # Ajouter la gestion d'autres types si nécessaire (ImageContent, AudioContent)
                            # else: laisser tel quel ou logguer l'erreur
                    else:
                        logger.warning(f"⚠️ Type de contenu inattendu pour ChatMessage: {type(msg.content)}")
                        processed_content = [llm.TextContent(text=str(msg.content))] # Fallback

                    messages_from_ctx.append({"role": str(msg.role), "content": processed_content})
# ...
```

Et de même dans les fonctions `_call_llm_service` et `process_with_llm` où `llm.ChatMessage` est instancié :

```python
# services/api-backend/services/real_time_voice_agent_force_audio.py
# ... dans _call_llm_service et process_with_llm
            system_msg = llm.ChatMessage(
                role="system",
                content=[llm.TextContent(text="Tu es un coach vocal expert. Sois concis et encourageant.")]
            )
            user_msg = llm.ChatMessage(
                role="user",
                content=[llm.TextContent(text=transcription)]
            )
# ...
```

Cette approche tente de fournir à Pydantic l'objet de type `TextContent` *directement* plutôt qu'un dictionnaire qu'il doit tenter de désérialiser en `TextContent`. Si le problème vient de la désérialisation trop "intelligente" de Pydantic, cela pourrait le résoudre.

Après l'application de ce changement, il sera nécessaire de reconstruire le conteneur Docker avec `docker-compose build --no-cache` et de redémarrer le service pour que les modifications prennent effet. Il est ensuite impératif de surveiller attentivement les logs pour valider la correction de l'erreur Pydantic.