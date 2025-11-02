// android/app/src/main/kotlin/com/example/ar_memo_frontend/MainActivity.kt
package com.example.ar_memo_frontend

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "image_channel"
    private val REQUEST_PICK_IMAGE = 5001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "pickImageWithGPS") {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_PICK).apply {
                        type = "image/*"
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                    }
                    startActivityForResult(intent, REQUEST_PICK_IMAGE)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_PICK_IMAGE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    val realPath = getRealPathFromUri(this, uri) ?: copyToCache(this, uri)
                    var lat: Double? = null
                    var lng: Double? = null
                    try {
                        contentResolver.openInputStream(uri)?.use { input ->
                            val exif = ExifInterface(input)
                            val latLong = FloatArray(2)
                            if (exif.getLatLong(latLong)) {
                                lat = latLong[0].toDouble()
                                lng = latLong[1].toDouble()
                            }
                        }
                    } catch (_: Exception) {
                    }

                    val map = hashMapOf<String, Any?>(
                        "uri" to uri.toString(),
                        "path" to realPath,
                        "latitude" to lat,
                        "longitude" to lng,
                    )
                    pendingResult?.success(map)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun getRealPathFromUri(context: Context, uri: Uri): String? {
        // Android 10 (Q) 이상에서는 직접 경로가 안 나올 수 있음
        return try {
            val projection = arrayOf(MediaStore.Images.Media.DATA)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                val idx = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                if (cursor.moveToFirst()) {
                    val path = cursor.getString(idx)
                    if (!path.isNullOrEmpty()) path else null
                } else null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun copyToCache(context: Context, uri: Uri): String? {
        return try {
            val input: InputStream? = context.contentResolver.openInputStream(uri)
            if (input != null) {
                val cacheFile = File(context.cacheDir, "picked_${System.currentTimeMillis()}.jpg")
                FileOutputStream(cacheFile).use { out ->
                    input.copyTo(out)
                }
                cacheFile.absolutePath
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }
}
