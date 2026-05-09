import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../core/file_name_safety.dart';
import '../../core/gmp_folder_structure.dart';
import '../../core/transfer_models.dart';

class AndroidPhoneShareFile {
  const AndroidPhoneShareFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
    required this.category,
  });

  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String mimeType;
  final TransferCategory category;

  String get sizeLabel => AndroidPhoneShareService.formatBytes(sizeBytes);
  String get typeLabel => mimeType.isEmpty ? extensionLabel : mimeType;
  String get extensionLabel {
    final extension = p.extension(name).replaceFirst('.', '').toUpperCase();
    return extension.isEmpty ? 'File' : extension;
  }
}

class AndroidPhoneShareSession {
  const AndroidPhoneShareSession({
    required this.ipAddress,
    required this.port,
    required this.url,
  });

  final String ipAddress;
  final int port;
  final String url;
}

class AndroidPhoneShareDownload {
  const AndroidPhoneShareDownload({
    required this.file,
    required this.progress,
    required this.complete,
  });

  final AndroidPhoneShareFile file;
  final double progress;
  final bool complete;
}

class AndroidPhoneShareService {
  static const _channel = MethodChannel('gmp_airdrop/android_export');

  HttpServer? _server;
  String? _token;
  AndroidPhoneShareSession? _session;
  List<AndroidPhoneShareFile> _files = const [];
  final _events = StreamController<AndroidPhoneShareDownload>.broadcast();

  Stream<AndroidPhoneShareDownload> get events => _events.stream;
  AndroidPhoneShareSession? get session => _session;
  List<AndroidPhoneShareFile> get files => List.unmodifiable(_files);
  bool get isRunning => _server != null;

  Future<List<TransferFile>> pickFiles(TransferCategory category) async {
    if (!Platform.isAndroid) return [];
    final result = await _channel.invokeMethod<List<Object?>>(
      'pickFiles',
      {'category': category.name},
    );
    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((item) => _transferFileFromNative(item, category))
        .toList();
  }

