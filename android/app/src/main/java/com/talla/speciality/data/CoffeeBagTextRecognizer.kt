package com.talla.speciality.data

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

object CoffeeBagTextRecognizer {
    suspend fun analyze(context: Context, imageUri: Uri): CoffeeBagScanResult {
        val image = InputImage.fromFilePath(context, imageUri)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        return suspendCoroutine { continuation ->
            recognizer.process(image)
                .addOnSuccessListener { recognized ->
                    recognizer.close()
                    val lines = recognized.textBlocks.flatMap { block -> block.lines.map { it.text } }
                    if (lines.none { it.isNotBlank() }) {
                        continuation.resumeWithException(IllegalArgumentException("No readable text was found on this coffee bag"))
                    } else {
                        continuation.resume(CoffeeBagLabelParser.parse(lines))
                    }
                }
                .addOnFailureListener { error ->
                    recognizer.close()
                    continuation.resumeWithException(error)
                }
        }
    }
}
