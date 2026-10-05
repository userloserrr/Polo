#!/usr/bin/env bash
set -e

mkdir -p PoloApp/backend PoloApp/app/src/main/java/com/polo/app PoloApp/app/src/main/res/values PoloApp/app/src/test/java/com/polo/app PoloApp/.github/workflows

cat > PoloApp/settings.gradle.kts <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "PoloApp"
include(":app")
EOF

cat > PoloApp/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
EOF

cat > PoloApp/gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
EOF

cat > PoloApp/.gitignore <<'EOF'
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
EOF

cat > PoloApp/README.md <<'EOF'
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
EOF

cat > PoloApp/.github/workflows/build-apk.yml <<'EOF'
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - name: Grant execute permission
        run: chmod +x ./gradlew

      - name: Build APK
        run: ./gradlew assembleRelease
EOF

cat > PoloApp/backend/requirements.txt <<'EOF'
fastapi==0.115.0
uvicorn[standard]==0.30.6
pydantic==2.9.2
requests==2.32.2
python-dotenv==1.0.1
anthropic>=0.37.1
EOF

cat > PoloApp/backend/.env.example <<'EOF'
OLLAMA_URL=http://localhost:11434
ANTHROPIC_API_KEY=your-claude-api-key-here
DEFAULT_MODEL=gemma3:4b
EOF

cat > PoloApp/backend/server.py <<'EOF'
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
EOF

cat > PoloApp/backend/run.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
python -m venv .venv 2>/dev/null || true
source .venv/bin/activate
pip install -r backend/requirements.txt
python backend/server.py
EOF

cat > PoloApp/backend/run.bat <<'EOF'
@echo off
cd /d "%~dp0.."
python -m venv .venv 2>nul
call .venv\Scripts\activate
pip install -r backend\requirements.txt
python backend\server.py
EOF

cat > PoloApp/app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.polo.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.polo.app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    implementation("androidx.activity:activity-compose:1.9.1")
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("io.coil-kt:coil-compose:2.7.0")
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("com.google.mlkit:face-detection:16.1.6")
    testImplementation("junit:junit:4.13.2")
}
EOF

cat > PoloApp/app/proguard-rules.pro <<'EOF'
-keep class com.polo.app.** { *; }
EOF

cat > PoloApp/app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:theme="@style/Theme.Material3.DayNight.NoActionBar"
        tools:targetApi="31">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
EOF

cat > PoloApp/app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">Polo</string>
</resources>
EOF

cat > PoloApp/app/src/main/java/com/polo/app/ApiModels.kt <<'EOF'
package com.polo.app

data class ChatRequest(
    val message: String,
    val model: String = "claude-5-5-sonnet-20250514",
    val language: String = "tr",
    val temperature: Double = 0.7,
    val top_p: Double = 0.9
)

data class ChatResponse(
    val reply: String,
    val model: String,
    val provider: String,
    val model_name: String? = null
)

data class ImageRequest(
    val prompt: String,
    val style: String = "realistic"
)

data class ImageResponse(
    val image_url: String,
    val prompt: String
)

data class ModelInfo(
    val id: String,
    val name: String,
    val provider: String
)
EOF

cat > PoloApp/app/src/main/java/com/polo/app/ApiClient.kt <<'EOF'
package com.polo.app

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

interface PoloApiService {
    @POST("api/chat")
    suspend fun chat(@Body request: ChatRequest): ChatResponse

    @POST("api/image")
    suspend fun image(@Body request: ImageRequest): ImageResponse

    @GET("models")
    suspend fun listModels(): Map<String, Any>
}

object ApiClient {
    private const val BASE_URL = "http://10.0.2.2:8000/"

    val service: PoloApiService by lazy {
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        }
        val client = OkHttpClient.Builder()
            .addInterceptor(logging)
            .build()

        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(PoloApiService::class.java)
    }
}
EOF

cat > PoloApp/app/src/main/java/com/polo/app/ModelManager.kt <<'EOF'
package com.polo.app

