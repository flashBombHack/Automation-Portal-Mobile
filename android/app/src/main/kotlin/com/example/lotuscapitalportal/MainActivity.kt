package com.example.lotuscapitalportal

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "download_pdf_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "downloadFile") {
                val url = call.argument<String>("url")
                if (url != null) {
                    downloadFile(url)
                    result.success("Download started")
                } else {
                    result.error("UNAVAILABLE", "URL not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun downloadFile(url: String) {
        val request = DownloadManager.Request(Uri.parse(url))
        request.setTitle("Downloading PDF")
        request.setDescription("Please wait...")
        request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "document.pdf")

        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.enqueue(request)
    }
}
