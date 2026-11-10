package com.example.certificate_studio

import android.app.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.certificate_studio/whatsapp_share"
        private val ALLOWED_PACKAGES = setOf("com.whatsapp", "com.whatsapp.w4b")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sharePdfToWhatsApp" -> sharePdfToWhatsApp(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun sharePdfToWhatsApp(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val packageName = call.argument<String>("packageName")
        val filePath = call.argument<String>("filePath")
        val phoneNumber = call.argument<String>("phoneNumber")

        if (packageName == null || packageName !in ALLOWED_PACKAGES) {
            result.error("INVALID_TARGET", "Unsupported WhatsApp package.", null)
            return
        }
        if (!isPackageInstalled(packageName)) {
            result.error("APP_NOT_INSTALLED", "Target application is not installed.", null)
            return
        }
        if (filePath.isNullOrBlank()) {
            result.error("INVALID_FILE", "A PDF path is required.", null)
            return
        }

        try {
            val file = File(filePath).canonicalFile
            val allowedDirectory = File(
                applicationContext.cacheDir,
                "certificate_studio_shares",
            ).canonicalPath + File.separator
            if (!file.isFile ||
                !file.path.startsWith(allowedDirectory) ||
                !file.extension.equals("pdf", ignoreCase = true)
            ) {
                result.error("INVALID_FILE", "The PDF file is outside the permitted share directory.", null)
                return
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(packageName)
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newUri(contentResolver, file.name, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                val cleanNumber = phoneNumber?.filter { it.isDigit() }.orEmpty()
                if (cleanNumber.isNotEmpty()) {
                    // This follows Qayd's JID approach. The extra is undocumented
                    // and may be ignored by WhatsApp; recipient routing is best-effort.
                    putExtra("jid", "$cleanNumber@s.whatsapp.net")
                }
            }
            startActivity(intent)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.error("APP_NOT_INSTALLED", "Target application is not available.", null)
        } catch (error: Exception) {
            result.error("INTENT_ERROR", error.message ?: "Unable to share PDF.", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun isPackageInstalled(packageName: String): Boolean = try {
        packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }
}
