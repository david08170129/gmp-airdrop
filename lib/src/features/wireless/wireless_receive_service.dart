import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';



import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


import '../../core/file_name_safety.dart';
import '../../core/file_count_summary.dart';
import '../../core/gmp_folder_structure.dart';
import '../../core/transfer_models.dart';

class WirelessReceiveSession {
  const WirelessReceiveSession({
    required this.ipAddress,
    required this.port,
    required this.url,
    required this.availableBytes,
  });

  final String ipAddress;
  final int port;
  final String url;
  final int availableBytes;
}

class WirelessReceiveItem {
  const WirelessReceiveItem({
    required this.name,
    required this.savedPath,
    required this.sizeBytes,
    required this.category,
    required this.receivedAt,
    this.progress = 1,
    this.complete = true,
  });

  final String name;
  final String savedPath;
  final int sizeBytes;
  final TransferCategory category;
  final DateTime receivedAt;
  final double progress;
  final bool complete;

  WirelessReceiveItem copyWith({
    String? savedPath,
    int? sizeBytes,
    double? progress,
    bool? complete,
  }) {
    return WirelessReceiveItem(
      name: name,
      savedPath: savedPath ?? this.savedPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      category: category,
      receivedAt: receivedAt,
      progress: progress ?? this.progress,
      complete: complete ?? this.complete,
    );
  }
}