  Future<List<AndroidPhoneShareFile>> prepareFiles(
      List<TransferFile> files) async {
    if (!Platform.isAndroid || files.isEmpty) return const [];
    final payload = files
        .where((file) => file.sourcePath != null)
        .map((file) => {
              'uri': file.sourcePath,
              'name': file.name,
            })
        .toList();
    if (payload.isEmpty) return const [];

    final result = await _channel.invokeMethod<List<Object?>>(
      'cacheShareFiles',
      {'files': payload},
    );
    var index = 0;
    _files = (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((item) {
          final name = FileNameSafety.cleanFileName(
            item['name']?.toString() ?? 'Untitled',
          );
          final mimeType = item['mimeType']?.toString() ?? '';
          final path = item['path']?.toString() ?? '';
          final size = int.tryParse(item['size']?.toString() ?? '') ?? 0;
          return AndroidPhoneShareFile(
            id: '${index++}',
            name: name,
            path: path,
            sizeBytes: size,
            mimeType: mimeType,
            category: _categoryForName(name),
          );
        })
        .where((file) => file.path.isNotEmpty)
        .toList();
    return _files;
  }

  Future<AndroidPhoneShareSession> start() async {
    if (_session != null && _server != null) return _session!;
    if (_files.isEmpty) {
      throw StateError('Select files before starting phone share.');
    }

    final ipAddress = await _localIpAddress();
    final token = _makeToken();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _token = token;
    _session = AndroidPhoneShareSession(
      ipAddress: ipAddress,
      port: server.port,
      url: 'http://$ipAddress:${server.port}/?t=$token',
    );
    unawaited(_serve(server));
    return _session!;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _session = null;
    _token = null;
    await server?.close(force: true);
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      try {
        await _handle(request);
      } catch (_) {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response
              .write('Download failed. Keep Android GMP Airdrop open.');
          await request.response.close();
        } on StateError {
          // Client may have closed the connection.
        }
      }
    }
  }

  Future<void> _handle(HttpRequest request) async {
    request.response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff');

    if (!_validToken(request.uri.queryParameters['t'])) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('Invalid share link.');
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(_downloadPage(request.uri.queryParameters['t']!));
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.pathSegments.length == 2) {
      if (request.uri.pathSegments.first == 'download') {
        await _downloadFile(request, request.uri.pathSegments.last);
        return;
      }
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not found.');
    await request.response.close();
  }

  Future<void> _downloadFile(HttpRequest request, String id) async {
    final fileItem = _files.where((file) => file.id == id).firstOrNull;
    if (fileItem == null) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('File not found.');
      await request.response.close();
      return;
    }

    final file = File(fileItem.path);
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.gone;
      request.response.write('This shared file is no longer available.');
      await request.response.close();
      return;
    }

    final mimeType = lookupMimeType(fileItem.path) ??
        (fileItem.mimeType.isEmpty
            ? 'application/octet-stream'
            : fileItem.mimeType);
    final encodedName = Uri.encodeComponent(fileItem.name);
    request.response.headers
      ..contentType = ContentType.parse(mimeType)
      ..set('Content-Disposition',
          "attachment; filename=\"${_asciiFallback(fileItem.name)}\"; filename*=UTF-8''$encodedName")
      ..set(HttpHeaders.contentLengthHeader, fileItem.sizeBytes.toString());

    var sent = 0;
    _events.add(AndroidPhoneShareDownload(
      file: fileItem,
      progress: 0,
      complete: false,
    ));
    await for (final chunk in file.openRead()) {
      sent += chunk.length;
      request.response.add(chunk);
      _events.add(AndroidPhoneShareDownload(
        file: fileItem,
        progress: fileItem.sizeBytes > 0
            ? (sent / fileItem.sizeBytes).clamp(0, 0.98).toDouble()
            : 0,
        complete: false,
      ));
    }
    await request.response.close();
    _events.add(AndroidPhoneShareDownload(
      file: fileItem,
      progress: 1,
      complete: true,
    ));
  }

  String _downloadPage(String token) {
    final rows = _files.map((file) {
      final href = '/download/${file.id}?t=${Uri.encodeQueryComponent(token)}';
      return '''
        <li>
          <div>
            <strong>${_html(file.name)}</strong>
            <span>${_html(file.sizeLabel)} · ${_html(file.typeLabel)}</span>
          </div>
          <a href="$href">Download</a>
        </li>
      ''';
    }).join();

    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>GMP Airdrop Download</title>
  <style>
    :root {
      color-scheme: light dark;
      --bg: #fafbfd;
      --surface: #ffffff;
      --text: #12223a;
      --muted: #697589;
      --line: #e7ecf4;
      --blue: #155fd6;
      --blue-soft: #f1f6ff;
      --shadow: rgba(21,95,214,.08);
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0d1118;
        --surface: #151b24;
        --text: #f5f7fb;
        --muted: #a5afbd;
        --line: #263242;
        --blue-soft: #13243d;
        --shadow: rgba(0,0,0,.28);
      }
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--text); }
    main { max-width: 760px; margin: 0 auto; padding: max(26px, env(safe-area-inset-top)) 18px 44px; }
    h1 { font-size: clamp(34px, 10vw, 52px); line-height: .98; margin: 14px 0; }
    p { color: var(--muted); line-height: 1.55; font-size: 17px; margin: 0 0 22px; }
    .badge { display: inline-flex; padding: 8px 12px; border-radius: 999px; background: var(--blue-soft); color: var(--blue); font-weight: 800; font-size: 14px; }
    ul { list-style: none; padding: 0; margin: 0; }
    li { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 16px; margin-bottom: 12px; background: var(--surface); border: 1px solid var(--line); border-radius: 18px; box-shadow: 0 14px 36px var(--shadow); animation: rise .2s ease both; }
    strong { display: block; overflow-wrap: anywhere; }
    span { display: block; color: var(--muted); margin-top: 5px; font-size: 14px; }
    a { flex: 0 0 auto; text-decoration: none; color: #fff; background: var(--blue); padding: 10px 14px; border-radius: 12px; font-weight: 800; }
    @media (max-width: 520px) {
      li { align-items: stretch; flex-direction: column; }
      a { text-align: center; }
    }
    @keyframes rise { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
  </style>
</head>
<body>
  <main>
    <span class="badge">Local Wi-Fi only</span>
    <h1>Download from Android</h1>
    <p>These files are shared directly from the Android GMP Airdrop app. Keep both devices on the same Wi-Fi until downloads finish.</p>
    <ul>$rows</ul>
  </main>
</body>
</html>
''';
  }

  TransferFile _transferFileFromNative(
    Map<Object?, Object?> item,
    TransferCategory requestedCategory,
  ) {
    final name =
        FileNameSafety.cleanFileName(item['name']?.toString() ?? 'Untitled');
    final size = int.tryParse(item['size']?.toString() ?? '') ?? 0;
    final folder = GmpFolderStructure.folderForExtension(p.extension(name));
    return TransferFile(
      name: name,
      sizeLabel: formatBytes(size),
      modifiedLabel: 'Selected',
      category: requestedCategory == TransferCategory.documents
          ? TransferClassifier.categoryForFolder(folder)
          : requestedCategory,
      targetFolder: folder,
      sizeBytes: size,
      sourcePath: item['uri']?.toString(),
      relativePath: name,
    );
  }

  TransferCategory _categoryForName(String name) {
    final folder = GmpFolderStructure.folderForExtension(p.extension(name));
    return TransferClassifier.categoryForFolder(folder);
  }

  Future<String> _localIpAddress() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = interfaces
        .expand((interface) => interface.addresses)
        .map((address) => address.address)
        .where(_isPrivateIpv4)
        .toList();
    if (addresses.isNotEmpty) return addresses.first;
    return interfaces
            .expand((interface) => interface.addresses)
            .map((address) => address.address)
            .firstOrNull ??
        '127.0.0.1';
  }

  bool _isPrivateIpv4(String address) {
    return address.startsWith('192.168.') ||
        address.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(address);
  }

  bool _validToken(String? token) {
    final expected = _token;
    return expected != null && token != null && token == expected;
  }

  String _makeToken() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  String _asciiFallback(String name) {
    final fallback = name.replaceAll(RegExp(r'[^\x20-\x7E]'), '_');
    return fallback.replaceAll('"', '_');
  }

  String _html(String value) {
    return const HtmlEscape().convert(value);
  }

  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = unitIndex == 0 || size >= 10 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}
