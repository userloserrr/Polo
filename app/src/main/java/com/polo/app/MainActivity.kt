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