object ModelManager {
    fun getSupportedModels(): List<String> = listOf(
        "gemma3:4b",
        "gemma3:12b",
        "gemma2:2b",
        "llama2:7b",
        "llama2:13b",
        "mistral:7b",
        "phi3:mini",
        "deepseek-r1:7b",
        "claude-3-5-sonnet-20241022",
        "claude-3-5-opus-20241022",
        "claude-5-5-sonnet-20250514"
    )

    fun getModelDisplayName(modelId: String): String = when (modelId) {
        "gemma3:4b" -> "Gemma 3 4B"
        "gemma3:12b" -> "Gemma 3 12B"
        "gemma2:2b" -> "Gemma 2 2B"
        "llama2:7b" -> "Llama 2 7B"
        "llama2:13b" -> "Llama 2 13B"
        "mistral:7b" -> "Mistral 7B"
        "phi3:mini" -> "Phi 3 Mini"
        "deepseek-r1:7b" -> "DeepSeek R1 7B"
        "claude-3-5-sonnet-20241022" -> "Claude 3.5 Sonnet"
        "claude-3-5-opus-20241022" -> "Claude 3.5 Opus"
        "claude-5-5-sonnet-20250514" -> "Claude 5.5 Sonnet"
        else -> modelId
    }
}
EOF

cat > PoloApp/app/src/main/java/com/polo/app/FaceTransfer.kt <<'EOF'
package com.polo.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint

object FaceTransfer {
    fun overlayFace(target: Bitmap, sourceFace: Bitmap): Bitmap {
        val output = target.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(output)
        val paint = Paint()
        canvas.drawBitmap(sourceFace, 0f, 0f, paint)
        return output
    }
}
EOF

cat > PoloApp/app/src/main/java/com/polo/app/VoiceManager.kt <<'EOF'
package com.polo.app

import android.content.Context
import android.content.Intent
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import java.util.Locale

class VoiceManager(private val context: Context) {
    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var currentLanguage = "tr"

    init {
        initTTS()
        initSpeechRecognizer()
    }

    private fun initTTS() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                setLanguage(currentLanguage)
            }
        }
    }

    private fun initSpeechRecognizer() {
        if (SpeechRecognizer.isRecognitionAvailable(context)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
        }
    }

    fun startListening(onResult: (String) -> Unit) {
        val intent = Intent(android.speech.RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(android.speech.RecognizerIntent.EXTRA_LANGUAGE_MODEL, android.speech.RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(android.speech.RecognizerIntent.EXTRA_LANGUAGE, if (currentLanguage == "tr") "tr_TR" else "en_US")
        intent.putExtra(android.speech.RecognizerIntent.EXTRA_MAX_RESULTS, 1)

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(bundle: android.os.Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(v: Float) {}
            override fun onBufferReceived(bytes: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onError(error: Int) {}
            override fun onResults(bundle: android.os.Bundle?) {
                val matches = bundle?.getStringArrayList(android.speech.SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    onResult(matches[0])
                }
            }
            override fun onPartialResults(bundle: android.os.Bundle?) {}
            override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
        })

        speechRecognizer?.startListening(intent)
    }

    fun stopListening() {
        speechRecognizer?.stopListening()
    }

    fun speak(text: String) {
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "polo_tts")
    }

    fun setLanguage(language: String) {
        currentLanguage = language
        val locale = if (language == "tr") Locale("tr") else Locale.ENGLISH
        textToSpeech?.language = locale
    }

    fun release() {
        speechRecognizer?.destroy()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
    }
}
EOF

cat > PoloApp/app/src/main/java/com/polo/app/MainActivity.kt <<'EOF'
package com.polo.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private var voiceManager: VoiceManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        voiceManager = VoiceManager(this)
        requestMicrophonePermission()
        setContent { PoloApp(voiceManager!!) }
    }

    private fun requestMicrophonePermission() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 1)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        voiceManager?.release()
    }
}

