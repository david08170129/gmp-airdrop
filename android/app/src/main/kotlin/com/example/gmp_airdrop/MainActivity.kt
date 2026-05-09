package com.example.gmp_airdrop

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.StatFs
import android.provider.OpenableColumns
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val logTag = "GMP_Airdrop_SAF"
    private val channelName = "gmp_airdrop/android_export"
    private val pickFilesRequest = 4101
    private val pickTreeRequest = 4102
    private val executor = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCategory: String = "documents"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFiles" -> pickFiles(call, result)
                "chooseDestination" -> chooseDestination(result)
                "createFolderStructure" -> createFolderStructure(call, result)
                "exportFiles" -> exportFiles(call, result)
                "cacheShareFiles" -> cacheShareFiles(call, result)
                "getAppStorageFreeBytes" -> getAppStorageFreeBytes(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        when (requestCode) {
            pickFilesRequest -> handlePickedFiles(data, result)
            pickTreeRequest -> handlePickedTree(data, result)
        }
    }

    private fun pickFiles(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another Android picker is already open.", null)
            return
        }

        pendingCategory = call.argument<String>("category") ?: "documents"
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            type = when (pendingCategory) {
                "photos" -> "image/*"
                "videos" -> "video/*"
                else -> "*/*"
            }
            if (pendingCategory == "documents") {
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf(
                        "application/pdf",
                        "application/msword",
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                        "application/vnd.ms-excel",
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        "text/csv",
                        "application/vnd.ms-powerpoint",
                        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                        "text/markdown",
                        "text/plain",
                        "text/x-python",
                        "application/octet-stream"
                    )
                )
            }
        }

        pendingResult = result
        startActivityForResult(intent, pickFilesRequest)
    }

    private fun chooseDestination(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another Android picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }

        pendingResult = result
        startActivityForResult(intent, pickTreeRequest)
    }

    private fun exportFiles(call: MethodCall, result: MethodChannel.Result) {
        val destinationUri = call.argument<String>("destinationUri")
        val files = call.argument<List<Map<String, Any?>>>("files") ?: emptyList()
        if (destinationUri.isNullOrBlank()) {
            result.error("missing_destination", "No destination URI was provided.", null)
            return
        }
        if (files.isEmpty()) {
            result.success(null)
            return
        }

        executor.execute {
            try {
                val selectedTree = openVerifiedUsbRoot(Uri.parse(destinationUri))
                val gmpRoot = createAndVerifyGmpRoot(selectedTree)
                ensureFolderTree(gmpRoot)
                verifyFolderTree(gmpRoot)

                files.forEachIndexed { index, item ->
                    val sourceUri = Uri.parse(item["uri"]?.toString() ?: "")
                    val displayName = cleanDisplayName(item["name"]?.toString() ?: "Untitled")
                    val targetFolder = item["targetFolder"]?.toString() ?: folderForName(displayName)
                    copyToTarget(sourceUri, displayName, targetFolder, gmpRoot)
                    runOnUiThread {
                        channel?.invokeMethod(
                            "exportProgress",
                            (index + 1).toDouble() / files.size
                        )
                    }
                }

                verifyFolderTree(gmpRoot)
                runOnUiThread { result.success(null) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("export_failed", error.message, null)
                }
            }
        }
    }

    private fun createFolderStructure(call: MethodCall, result: MethodChannel.Result) {
        val destinationUri = call.argument<String>("destinationUri")
        if (destinationUri.isNullOrBlank()) {
            result.error("missing_destination", "No destination URI was provided.", null)
            return
        }

        executor.execute {
            try {
                val selectedTree = openVerifiedUsbRoot(Uri.parse(destinationUri))
                val gmpRoot = createAndVerifyGmpRoot(selectedTree)
                ensureFolderTree(gmpRoot)
                val folders = verifyFolderTree(gmpRoot)
                Log.d(logTag, "Verified folder structure: $folders")
                runOnUiThread { result.success(folders) }
            } catch (error: Exception) {
                Log.e(logTag, "createFolderStructure failed: ${error.message}", error)
                runOnUiThread {
                    result.error("create_structure_failed", error.message, null)
                }
            }
        }
    }

    private fun cacheShareFiles(call: MethodCall, result: MethodChannel.Result) {
        val files = call.argument<List<Map<String, Any?>>>("files") ?: emptyList()
        if (files.isEmpty()) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        executor.execute {
            try {
                val shareRoot = File(cacheDir, "gmp_airdrop_share").apply {
                    deleteRecursively()
                    mkdirs()
                }
                val cached = mutableListOf<Map<String, Any?>>()
                files.forEach { item ->
                    val sourceUri = Uri.parse(item["uri"]?.toString() ?: "")
                    val displayName = cleanDisplayName(item["name"]?.toString() ?: displayName(sourceUri))
                    val mimeType = contentResolver.getType(sourceUri) ?: "application/octet-stream"
                    val targetFile = uniqueCacheFile(shareRoot, displayName)
                    contentResolver.openInputStream(sourceUri).use { input ->
                        FileOutputStream(targetFile).use { output ->
                            if (input == null) {
                                throw IllegalStateException("Unable to open $displayName for sharing.")
                            }
                            input.copyTo(output)
                            output.flush()
                            output.channel.force(true)
                        }
                    }
                    cached.add(
                        mapOf(
                            "path" to targetFile.absolutePath,
                            "name" to targetFile.name,
                            "size" to targetFile.length(),
                            "mimeType" to mimeType
                        )
                    )
                }
                runOnUiThread { result.success(cached) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("cache_share_failed", error.message, null)
                }
            }
        }
    }

    private fun getAppStorageFreeBytes(result: MethodChannel.Result) {
        try {
            val stat = StatFs(filesDir.absolutePath)
            result.success(stat.availableBytes)
        } catch (error: Exception) {
            result.error("storage_check_failed", error.message, null)
        }
    }

    private fun handlePickedFiles(data: Intent, result: MethodChannel.Result) {
        val flags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        val uris = mutableListOf<Uri>()

        data.clipData?.let { clipData ->
            for (index in 0 until clipData.itemCount) {
                uris.add(clipData.getItemAt(index).uri)
            }
        } ?: data.data?.let { uri ->
            uris.add(uri)
        }

        val files = uris.map { uri ->
            try {
                contentResolver.takePersistableUriPermission(uri, flags)
            } catch (_: SecurityException) {
            }
            mapOf(
                "uri" to uri.toString(),
                "name" to displayName(uri),
                "size" to fileSize(uri),
                "mimeType" to (contentResolver.getType(uri) ?: "")
            )
        }
        result.success(files)
    }

    private fun handlePickedTree(data: Intent, result: MethodChannel.Result) {
        val uri = data.data
        if (uri == null) {
            result.success(null)
            return
        }

        val flags = data.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (error: SecurityException) {
            result.error("permission_failed", error.message, null)
            return
        }

        val selectedTree = DocumentFile.fromTreeUri(this, uri)
        Log.d(logTag, "Selected URI: $uri")
        Log.d(logTag, "Selected URI lastPathSegment: ${uri.lastPathSegment}")
        Log.d(logTag, "Selected tree is USB root: ${isUsbRootTreeUri(uri)}")
        Log.d(logTag, "DocumentFile.fromTreeUri null: ${selectedTree == null}")
        Log.d(logTag, "Selected tree canWrite: ${selectedTree?.canWrite()}")
        if (selectedTree == null || !selectedTree.exists() || !selectedTree.isDirectory || !selectedTree.canWrite()) {
            result.error("not_writable", "Selected USB folder is not writable.", null)
            return
        }
        if (!isUsbRootTreeUri(uri)) {
            result.error(
                "not_usb_root",
                "Please select the USB drive root, not a subfolder. Android returned: ${uri.lastPathSegment}",
                null
            )
            return
        }

        result.success(
            mapOf(
                "uri" to uri.toString(),
                "label" to treeLabel(uri)
            )
        )
    }

    private fun ensureFolderTree(gmpRoot: DocumentFile) {
        findOrCreateDirectory(gmpRoot, "Photos")
        findOrCreateDirectory(gmpRoot, "Videos")
        val documents = findOrCreateDirectory(gmpRoot, "Documents")
        findOrCreateDirectory(documents, "PDF")
        findOrCreateDirectory(documents, "Word")
        findOrCreateDirectory(documents, "Excel")
        findOrCreateDirectory(documents, "PPT")
        findOrCreateDirectory(documents, "Markdown")
        findOrCreateDirectory(documents, "TXT")
        findOrCreateDirectory(documents, "Others")
        val code = findOrCreateDirectory(gmpRoot, "Code")
        findOrCreateDirectory(code, "Python")
    }

    private fun verifyFolderTree(gmpRoot: DocumentFile): List<String> {
        val requiredPaths = listOf(
            "",
            "Photos",
            "Videos",
            "Documents/PDF",
            "Documents/Word",
            "Documents/Excel",
            "Documents/PPT",
            "Documents/Markdown",
            "Documents/TXT",
            "Documents/Others",
            "Code/Python"
        )
        for (path in requiredPaths) {
            val exists = if (path.isEmpty()) {
                gmpRoot.exists() && gmpRoot.isDirectory
            } else {
                directoryForPath(gmpRoot, path, createMissing = false) != null
            }
            Log.d(logTag, "Verify folder '${if (path.isEmpty()) "GMP_Airdrop" else "GMP_Airdrop/$path"}': $exists")
            require(exists) {
                "Unable to verify folder GMP_Airdrop/$path on the USB drive."
            }
        }
        return requiredPaths.map { path ->
            if (path.isEmpty()) "GMP_Airdrop" else "GMP_Airdrop/$path"
        }
    }

    private fun copyToTarget(
        sourceUri: Uri,
        displayName: String,
        targetFolder: String,
        gmpRoot: DocumentFile
    ) {
        val targetDirectory = directoryForTarget(gmpRoot, targetFolder)
        val targetName = uniqueName(targetDirectory, displayName)
        val mimeType = contentResolver.getType(sourceUri) ?: "application/octet-stream"
        val targetFile = targetDirectory.createFile(mimeType, targetName)
            ?: throw IllegalStateException("Unable to create $targetName on the USB drive.")

        contentResolver.openInputStream(sourceUri).use { input ->
            contentResolver.openFileDescriptor(targetFile.uri, "w").use { descriptor ->
                if (input == null || descriptor == null) {
                    throw IllegalStateException("Unable to open streams for $displayName")
                }
                FileOutputStream(descriptor.fileDescriptor).use { output ->
                    input.copyTo(output)
                    output.flush()
                    output.channel.force(true)
                    descriptor.fileDescriptor.sync()
                }
            }
        }

        require(targetFile.exists() && targetFile.length() >= 0) {
            "Unable to verify copied file $targetName on the USB drive."
        }
    }

    private fun directoryForTarget(gmpRoot: DocumentFile, targetFolder: String): DocumentFile {
        val path = targetFolder
            .replace("\\", "/")
            .split("/")
            .filter { it.isNotBlank() && it != "GMP_Airdrop" }
            .joinToString("/")
        return directoryForPath(gmpRoot, path, createMissing = true)
            ?: throw IllegalStateException("Unable to create target folder GMP_Airdrop/$path")
    }

    private fun directoryForPath(
        root: DocumentFile,
        path: String,
        createMissing: Boolean
    ): DocumentFile? {
        var current = root
        val parts = path.split("/").filter { it.isNotBlank() }
        for (part in parts) {
            val next = current.findFile(part)
            current = when {
                next != null && next.isDirectory -> next
                next != null -> return null
                createMissing -> findOrCreateDirectory(current, part)
                else -> return null
            }
        }
        return current
    }

    private fun findOrCreateDirectory(parent: DocumentFile, name: String): DocumentFile {
        parent.findFile(name)?.let { existing ->
            Log.d(logTag, "Found existing folder name=$name exists=${existing.exists()} isDirectory=${existing.isDirectory}")
            require(existing.isDirectory) { "$name exists but is not a folder." }
            return existing
        }
        val created = parent.createDirectory(name)
            ?: throw IllegalStateException("Unable to create folder $name on the USB drive.")
        Log.d(logTag, "createDirectory('$name') return value null: ${created == null}")
        Log.d(logTag, "createDirectory('$name') uri: ${created?.uri}")
        Log.d(logTag, "createDirectory('$name') exists immediately: ${created?.exists()}")
        Log.d(logTag, "createDirectory('$name') canWrite immediately: ${created?.canWrite()}")
        require(created.exists() && created.isDirectory) {
            "Folder $name was not created on the USB drive."
        }
        return created
    }

    private fun uniqueName(parent: DocumentFile, originalName: String): String {
        val safeName = cleanDisplayName(originalName)
        val existing = parent.listFiles()
            .mapNotNull { it.name }
            .map { it.lowercase(Locale.ROOT) }
            .toSet()
        if (!existing.contains(safeName.lowercase(Locale.ROOT))) return safeName

        val dot = safeName.lastIndexOf('.')
        val base = if (dot > 0) safeName.substring(0, dot) else safeName
        val extension = if (dot > 0) safeName.substring(dot) else ""
        var index = 1
        while (true) {
            val candidate = limitFileName("$base ($index)$extension")
            if (!existing.contains(candidate.lowercase(Locale.ROOT))) return candidate
            index++
        }
    }

    private fun uniqueCacheFile(parent: File, originalName: String): File {
        val safeName = cleanDisplayName(originalName)
        val existing = parent.listFiles()
            ?.map { it.name.lowercase(Locale.ROOT) }
            ?.toSet()
            ?: emptySet()
        if (!existing.contains(safeName.lowercase(Locale.ROOT))) {
            return File(parent, safeName)
        }

        val dot = safeName.lastIndexOf('.')
        val base = if (dot > 0) safeName.substring(0, dot) else safeName
        val extension = if (dot > 0) safeName.substring(dot) else ""
        var index = 1
        while (true) {
            val candidate = limitFileName("$base ($index)$extension")
            if (!existing.contains(candidate.lowercase(Locale.ROOT))) {
                return File(parent, candidate)
            }
            index++
        }
    }

    private fun cleanDisplayName(name: String): String {
        val withoutPath = name.substringAfterLast('/').substringAfterLast('\\').trim()
        val cleaned = withoutPath
            .replace(Regex("[<>:\"/\\\\|?*\\u0000-\\u001F]"), "_")
            .replace(Regex("\\s+"), " ")
            .replace(Regex("^\\.+"), "")
            .trim()
        return limitFileName(cleaned.ifBlank { "Untitled" })
    }

    private fun limitFileName(name: String): String {
        val maxLength = 180
        if (name.length <= maxLength) return name
        val dot = name.lastIndexOf('.')
        val extension = if (dot > 0) name.substring(dot) else ""
        val base = if (dot > 0) name.substring(0, dot) else name
        val keep = (maxLength - extension.length).coerceAtLeast(20)
        return base.take(keep) + extension
    }

    private fun hasPersistedWritePermission(uri: Uri): Boolean {
        return contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isWritePermission
        }
    }

    private fun openVerifiedUsbRoot(treeUri: Uri): DocumentFile {
        Log.d(logTag, "Open selected URI: $treeUri")
        Log.d(logTag, "Open URI path: ${treeUri.path}")
        Log.d(logTag, "Open URI lastPathSegment: ${treeUri.lastPathSegment}")
        Log.d(logTag, "Persisted URI permissions: ${contentResolver.persistedUriPermissions.joinToString { "${it.uri} read=${it.isReadPermission} write=${it.isWritePermission}" }}")
        Log.d(logTag, "Selected tree is USB root: ${isUsbRootTreeUri(treeUri)}")
        require(isUsbRootTreeUri(treeUri)) {
            "Please select the USB drive root, not a subfolder. Android returned: ${treeUri.lastPathSegment}"
        }
        require(hasPersistedWritePermission(treeUri)) {
            "GMP Airdrop does not have persisted write access to this USB root."
        }

        val selectedTree = DocumentFile.fromTreeUri(this, treeUri)
            ?: throw IllegalStateException("DocumentFile.fromTreeUri returned null for $treeUri")
        Log.d(logTag, "DocumentFile.fromTreeUri null: false")
        Log.d(logTag, "Selected tree name: ${selectedTree.name}")
        Log.d(logTag, "Selected tree exists: ${selectedTree.exists()}")
        Log.d(logTag, "Selected tree isDirectory: ${selectedTree.isDirectory}")
        Log.d(logTag, "Selected tree canWrite: ${selectedTree.canWrite()}")
        require(selectedTree.exists() && selectedTree.isDirectory && selectedTree.canWrite()) {
            "Selected USB root is not writable. canWrite=${selectedTree.canWrite()} uri=$treeUri"
        }
        return selectedTree
    }

    private fun createAndVerifyGmpRoot(selectedTree: DocumentFile): DocumentFile {
        Log.d(logTag, "Creating GMP_Airdrop under selected root: name=${selectedTree.name} uri=${selectedTree.uri}")
        val gmpRoot = findOrCreateDirectory(selectedTree, "GMP_Airdrop")
        Log.d(logTag, "GMP_Airdrop uri: ${gmpRoot.uri}")
        Log.d(logTag, "GMP_Airdrop exists immediately: ${gmpRoot.exists()}")
        Log.d(logTag, "GMP_Airdrop canWrite immediately: ${gmpRoot.canWrite()}")
        require(gmpRoot.exists() && gmpRoot.isDirectory) {
            "createDirectory(\"GMP_Airdrop\") returned but folder does not exist."
        }
        return gmpRoot
    }

    private fun isUsbRootTreeUri(uri: Uri): Boolean {
        val segment = uri.lastPathSegment ?: return false
        val documentPath = segment.substringAfter(":", missingDelimiterValue = "")
        return segment.contains(":") && documentPath.isEmpty()
    }

    private fun folderForName(name: String): String {
        return when (name.substringAfterLast('.', "").lowercase(Locale.US)) {
            "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "bmp", "tif", "tiff", "raw", "dng" -> "GMP_Airdrop/Photos"
            "mp4", "mov", "m4v", "avi", "mkv", "webm", "wmv", "3gp" -> "GMP_Airdrop/Videos"
            "pdf" -> "GMP_Airdrop/Documents/PDF"
            "doc", "docx" -> "GMP_Airdrop/Documents/Word"
            "xls", "xlsx", "csv" -> "GMP_Airdrop/Documents/Excel"
            "ppt", "pptx" -> "GMP_Airdrop/Documents/PPT"
            "md", "markdown" -> "GMP_Airdrop/Documents/Markdown"
            "txt" -> "GMP_Airdrop/Documents/TXT"
            "py" -> "GMP_Airdrop/Code/Python"
            else -> "GMP_Airdrop/Documents/Others"
        }
    }

    private fun displayName(uri: Uri): String {
        queryOpenable(uri)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && index >= 0) return cursor.getString(index)
        }
        return uri.lastPathSegment ?: "Untitled"
    }

    private fun fileSize(uri: Uri): Long {
        queryOpenable(uri)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (cursor.moveToFirst() && index >= 0) return cursor.getLong(index)
        }
        return 0L
    }

    private fun queryOpenable(uri: Uri): Cursor? {
        return contentResolver.query(uri, null, null, null, null)
    }

    private fun treeLabel(uri: Uri): String {
        return uri.lastPathSegment
            ?.substringAfterLast(":")
            ?.ifBlank { "USB-C destination" }
            ?: "USB-C destination"
    }
}
