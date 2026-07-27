package com.example.atom_flt

import android.content.ContentResolver
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.atom_flt/file_browser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "listDirectory") {
                val uriString = call.argument<String>("uri")
                if (uriString == null) {
                    result.error("INVALID_ARG", "uri is required", null)
                    return@setMethodCallHandler
                }
                try {
                    val uri = Uri.parse(uriString)
                    val children = listDocuments(uri)
                    result.success(children)
                } catch (e: Exception) {
                    result.error("LIST_ERROR", e.message ?: "Unknown error", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun listDocuments(uri: Uri): List<Map<String, Any?>> {
        val resolver: ContentResolver = contentResolver
        val childrenUri: Uri

        if (uri.toString().contains("/document/")) {
            // Already a document URI, use it directly
            val docId = DocumentsContract.getDocumentId(uri)
            childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, docId)
        } else {
            // Tree URI, get root document ID
            val treeDocId = DocumentsContract.getTreeDocumentId(uri)
            childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, treeDocId)
        }

        val resultList = mutableListOf<Map<String, Any?>>()
        val cursor = resolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                DocumentsContract.Document.COLUMN_SIZE
            ),
            null, null, null
        )

        cursor?.use { c ->
            while (c.moveToNext()) {
                val docId = c.getString(0) ?: continue
                val name = c.getString(1) ?: "Unknown"
                val mimeType = c.getString(2) ?: ""
                val lastModified = c.getLong(3)
                val size = c.getLong(4)
                val isDir = mimeType == DocumentsContract.Document.MIME_TYPE_DIR

                val docUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)

                resultList.add(
                    mapOf(
                        "name" to name,
                        "uri" to docUri.toString(),
                        "isDirectory" to isDir,
                        "isFile" to !isDir,
                        "lastModified" to lastModified,
                        "length" to size
                    )
                )
            }
        }

        return resultList
    }
}