class WirelessReceiveService {
  static const _androidChannel = MethodChannel('gmp_airdrop/android_export');
  static const largeFileWarningBytes = 1024 * 1024 * 1024;
  static const maxUploadBytes = 10 * 1024 * 1024 * 1024;
  static const supportedVideoMimeTypes = {
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
    'application/octet-stream',
  };
  static const supportedVideoExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.avi',
    '.mkv',
  };

  HttpServer? _server;
  RawDatagramSocket? _discoverySocket;
  Timer? _discoveryTimer;

  String? _token;
  WirelessReceiveSession? _session;
  final _events = StreamController<WirelessReceiveItem>.broadcast();

  Stream<WirelessReceiveItem> get events => _events.stream;
  WirelessReceiveSession? get session => _session;
  bool get isRunning => _server != null;

  Future<void> receiveLocalFiles(List<File> files) async {


    final received = <WirelessReceiveItem>[];
    for (final file in files) {
      if (!await file.exists()) continue;
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) continue;

      final cleanName = FileNameSafety.cleanFileName(p.basename(file.path));
      final category = _categoryForExtension(p.extension(cleanName));
      final destination = await FileNameSafety.uniqueFile(File(p.join(
        await _categoryRoot(category),
        cleanName,
      )));

      var written = 0;
      final createdAt = DateTime.now();
      var progressItem = WirelessReceiveItem(
        name: cleanName,
        savedPath: destination.path,
        sizeBytes: 0,
        category: category,
        receivedAt: createdAt,
        progress: 0,
        complete: false,
      );
      _events.add(progressItem);

      final input = file.openRead();
      final sink = destination.openWrite();
      try {
        await for (final chunk in input) {
          written += chunk.length;
          sink.add(chunk);
          progressItem = progressItem.copyWith(
            sizeBytes: written,
            progress: stat.size > 0
                ? (written / stat.size).clamp(0, 0.98).toDouble()
                : 0,
          );
          _events.add(progressItem);
        }
      } finally {
        await sink.close();
      }

      final completeItem = progressItem.copyWith(
        sizeBytes: written,
        progress: 1,
        complete: true,
      );
      received.add(completeItem);
      _events.add(completeItem);
    }

    if (received.isNotEmpty) {
      await saveWirelessHistory(_historyItem(received));
    }
  }
  Future<void> _startDiscoveryBroadcast(
  String ip,
  int port,
) async {
  _discoverySocket ??=
      await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    0,
    reuseAddress: true,
    reusePort: true,
  );

  _discoverySocket!.broadcastEnabled = true;


  

  final deviceName = Platform.localHostname;
  
  _discoveryTimer?.cancel();

  _discoveryTimer = Timer.periodic(
    const Duration(seconds: 2),
    (_) {
      final payload = jsonEncode({
        'name': deviceName,
      


        'url': 'http://$ip:$port/?t=$_token',
      });

      _discoverySocket!.send(
        utf8.encode(payload),
        InternetAddress('255.255.255.255'),
        45454,
      );
    },
  );
}
  
  
  
  
  

  Future<WirelessReceiveSession> start() async {
    if (_session != null && _server != null) return _session!;

    final ipAddress = await _localIpAddress();
    final token = _makeToken();
    final availableBytes = await _receiverAvailableBytes();

      await Directory(await _categoryRoot(TransferCategory.photos))
    .create(recursive: true);

await Directory(await _categoryRoot(TransferCategory.videos))
    .create(recursive: true);

await Directory(await _categoryRoot(TransferCategory.documents))
    .create(recursive: true);

    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _token = token;
    _session = WirelessReceiveSession(
      ipAddress: ipAddress,
      port: server.port,
      url: 'http://$ipAddress:${server.port}/?t=$token',
      availableBytes: availableBytes,
    );



    await _startDiscoveryBroadcast(
  ipAddress,
  server.port,
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

  Future<List<TransferHistoryItem>> loadWirelessHistory() async {
    final file = await _historyFile();
    if (!await file.exists()) return [];

    try {
      final payload = jsonDecode(await file.readAsString());
      if (payload is! List) return [];
      return payload
          .whereType<Map<String, dynamic>>()
          .map(_historyFromJson)
          .whereType<TransferHistoryItem>()
          .toList();
    } on FormatException {
      return [];
    } on FileSystemException {
      return [];
    }
  }

  Future<void> saveWirelessHistory(TransferHistoryItem item) async {
    final history = await loadWirelessHistory();
    history.insert(0, item);
    final file = await _historyFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        history.take(80).map(_historyToJson).toList(),
      ),
    );
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      try {
        await _handle(request);
      } catch (_) {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'ok': false,
            'message':
                'Upload failed while saving to this device. Check storage space and try again.',
          }));
          await request.response.close();
        } on StateError {
          // The response may already be closed if the client disconnected.
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
      request.response.write('Invalid receive link.');
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/') {
      final availableBytes = await _receiverAvailableBytes();
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        _uploadPage(request.uri.queryParameters['t']!, availableBytes),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/upload') {
      await _handleUpload(request);
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not found.');
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final contentType = request.headers.contentType;
    final boundary = contentType?.parameters['boundary'];
    if (contentType == null ||
        contentType.mimeType != 'multipart/form-data' ||
        boundary == null ||
        boundary.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'ok': false,
        'message': 'The browser did not send a valid file upload.',
      }));
      await request.response.close();
      return;
    }
    if (request.contentLength > maxUploadBytes) {
      request.response.statusCode = HttpStatus.requestEntityTooLarge;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'ok': false,
        'message':
            'This upload is over 10 GB. Send fewer files at once or move very large videos by USB.',
      }));
      await request.response.close();
      return;
    }
    final availableBytes = await _receiverAvailableBytes();
    if (availableBytes >= 0 && request.contentLength > availableBytes) {
      request.response.statusCode = 507;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'ok': false,
        'message':
            'Transfer blocked. Required: ${_formatBytes(request.contentLength)}. Receiver available: ${_formatBytes(availableBytes)}.',
        'requiredBytes': request.contentLength,
        'availableBytes': availableBytes,
      }));
      await request.response.close();
      return;
    }

    final received = <WirelessReceiveItem>[];
    final multipartStream = MimeMultipartTransformer(boundary).bind(request);
    await for (final part in multipartStream) {
      final disposition = part.headers['content-disposition'] ?? '';
      final fileName = _fileNameFromDisposition(disposition);
      if (fileName == null || fileName.trim().isEmpty) {
        await part.drain<void>();
        continue;
      }

      final cleanName = FileNameSafety.cleanFileName(fileName);
      final category = _categoryForUpload(
        cleanName,
        part.headers[HttpHeaders.contentTypeHeader],
      );
      final destination = await FileNameSafety.uniqueFile(File(p.join(
        await _categoryRoot(category),
        cleanName,
      )));

      var written = 0;
      final createdAt = DateTime.now();
      var progressItem = WirelessReceiveItem(
        name: cleanName,
        savedPath: destination.path,
        sizeBytes: 0,
        category: category,
        receivedAt: createdAt,
        progress: 0,
        complete: false,
      );
      _events.add(progressItem);

      final sink = destination.openWrite();
      try {
        await for (final List<int> chunk in part) {
          written += chunk.length;
          sink.add(chunk);
          progressItem = progressItem.copyWith(
            sizeBytes: written,
            progress: request.contentLength > 0
                ? (written / request.contentLength).clamp(0, 0.98).toDouble()
                : 0,
          );
          _events.add(progressItem);
        }
      } finally {
        await sink.close();
      }

      final completeItem = progressItem.copyWith(
        sizeBytes: written,
        progress: 1,
        complete: true,
      );
      received.add(completeItem);
      _events.add(completeItem);
    }

    if (received.isNotEmpty) {
      await saveWirelessHistory(_historyItem(received));
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'ok': true,
      'received': received.length,
    }));
    await request.response.close();
  }

  Future<String> _categoryRoot(TransferCategory category) async {
    if (Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      return switch (category) {
        TransferCategory.photos => p.join(
            directory.path,
            'GMP_Airdrop',
            'Wireless',
            'Photos',
          ),
        TransferCategory.videos => p.join(
            directory.path,
            'GMP_Airdrop',
            'Wireless',
            'Videos',
          ),
        TransferCategory.documents ||
        TransferCategory.code ||
        TransferCategory.others =>
          p.join(
            directory.path,
            'GMP_Airdrop',
            'Wireless',
            'Documents',
          ),
      };
    }

    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    return switch (category) {
      
      
      
     TransferCategory.photos =>
  p.join(userProfile, 'Pictures', 'GMP_Airdrop', 'Wireless', 'Photos'),

TransferCategory.videos =>
  p.join(userProfile, 'Pictures', 'GMP_Airdrop', 'Wireless', 'Videos'),

TransferCategory.documents ||
TransferCategory.code ||
TransferCategory.others =>
  p.join(
    userProfile,
    'Pictures',
    'GMP_Airdrop',
    'Wireless',
    'Documents',
  ),
  
  
  
    };
  }

  
  
  Future<int> _receiverAvailableBytes() async {
    if (Platform.isAndroid) {
      try {
        final value = await _androidChannel
            .invokeMethod<Object?>('getAppStorageFreeBytes');
        return _intValue(value);
      } on PlatformException {
        return -1;
      } on MissingPluginException {
        return -1;
      }
    }

    if (!Platform.isWindows) return -1;

    final roots = <String>{
      await _categoryRoot(TransferCategory.photos),
      await _categoryRoot(TransferCategory.videos),
      await _categoryRoot(TransferCategory.documents),
    };
    for (final root in roots) {
      await Directory(root).create(recursive: true);
    }

    final pathList =
        roots.map((path) => "'${path.replaceAll("'", "''")}'").join(',');
    final command = '''
\$paths = @($pathList)
\$values = foreach (\$path in \$paths) {
  New-Item -ItemType Directory -Force -Path \$path | Out-Null
  \$item = Get-Item -LiteralPath \$path
  ([System.IO.DriveInfo]\$item.PSDrive.Root).AvailableFreeSpace
}
(\$values | Measure-Object -Minimum).Minimum
''';
    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
      runInShell: false,
    );
    if (result.exitCode != 0) return -1;
    return int.tryParse(result.stdout.toString().trim()) ?? -1;
  }

  TransferCategory _categoryForExtension(String extension) {
    final folder = GmpFolderStructure.folderForExtension(extension);
    return TransferClassifier.categoryForFolder(folder);
  }

  TransferCategory _categoryForUpload(String fileName, String? contentType) {
    final extension = p.extension(fileName).toLowerCase();
    if (supportedVideoExtensions.contains(extension)) {
      return TransferCategory.videos;
    }

    final mimeType = contentType
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (mimeType != null && supportedVideoMimeTypes.contains(mimeType)) {
      return TransferCategory.videos;
    }

    return _categoryForExtension(extension);
  }

  String? _fileNameFromDisposition(String disposition) {
    final encoded = RegExp("filename\\*=UTF-8''([^;]+)", caseSensitive: false)
        .firstMatch(disposition)
        ?.group(1);
    if (encoded != null) return Uri.decodeComponent(encoded);

    final quoted = RegExp('filename="([^"]*)"', caseSensitive: false)
        .firstMatch(disposition)
        ?.group(1);
    if (quoted != null) return quoted;

    return RegExp('filename=([^;]+)', caseSensitive: false)
        .firstMatch(disposition)
        ?.group(1)
        ?.trim();
  }

  bool _validToken(String? token) {
    final expected = _token;
    return expected != null && token != null && token == expected;
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

  String _makeToken() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  TransferHistoryItem _historyItem(List<WirelessReceiveItem> items) {
    var photos = 0;
    var videos = 0;
    var documents = 0;
    for (final item in items) {
      switch (item.category) {
        case TransferCategory.photos:
          photos++;
        case TransferCategory.videos:
          videos++;
        case TransferCategory.documents:
        case TransferCategory.code:
        case TransferCategory.others:
          documents++;
      }
    }

    return TransferHistoryItem(
      title: 'Wireless receive',
      direction: TransferDirection.wirelessReceive,
      dateLabel: _formatDateTime(DateTime.now()),
      summary: FileCountSummary(
        photos: photos,
        videos: videos,
        documents: documents,
        code: 0,
      ),
      destination: Platform.isAndroid
          ? 'Local Wi-Fi to Android app GMP_Airdrop/Wireless folders'
          : 'Local Wi-Fi to GMP_Airdrop/Wireless folders',
    );
  }

  Future<File> _historyFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'wireless_history.json'));
  }

  Map<String, dynamic> _historyToJson(TransferHistoryItem item) {
    return {
      'title': item.title,
      'dateLabel': item.dateLabel,
      'destination': item.destination,
      'summary': {
        'photos': item.summary.photos,
        'videos': item.summary.videos,
        'documents': item.summary.documents,
        'code': item.summary.code,
      },
    };
  }

  TransferHistoryItem? _historyFromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    if (summary is! Map<String, dynamic>) return null;
    return TransferHistoryItem(
      title: json['title']?.toString() ?? 'Wireless receive',
      direction: TransferDirection.wirelessReceive,
      dateLabel: json['dateLabel']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      summary: FileCountSummary(
        photos: _intValue(summary['photos']),
        videos: _intValue(summary['videos']),
        documents: _intValue(summary['documents']),
        code: _intValue(summary['code']),
      ),
    );
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatBytes(int bytes) {
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _uploadPage(String token, int availableBytes) {
    final uploadUrl = '/upload?t=${Uri.encodeQueryComponent(token)}';
    const largeFileWarningBytes = WirelessReceiveService.largeFileWarningBytes;
    const maxUploadBytes = WirelessReceiveService.maxUploadBytes;
    final targetLabel = Platform.isAndroid ? 'Android device' : 'Windows PC';
    final receiverHint = Platform.isAndroid
        ? 'leave GMP Airdrop open on the Android receiver'
        : 'leave the Windows receiver open, and allow GMP Airdrop through Windows Firewall';
    final availableLabel =
        availableBytes >= 0 ? _formatBytes(availableBytes) : 'Unknown';
    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>GMP Airdrop Wireless Upload</title>
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
      --success: #16a36f;
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
    main { max-width: 720px; margin: 0 auto; padding: max(26px, env(safe-area-inset-top)) 18px 44px; }
    h1 { font-size: clamp(34px, 10vw, 52px); line-height: .98; letter-spacing: 0; margin: 14px 0 14px; }
    p { color: var(--muted); line-height: 1.55; font-size: 17px; margin: 0 0 22px; }
    .badge { display: inline-flex; padding: 8px 12px; border-radius: 999px; background: var(--blue-soft); color: var(--blue); font-weight: 800; font-size: 14px; }
    .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 24px; padding: 20px; box-shadow: 0 18px 48px var(--shadow); }
    .picker { border: 1.5px dashed var(--line); border-radius: 18px; padding: 18px; margin: 2px 0 16px; background: color-mix(in srgb, var(--blue-soft) 38%, transparent); }
    .picker + .picker { margin-top: 12px; }
    .picker label { display: block; font-weight: 800; margin-bottom: 8px; }
    input[type=file] { width: 100%; font-size: 16px; color: var(--muted); }
    button { width: 100%; border: 0; border-radius: 16px; background: var(--blue); color: #fff; font-weight: 800; font-size: 17px; padding: 16px 18px; box-shadow: 0 12px 24px rgba(21,95,214,.2); transition: transform .18s ease, opacity .18s ease; }
    button:active { transform: scale(.99); }
    button:disabled { opacity: .48; box-shadow: none; }
    progress { width: 100%; height: 12px; margin-top: 18px; accent-color: var(--blue); }
    ul { list-style: none; padding: 0; margin: 18px 0 0; }
    li { display: flex; justify-content: space-between; gap: 14px; padding: 12px 0; border-top: 1px solid var(--line); overflow-wrap: anywhere; color: var(--text); animation: rise .22s ease both; }
    .status { min-height: 24px; margin-top: 14px; font-weight: 750; color: var(--blue); }
    .space { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 0 0 16px; }
    .space div { border: 1px solid var(--line); border-radius: 14px; padding: 12px; background: color-mix(in srgb, var(--blue-soft) 32%, transparent); }
    .space b { display: block; color: var(--text); margin-top: 4px; }
    .warning { color: #9a5b00; font-weight: 700; }
    .done { color: var(--success); }
    @media (max-width: 520px) { .space { grid-template-columns: 1fr; } }
    @keyframes rise { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
  </style>
</head>
<body>
  <main>
    <span class="badge">Local Wi-Fi only</span>
    <h1>Send to GMP Airdrop</h1>
    <p>Select photos, videos, or files from this phone. They upload directly to the $targetLabel on this Wi-Fi network.</p>
    <section class="panel">
      <div class="space">
        <div><span>Required</span><b id="required">0 B</b></div>
        <div><span>Receiver available</span><b>$availableLabel</b></div>
      </div>
      <form id="form">
        <!-- Do not use image/*, video/*, or capture in iOS WebView because it shows "Take Photo or Video" and crashes on some devices. -->
        <div class="picker">
          <label for="photoFiles">Photo Library</label>
          <input id="photoFiles" name="files" type="file" multiple accept=".jpg,.jpeg,.png,.gif,.webp,.heic,.heif,.bmp,.tif,.tiff">
        </div>
        <div class="picker">
          <label for="documentFiles">Choose Files</label>
          <input id="documentFiles" name="files" type="file" multiple accept=".jpg,.jpeg,.png,.gif,.webp,.heic,.heif,.bmp,.tif,.tiff,.mp4,.mov,.m4v,.avi,.mkv,.pdf,.zip,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt">
        </div>
        <button id="send" type="submit">Send files</button>
      </form>
      <progress id="progress" value="0" max="100"></progress>
      <p id="status" class="status"></p>
      <ul id="list"></ul>
    </section>
  </main>
  <script>
    const form = document.getElementById('form');
    const photoInput = document.getElementById('photoFiles');
    const documentInput = document.getElementById('documentFiles');
    const inputs = [photoInput, documentInput];
    const send = document.getElementById('send');
    const progress = document.getElementById('progress');
    const status = document.getElementById('status');
    const list = document.getElementById('list');
    const required = document.getElementById('required');
    const receiverFreeBytes = $availableBytes;
    let selectedTotal = 0;
    inputs.forEach((input) => input.addEventListener('change', updateSelection));
    function selectedFiles() {
      return inputs.flatMap((input) => Array.from(input.files || []));
    }
    function updateSelection() {
      list.innerHTML = '';
      selectedTotal = 0;
      let hasLargeFile = false;
      const files = selectedFiles();
      for (const file of files) {
        selectedTotal += file.size;
        if (file.size >= $largeFileWarningBytes) hasLargeFile = true;
        const item = document.createElement('li');
        item.innerHTML = '<span>' + escapeHtml(file.name) + '</span><strong>' + formatBytes(file.size) + '</strong>';
        list.appendChild(item);
      }
      required.textContent = formatBytes(selectedTotal);
      if (receiverFreeBytes >= 0 && selectedTotal > receiverFreeBytes) {
        send.disabled = true;
        status.className = 'status warning';
        status.textContent = 'Transfer blocked. Required: ' + formatBytes(selectedTotal) + '. Receiver available: ' + formatBytes(receiverFreeBytes) + '.';
      } else if (selectedTotal > $maxUploadBytes) {
        send.disabled = true;
        status.className = 'status warning';
        status.textContent = 'Transfer blocked. This upload is over 10 GB. Send fewer files at once or move very large videos by USB.';
      } else if (hasLargeFile || selectedTotal >= $largeFileWarningBytes) {
        send.disabled = false;
        status.className = 'status warning';
        status.textContent = 'Large upload selected. Keep this phone awake and near Wi-Fi until transfer completes.';
      } else {
        send.disabled = false;
        status.className = 'status';
        status.textContent = files.length ? files.length + ' file(s) ready.' : '';
      }
    }
    form.addEventListener('submit', (event) => {
      event.preventDefault();
      const files = selectedFiles();
      if (!files.length) {
        status.textContent = 'Choose files first.';
        return;
      }
      if (receiverFreeBytes >= 0 && selectedTotal > receiverFreeBytes) {
        status.className = 'status warning';
        status.textContent = 'Transfer blocked. Required: ' + formatBytes(selectedTotal) + '. Receiver available: ' + formatBytes(receiverFreeBytes) + '.';
        return;
      }
      if (selectedTotal > $maxUploadBytes) {
        status.className = 'status warning';
        status.textContent = 'Transfer blocked. This upload is over 10 GB. Send fewer files at once or move very large videos by USB.';
        return;
      }
      const data = new FormData();
      for (const file of files) data.append('files', file, file.name);
      const xhr = new XMLHttpRequest();
      xhr.open('POST', '$uploadUrl');
      xhr.upload.onprogress = (event) => {
        if (!event.lengthComputable) return;
        progress.value = Math.round((event.loaded / event.total) * 100);
        status.textContent = 'Uploading ' + progress.value + '%';
      };
      xhr.onload = () => {
        send.disabled = false;
        let payload = {};
        try { payload = JSON.parse(xhr.responseText || '{}'); } catch (_) {}
        if (xhr.status >= 200 && xhr.status < 300) {
          progress.value = 100;
          status.className = 'status done';
          const count = payload.received || files.length;
          status.textContent = count + ' file(s) uploaded to the $targetLabel.';
          form.reset();
          updateSelection();
        } else {
          status.className = 'status warning';
          status.textContent = payload.message || 'Upload failed. Check the receiver is still open and both devices are on the same Wi-Fi.';
        }
      };
      xhr.onerror = () => {
        send.disabled = false;
        status.className = 'status warning';
        status.textContent = 'Connection failed. Keep both devices on the same Wi-Fi, $receiverHint.';
      };
      send.disabled = true;
      progress.value = 0;
      status.className = 'status';
      status.textContent = 'Starting upload...';
      xhr.send(data);
    });
    function formatBytes(bytes) {
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      let size = bytes;
      let unit = 0;
      while (size >= 1024 && unit < units.length - 1) {
        size /= 1024;
        unit++;
      }
      return (unit === 0 || size >= 10 ? size.toFixed(0) : size.toFixed(1)) + ' ' + units[unit];
    }
    function escapeHtml(value) {
      return value.replace(/[&<>"']/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));
    }
  </script>
</body>
</html>
''';
  }
}
