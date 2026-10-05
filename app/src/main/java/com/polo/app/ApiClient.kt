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
