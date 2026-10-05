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