@Composable
fun PoloApp(voiceManager: VoiceManager) {
    val scope = rememberCoroutineScope()
    var input by remember { mutableStateOf("") }
    var language by remember { mutableStateOf("tr") }
    var selectedModel by remember { mutableStateOf("claude-5-5-sonnet-20250514") }
    var messages by remember { mutableStateOf(listOf("Polo hazır. Sesli komut ve Claude 5.5 Sonnet hazır.")) }
    var generatedImage by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var isListening by remember { mutableStateOf(false) }
    var expandedModels by remember { mutableStateOf(false) }

    LaunchedEffect(language) {
        voiceManager.setLanguage(language)
    }

    MaterialTheme {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF0F172A))
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Polo", color = Color.White, fontSize = 30.sp)
                Row {
                    OutlinedButton(onClick = { language = "tr" }) { Text("TR") }
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedButton(onClick = { language = "en" }) { Text("EN") }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Box(modifier = Modifier.fillMaxWidth()) {
                OutlinedButton(
                    onClick = { expandedModels = !expandedModels },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(ModelManager.getModelDisplayName(selectedModel), color = Color.White)
                }

                DropdownMenu(
                    expanded = expandedModels,
                    onDismissRequest = { expandedModels = false },
                    modifier = Modifier.fillMaxWidth(0.9f)
                ) {
                    ModelManager.getSupportedModels().forEach { model ->
                        DropdownMenuItem(
                            text = { Text(ModelManager.getModelDisplayName(model)) },
                            onClick = {
                                selectedModel = model
                                expandedModels = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(messages) { msg ->
                    Surface(
                        color = Color(0xFF1F2937),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(msg, color = Color.White, modifier = Modifier.padding(12.dp), fontSize = 14.sp)
                    }
                }

                if (generatedImage != null) {
                    item {
                        AsyncImage(
                            model = generatedImage,
                            contentDescription = "Generated image",
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(220.dp)
                        )
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Mesaj yaz...") }
                )

                Spacer(modifier = Modifier.width(8.dp))

                Button(
                    onClick = {
                        isListening = !isListening
                        if (isListening) {
                            voiceManager.startListening { result ->
                                input = result
                                isListening = false
                            }
                        } else {
                            voiceManager.stopListening()
                        }
                    },
                    modifier = Modifier.size(48.dp),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Icon(Icons.Default.Mic, contentDescription = "Voice", tint = if (isListening) Color.Red else Color.White)
                }

                Spacer(modifier = Modifier.width(8.dp))

                Button(
                    onClick = {
                        if (input.isBlank()) return@Button
                        val msg = input.trim()
                        messages = messages + msg
                        input = ""
                        isLoading = true

                        scope.launch {
                            try {
                                val response = ApiClient.service.chat(
                                    ChatRequest(
                                        message = msg,
                                        model = selectedModel,
                                        language = language
                                    )
                                )
                                messages = messages + response.reply
                                voiceManager.speak(response.reply)

                                val imageResponse = ApiClient.service.image(
                                    ImageRequest(prompt = msg, style = "realistic")
                                )
                                generatedImage = imageResponse.image_url
                            } catch (e: Exception) {
                                messages = messages + "Hata: Sunucuya bağlanılamadı."
                            } finally {
                                isLoading = false
                            }
                        }
                    }
                ) {
                    Icon(Icons.Default.Send, contentDescription = null)
                }
            }
        }
    }
}
EOF

cat > PoloApp/app/src/test/java/com/polo/app/ExampleUnitTest.kt <<'EOF'
package com.polo.app

import org.junit.Assert.assertEquals
import org.junit.Test

class ExampleUnitTest {
    @Test
    fun addition_isCorrect() {
        assertEquals(4, 2 + 2)
    }
}
EOF

chmod +x PoloApp/backend/run.sh
chmod +x setup_polo.sh

echo "PoloApp hazır."
