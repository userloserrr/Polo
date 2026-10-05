# Polo

Polo is an Android AI assistant with voice commands, multilingual support, model selection, image generation and face transfer module.

## Features
- Speech recognition
- Text-to-speech
- Multilingual support
- Multiple AI models
- Image generation
- Face transfer module
- Ollama/Claude backend

## Supported Models
- Ollama: gemma3:4b, gemma3:12b, gemma2:2b, llama2:7b, llama2:13b, mistral:7b, phi3:mini, deepseek-r1:7b
- Anthropic: claude-3-5-sonnet-20241022, claude-3-5-opus-20241022, claude-5-5-sonnet-20250514

## Backend
Run backend:
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export ANTHROPIC_API_KEY="your-key-here"
python server.py
```

## Android Studio
Open the project in Android Studio and run it.

## Backend URL
- http://10.0.2.2:8000/api/chat
- http://10.0.2.2:8000/api/image

## Build APK
```bash
./gradlew assembleRelease
```
