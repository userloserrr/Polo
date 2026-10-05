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
