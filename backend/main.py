from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import os
from typing import List, Optional, Dict, Any
import random
import time

# Configuration de l'application
app = FastAPI(
    title="Backend API Eloquence",
    description="API REST complète pour l'application Flutter Eloquence",
    version="1.0.0"
)

# Configuration CORS pour permettre les requêtes du frontend Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modèles Pydantic
class Item(BaseModel):
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    price: float

class User(BaseModel):
    id: Optional[int] = None
    username: str
    email: str

class Exercise(BaseModel):
    id: Optional[int] = None
    title: str
    description: str
    type: str
    difficulty: str
    duration: int  # en minutes

class ConfidenceSession(BaseModel):
    id: Optional[int] = None
    scenario: str
    difficulty: str
    duration: int
    score: Optional[float] = None

class Story(BaseModel):
    id: Optional[int] = None
    title: str
    content: str
    genre: str
    difficulty: str

# Base de données simulée (en mémoire)
items_db = []
users_db = []
exercises_db = [
    Exercise(id=1, title="Respiration Dragon", description="Exercice de respiration pour améliorer la confiance", type="breathing", difficulty="facile", duration=5),
    Exercise(id=2, title="Virelangues", description="Exercices d'articulation avec des virelangues", type="articulation", difficulty="moyen", duration=10),
    Exercise(id=3, title="Présentation Publique", description="Simulation de présentation devant un public", type="presentation", difficulty="difficile", duration=15),
    Exercise(id=4, title="Conversation Spontanée", description="Dialogue improvisé avec l'IA", type="conversation", difficulty="moyen", duration=8),
]

confidence_sessions_db = []
stories_db = [
    Story(id=1, title="L'Aventure du Petit Dragon", content="Il était une fois un petit dragon qui avait peur de voler...", genre="aventure", difficulty="facile"),
    Story(id=2, title="Le Mystère de la Forêt Enchantée", content="Dans une forêt mystérieuse, un jeune explorateur découvre...", genre="mystère", difficulty="moyen"),
]

# Routes de base
@app.get("/")
async def root():
    return {"message": "API Backend Python - Déployée avec succès !"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "backend-api"}

# Routes pour les items
@app.get("/api/items", response_model=List[Item])
async def get_items():
    return items_db

@app.post("/api/items", response_model=Item)
async def create_item(item: Item):
    item.id = len(items_db) + 1
    items_db.append(item)
    return item

@app.get("/api/items/{item_id}", response_model=Item)
async def get_item(item_id: int):
    for item in items_db:
        if item.id == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item non trouvé")

@app.put("/api/items/{item_id}", response_model=Item)
async def update_item(item_id: int, updated_item: Item):
    for i, item in enumerate(items_db):
        if item.id == item_id:
            updated_item.id = item_id
            items_db[i] = updated_item
            return updated_item
    raise HTTPException(status_code=404, detail="Item non trouvé")

@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    for i, item in enumerate(items_db):
        if item.id == item_id:
            del items_db[i]
            return {"message": "Item supprimé"}
    raise HTTPException(status_code=404, detail="Item non trouvé")

# Routes pour les utilisateurs
@app.get("/api/users", response_model=List[User])
async def get_users():
    return users_db

@app.post("/api/users", response_model=User)
async def create_user(user: User):
    user.id = len(users_db) + 1
    users_db.append(user)
    return user

# Routes pour les exercices
@app.get("/api/exercises", response_model=List[Exercise])
async def get_exercises():
    """Récupère la liste de tous les exercices disponibles"""
    return exercises_db

@app.get("/api/exercises/{exercise_id}", response_model=Exercise)
async def get_exercise(exercise_id: int):
    """Récupère un exercice spécifique par son ID"""
    for exercise in exercises_db:
        if exercise.id == exercise_id:
            return exercise
    raise HTTPException(status_code=404, detail="Exercice non trouvé")

@app.get("/api/exercises/type/{exercise_type}", response_model=List[Exercise])
async def get_exercises_by_type(exercise_type: str):
    """Récupère les exercices par type (breathing, articulation, presentation, conversation)"""
    filtered_exercises = [ex for ex in exercises_db if ex.type == exercise_type]
    return filtered_exercises

# Routes pour Confidence Boost
@app.get("/api/confidence-boost")
async def get_confidence_boost_info():
    """Informations sur le module Confidence Boost"""
    return {
        "module": "confidence-boost",
        "status": "active",
        "available_scenarios": [
            "Entretien d'embauche",
            "Présentation en public",
            "Conversation sociale",
            "Négociation commerciale",
            "Débat argumenté"
        ],
        "difficulty_levels": ["facile", "moyen", "difficile", "expert"]
    }

