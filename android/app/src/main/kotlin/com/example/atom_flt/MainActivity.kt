package com.example.atom_flt

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingManageStorageResult: MethodChannel.Result? = null
    private val PICK_DIRECTORY_REQUEST = 0x1001
    private val MANAGE_STORAGE_REQUEST = 0x1002

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.i("atom_flt", "API_LEVEL=${Build.VERSION.SDK_INT}")

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.atom_flt/file_browser"
        ).setMethodCallHandler { call, result ->
            Log.i("atom_flt", "method=${call.method}")
            try {
                when (call.method) {
                    "ping" -> result.success("pong")
                    "getApiLevel" -> result.success(Build.VERSION.SDK_INT)
                    "pickDirectory" -> {
                        pendingPickResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                        startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
                    }
                    "isExternalStorageManager" -> {
                        result.success(Environment.isExternalStorageManager())
                    }
                    "requestManageStorage" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()) {
                            pendingManageStorageResult = result
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            intent.data = Uri.parse("package:$packageName")
                            startActivityForResult(intent, MANAGE_STORAGE_REQUEST)
                        } else {
                            result.success(true)
                        }
                    }
                    "getRootDocId" -> {
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val treeUri = Uri.parse(treeUriStr)
                        val rootDocId = DocumentsContract.getTreeDocumentId(treeUri)
                        Log.i("atom_flt", "getRootDocId=$rootDocId")
                        result.success(rootDocId)
                    }
                    "listDirectory" -> {
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val parentDocId = call.argument<String>("docId")!!
                        val treeUri = Uri.parse(treeUriStr)
                        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
                        Log.i("atom_flt", "listDirectory treeUri=$treeUriStr parentDocId=$parentDocId childrenUri=$childrenUri")
                        val cursor = contentResolver.query(childrenUri, null, null, null, null)
                        val list = mutableListOf<Map<String, Any?>>()
                        if (cursor != null) {
                            cursor.use { c ->
                                while (c.moveToNext()) {
                                    val docId = c.getString(c.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                    val name = c.getString(c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)) ?: docId
                                    val mime = c.getString(c.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)) ?: ""
                                    val isDir = mime == DocumentsContract.Document.MIME_TYPE_DIR
                                    val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                                    val size = if (!isDir) c.getLong(c.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)) else 0L
                                    list.add(mapOf(
                                        "name" to name,
                                        "uri" to docUri.toString(),
                                        "docId" to docId,
                                        "isDirectory" to isDir,
                                        "isFile" to !isDir,
                                        "lastModified" to c.getLong(c.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)),
                                        "length" to size
                                    ))
                                }
                            }
                            Log.i("atom_flt", "found ${list.size} children via SAF")
                        } else {
                            Log.w("atom_flt", "cursor=null")
                        }
                        result.success(list)
                    }
                    "listDirectoryPath" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            Log.w("atom_flt", "listDirectoryPath blocked: API ${Build.VERSION.SDK_INT} >= 33, use SAF")
                            result.error("USE_SAF", "Android 13+ requiere SAF. Usa Configuración > Seleccionar carpeta.", null)
                            return@setMethodCallHandler
                        }
                        val path = call.argument<String>("path")!!
                        val dir = java.io.File(path)
                        val exists = dir.exists()
                        val isDir = dir.isDirectory
                        Log.i("atom_flt", "listDirPath path=$path exists=$exists isDir=$isDir")
                        if (!exists || !isDir) {
                            result.error("NOT_A_DIRECTORY", "No es un directorio: $path", null)
                            return@setMethodCallHandler
                        }
                        val files = dir.listFiles()
                        if (files == null) {
                            Log.w("atom_flt", "listFiles=null (scoped storage bloquea acceso)")
                            result.error("ACCESS_DENIED", "Acceso denegado. Usa Configuración > Seleccionar carpeta para otorgar permisos.", null)
                            return@setMethodCallHandler
                        }
                        val list = mutableListOf<Map<String, Any?>>()
                        for (file in files) {
                            list.add(mapOf(
                                "name" to file.name,
                                "uri" to file.absolutePath,
                                "docId" to file.absolutePath,
                                "isDirectory" to file.isDirectory,
                                "isFile" to file.isFile,
                                "lastModified" to file.lastModified(),
                                "length" to file.length()
                            ))
                        }
                        Log.i("atom_flt", "found ${list.size} children via File API")
                        result.success(list)
                    }
                    "readFile" -> {
                        val uriStr = call.argument<String>("uri")!!
                        val uri = Uri.parse(uriStr)
                        val input = contentResolver.openInputStream(uri)
                        val text = input?.bufferedReader()?.use { it.readText() } ?: ""
                        result.success(text)
                    }
                    "readFilePath" -> {
                        val path = call.argument<String>("path")!!
                        val text = java.io.File(path).readText()
                        result.success(text)
                    }
                    "writeFile" -> {
                        val uriStr = call.argument<String>("uri")!!
                        val content = call.argument<String>("content")!!
                        val uri = Uri.parse(uriStr)
                        val output = contentResolver.openOutputStream(uri, "wt")
                        output?.bufferedWriter()?.use { it.write(content) }
                        result.success(true)
                    }
                    "writeFilePath" -> {
                        val path = call.argument<String>("path")!!
                        val content = call.argument<String>("content")!!
                        java.io.File(path).writeText(content)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("atom_flt", "error: ${e.message}", e)
                result.error("ERROR", e.message ?: "unknown", null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            PICK_DIRECTORY_REQUEST -> {
                val pending = pendingPickResult
                pendingPickResult = null
                if (resultCode == RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        try {
                            contentResolver.takePersistableUriPermission(
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            )
                        } catch (e: Exception) {
                            Log.w("atom_flt", "takePersistableUriPermission failed: ${e.message}")
                        }
                        pending?.success(uri.toString())
                    } else {
                        pending?.success(null)
                    }
                } else {
                    pending?.success(null)
                }
            }
            MANAGE_STORAGE_REQUEST -> {
                val pending = pendingManageStorageResult
                pendingManageStorageResult = null
                pending?.success(Environment.isExternalStorageManager())
            }
        }
    }
}
