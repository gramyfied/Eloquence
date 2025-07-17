from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
import os

app = FastAPI()

class TTSRequest(BaseModel):
    text: str
    voice: str = "alloy"

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="OpenAI API key not configured")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    data = {
        "model": "tts-1",
        "input": request.text,
        "voice": request.voice,
    }

    try:
        response = requests.post("https://api.openai.com/v1/audio/speech", headers=headers, json=data, stream=True)
        response.raise_for_status()
        return response.content
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "ok"}