@app.post("/api/confidence-boost/session", response_model=ConfidenceSession)
async def create_confidence_session(session: ConfidenceSession):
    """Crée une nouvelle session de confidence boost"""
    session.id = len(confidence_sessions_db) + 1
    confidence_sessions_db.append(session)
    return session

@app.get("/api/confidence-boost/sessions", response_model=List[ConfidenceSession])
async def get_confidence_sessions():
    """Récupère toutes les sessions de confidence boost"""
    return confidence_sessions_db

@app.post("/api/confidence-boost/evaluate")
async def evaluate_confidence_performance(data: Dict[str, Any]):
    """Évalue la performance d'une session de confidence boost"""
    # Simulation d'évaluation IA
    score = random.uniform(0.6, 0.95)
    feedback = [
        "Excellente articulation",
        "Bon rythme de parole",
        "Confiance en progression"
    ]
    
    return {
        "score": round(score, 2),
        "feedback": feedback,
        "recommendations": [
            "Continuez à pratiquer la respiration",
            "Travaillez sur le contact visuel"
        ],
        "next_level": "moyen" if score > 0.8 else "facile"
    }

# Routes pour Story Generator
@app.get("/api/story-generator")
async def get_story_generator_info():
    """Informations sur le module Story Generator"""
    return {
        "module": "story-generator",
        "status": "active",
        "available_genres": ["aventure", "mystère", "fantastique", "science-fiction", "comédie"],
        "difficulty_levels": ["facile", "moyen", "difficile"],
        "story_count": len(stories_db)
    }

@app.get("/api/story-generator/stories", response_model=List[Story])
async def get_stories():
    """Récupère toutes les histoires disponibles"""
    return stories_db

@app.post("/api/story-generator/generate")
async def generate_story(request: Dict[str, Any]):
    """Génère une nouvelle histoire basée sur les paramètres"""
    genre = request.get("genre", "aventure")
    difficulty = request.get("difficulty", "facile")
    theme = request.get("theme", "amitié")
    
    # Simulation de génération d'histoire
    story_templates = {
        "aventure": f"Dans un monde lointain, un héros courageux part à l'aventure pour découvrir {theme}...",
        "mystère": f"Un mystère étrange entoure {theme}, et seul un détective astucieux peut le résoudre...",
        "fantastique": f"Dans un royaume magique, {theme} détient le pouvoir de changer le destin...",
    }
    
    new_story = Story(
        id=len(stories_db) + 1,
        title=f"Histoire de {theme.title()}",
        content=story_templates.get(genre, story_templates["aventure"]),
        genre=genre,
        difficulty=difficulty
    )
    
    stories_db.append(new_story)
    
    return {
        "story": new_story,
        "generation_time": round(random.uniform(2.0, 5.0), 1),
        "word_count": len(new_story.content.split()),
        "estimated_reading_time": f"{random.randint(3, 8)} minutes"
    }

@app.post("/api/story-generator/analyze")
async def analyze_narration(data: Dict[str, Any]):
    """Analyse la narration d'une histoire"""
    # Simulation d'analyse vocale
    return {
        "pronunciation_score": round(random.uniform(0.7, 0.95), 2),
        "fluency_score": round(random.uniform(0.6, 0.9), 2),
        "expression_score": round(random.uniform(0.65, 0.88), 2),
        "overall_score": round(random.uniform(0.7, 0.9), 2),
        "feedback": [
            "Bonne prononciation générale",
            "Rythme approprié pour l'histoire",
            "Expression émotionnelle présente"
        ],
        "improvements": [
            "Variez davantage l'intonation",
            "Marquez plus les pauses"
        ]
    }

# Routes additionnelles pour l'écosystème Eloquence
@app.get("/api/stats")
async def get_user_stats():
    """Statistiques globales de l'utilisateur"""
    return {
        "total_exercises": len(exercises_db),
        "completed_sessions": len(confidence_sessions_db),
        "stories_read": len(stories_db),
        "total_practice_time": random.randint(120, 500),  # en minutes
        "confidence_level": round(random.uniform(0.6, 0.9), 2),
        "favorite_exercise_type": "breathing"
    }

@app.get("/api/leaderboard")
async def get_leaderboard():
    """Classement des utilisateurs (simulé)"""
    return {
        "top_users": [
            {"username": "EloquentMaster", "score": 950, "level": "Expert"},
            {"username": "SpeechPro", "score": 890, "level": "Avancé"},
            {"username": "ConfidentSpeaker", "score": 820, "level": "Intermédiaire"},
            {"username": "Vous", "score": random.randint(600, 800), "level": "Intermédiaire"}
        ],
        "your_rank": random.randint(15, 50),
        "total_users": random.randint(100, 500)
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
