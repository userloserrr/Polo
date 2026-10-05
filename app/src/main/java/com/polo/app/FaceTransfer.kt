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
