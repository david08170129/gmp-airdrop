import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/file_name_safety.dart';
import '../../core/file_count_summary.dart';
import '../../core/gmp_folder_structure.dart';
import '../../core/transfer_models.dart';

class WindowsImportScanResult {
  const WindowsImportScanResult({
    required this.drive,
    required this.files,
    required this.summary,
  });

  final UsbDrive drive;
  final List<TransferFile> files;
  final FileCountSummary summary;
}

class WindowsImportService {
  Future<WindowsImportScanResult?> detectGmpDrive() async {
    if (!Platform.isWindows) return null;

    final drives = await _readWindowsDrives();
    for (final drive in drives) {
      final root = drive.path;
      final gmpRoot = Directory(p.join(root, GmpFolderStructure.root));
      if (!await gmpRoot.exists()) continue;

      final files = await _scanFiles(gmpRoot.path);
      return WindowsImportScanResult(
        drive: UsbDrive(
          label: drive.label,
          path: gmpRoot.path,
          capacityLabel: _formatBytes(drive.sizeBytes),
          freeLabel: _formatBytes(drive.freeBytes),
          hasGmpFolder: true,
        ),
        files: files,
        summary: TransferClassifier.summarize(files),
      );
    }

    return null;
  }

  Future<TransferHistoryItem?> importFiles(
    WindowsImportScanResult scan, {
    required void Function(double progress) onProgress,
  }) async {
    final files = scan.files.where((file) => file.sourcePath != null).toList();
    if (files.isEmpty) {
      onProgress(1);
      return null;
    }

    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final picturesRoot = p.join(userProfile, 'Pictures', GmpFolderStructure.root);
    final videosRoot = p.join(userProfile, 'Videos', GmpFolderStructure.root);
    final documentsRoot =
        p.join(userProfile, 'Documents', GmpFolderStructure.root);

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final source = File(file.sourcePath!);
      if (!await source.exists()) {
        onProgress((index + 1) / files.length);
        continue;
      }

      final destinationRoot = switch (file.category) {
        TransferCategory.photos => picturesRoot,
        TransferCategory.videos => videosRoot,
        TransferCategory.documents => documentsRoot,
        TransferCategory.code => p.join(documentsRoot, 'Code'),
        TransferCategory.others => p.join(documentsRoot, 'Others'),
      };
      final relativePath = FileNameSafety.safeRelativePath(_targetRelativePath(file));
      final destination =
          await FileNameSafety.uniqueFile(File(p.join(destinationRoot, relativePath)));
      await source.copy(destination.path);
      onProgress((index + 1) / files.length);
    }

    final historyItem = TransferHistoryItem(
      title: 'Import to Windows PC',
      direction: TransferDirection.importToPc,
      dateLabel: _formatDateTime(DateTime.now()),
      summary: scan.summary,
      destination: 'Pictures, Videos, Documents GMP_Airdrop folders',
    );
    await saveImportHistory(historyItem);
    return historyItem;
  }

  Future<List<TransferHistoryItem>> loadImportHistory() async {
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

  Future<void> saveImportHistory(TransferHistoryItem item) async {
    final history = await loadImportHistory();
    history.insert(0, item);
    final file = await _historyFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        history.take(80).map(_historyToJson).toList(),
      ),
    );
  }

  Future<List<_WindowsDrive>> _readWindowsDrives() async {
    final command = '''
\$drives = Get-CimInstance Win32_LogicalDisk |
  Where-Object { \$_.DriveType -eq 2 -or \$_.DriveType -eq 3 } |
  Select-Object DeviceID, VolumeName, FreeSpace, Size, DriveType
\$drives | ConvertTo-Json -Compress
''';

    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
      runInShell: false,
    );
    if (result.exitCode != 0) return [];

    final output = result.stdout.toString().trim();
    if (output.isEmpty) return [];

    try {
      final decoded = jsonDecode(output);
      final items = decoded is List ? decoded : [decoded];
      return items
          .whereType<Map<String, dynamic>>()
          .map(_WindowsDrive.fromJson)
          .where((drive) => drive.rootExists)
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<List<TransferFile>> _scanFiles(String gmpRoot) async {
    final entries = <TransferFile>[];
    final folders = {
      'Photos': TransferCategory.photos,
      'Videos': TransferCategory.videos,
      'Documents': TransferCategory.documents,
      'Code': TransferCategory.code,
    };

    for (final folder in folders.entries) {
      final directory = Directory(p.join(gmpRoot, folder.key));
      if (!await directory.exists()) continue;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        final relativePath = p.relative(entity.path, from: directory.path);
        entries.add(
          TransferFile(
            name: p.basename(entity.path),
            sizeLabel: _formatBytes(stat.size),
            modifiedLabel: _formatDateTime(stat.modified),
            category: folder.value,
            targetFolder: p.join(GmpFolderStructure.root, folder.key),
            sizeBytes: stat.size,
            sourcePath: entity.path,
            relativePath: relativePath,
          ),
        );
      }
    }

    entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entries;
  }

  String _targetRelativePath(TransferFile file) {
    final relative = file.relativePath;
    if (relative == null || relative.trim().isEmpty) return file.name;
    return relative;
  }

  Future<File> _historyFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'import_history.json'));
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
      title: json['title']?.toString() ?? 'Import to Windows PC',
      direction: TransferDirection.importToPc,
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
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
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
}

class _WindowsDrive {
  const _WindowsDrive({
    required this.deviceId,
    required this.volumeName,
    required this.freeBytes,
    required this.sizeBytes,
  });

  factory _WindowsDrive.fromJson(Map<String, dynamic> json) {
    final deviceId = json['DeviceID']?.toString() ?? '';
    final volumeName = json['VolumeName']?.toString() ?? '';
    return _WindowsDrive(
      deviceId: deviceId,
      volumeName: volumeName,
      freeBytes: int.tryParse(json['FreeSpace']?.toString() ?? '') ?? 0,
      sizeBytes: int.tryParse(json['Size']?.toString() ?? '') ?? 0,
    );
  }

  final String deviceId;
  final String volumeName;
  final int freeBytes;
  final int sizeBytes;

  String get path => '$deviceId\\';
  String get label => volumeName.isEmpty ? '$deviceId USB Drive' : volumeName;
  bool get rootExists => deviceId.isNotEmpty && Directory(path).existsSync();
}
