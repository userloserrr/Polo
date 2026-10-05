from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os, requests
from typing import Optional

app = FastAPI(title="Polo AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "gemma3:4b")

MODEL_CATALOG = {
    "gemma3:4b": {"provider": "ollama", "name": "Gemma 3 4B"},
    "gemma3:12b": {"provider": "ollama", "name": "Gemma 3 12B"},
    "gemma2:2b": {"provider": "ollama", "name": "Gemma 2 2B"},
    "llama2:7b": {"provider": "ollama", "name": "Llama 2 7B"},
    "llama2:13b": {"provider": "ollama", "name": "Llama 2 13B"},
    "mistral:7b": {"provider": "ollama", "name": "Mistral 7B"},
    "phi3:mini": {"provider": "ollama", "name": "Phi 3 Mini"},
    "deepseek-r1:7b": {"provider": "ollama", "name": "DeepSeek R1 7B"},
    "claude-3-5-sonnet-20241022": {"provider": "anthropic", "name": "Claude 3.5 Sonnet"},
    "claude-3-5-opus-20241022": {"provider": "anthropic", "name": "Claude 3.5 Opus"},
    "claude-5-5-sonnet-20250514": {"provider": "anthropic", "name": "Claude 5.5 Sonnet"},
}

class ChatRequest(BaseModel):
    message: str
    model: Optional[str] = None
    language: Optional[str] = "tr"
    temperature: Optional[float] = 0.7
    top_p: Optional[float] = 0.9

class ImageRequest(BaseModel):
    prompt: str
    style: Optional[str] = "photo-realistic"

class ChatResponse(BaseModel):
    reply: str
    model: str
    provider: str
    model_name: Optional[str] = None

class ImageResponse(BaseModel):
    image_url: str
    prompt: str

@app.get("/")
async def root():
    return {
        "status": "Polo backend running",
        "default_model": DEFAULT_MODEL,
        "models_count": len(MODEL_CATALOG),
        "ollama_available": True,
        "anthropic_available": bool(ANTHROPIC_API_KEY)
    }

@app.get("/models")
async def list_models():
    models_list = []
    for model_id, model_info in MODEL_CATALOG.items():
        models_list.append({
            "id": model_id,
            "name": model_info.get("name", model_id),
            "provider": model_info["provider"]
        })
    return {"models": models_list, "total": len(models_list)}

@app.get("/api/health")
async def health():
    result = {"status": "healthy", "backends": {}}
    try:
        r = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        r.raise_for_status()
        data = r.json()
        result["backends"]["ollama"] = {"status": "healthy", "models": [m.get("name") for m in data.get("models", [])]}
    except Exception as e:
        result["backends"]["ollama"] = {"status": "down", "error": str(e)}

    if ANTHROPIC_API_KEY:
        result["backends"]["anthropic"] = {"status": "healthy"}
    else:
        result["backends"]["anthropic"] = {"status": "not_configured"}
    return result

@app.post("/api/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    model = req.model or DEFAULT_MODEL
    if model not in MODEL_CATALOG:
        raise HTTPException(status_code=400, detail=f"Model {model} not supported")

    model_meta = MODEL_CATALOG[model]
    provider = model_meta["provider"]
    model_name = model_meta.get("name", model)

    if provider == "anthropic":
        if not ANTHROPIC_API_KEY:
            return ChatResponse(
                reply="Anthropic API key not configured. Set ANTHROPIC_API_KEY environment variable.",
                model=model,
                provider="anthropic",
                model_name=model_name
            )
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
            response = client.messages.create(
                model=model,
                max_tokens=1024,
                temperature=req.temperature,
                messages=[{"role": "user", "content": req.message}]
            )
            return ChatResponse(
                reply=response.content[0].text,
                model=model,
                provider="anthropic",
                model_name=model_name
            )
        except Exception as e:
            return ChatResponse(
                reply=f"Claude error: {str(e)}",
                model=model,
                provider="anthropic",
                model_name=model_name
            )

    payload = {
        "model": model,
        "prompt": req.message,
        "stream": False,
        "options": {
            "temperature": req.temperature,
            "top_p": req.top_p,
            "num_predict": 256
        }
    }
    try:
        r = requests.post(f"{OLLAMA_URL}/api/generate", json=payload, timeout=180)
        r.raise_for_status()
        data = r.json()
        return ChatResponse(
            reply=data.get("response", "Cevap alınamadı."),
            model=model,
            provider="ollama",
            model_name=model_name
        )
    except Exception as e:
        return ChatResponse(
            reply=f"Ollama error: {str(e)}",
            model=model,
            provider="ollama",
            model_name=model_name
        )

@app.post("/api/image", response_model=ImageResponse)
async def image(req: ImageRequest):
    prompt = req.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt boş olamaz.")
    encoded = prompt.replace(" ", "%20")
    return ImageResponse(image_url=f"https://image.pollinations.ai/prompt/{encoded}", prompt=prompt)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
