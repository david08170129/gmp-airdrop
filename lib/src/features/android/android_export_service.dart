import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/file_count_summary.dart';
import '../../core/gmp_folder_structure.dart';
import '../../core/transfer_models.dart';

class AndroidExportDestination {
  const AndroidExportDestination({
    required this.uri,
    required this.label,
  });

  final String uri;
  final String label;
}

class AndroidExportService {
  AndroidExportService() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const _channel = MethodChannel('gmp_airdrop/android_export');
  final _progressController = StreamController<double>.broadcast();

  Stream<double> get progressStream => _progressController.stream;

  Future<List<TransferFile>> pickFiles(TransferCategory category) async {
    if (!Platform.isAndroid) return [];
    final result = await _channel.invokeMethod<List<Object?>>(
      'pickFiles',
      {'category': category.name},
    );
    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((item) => _fileFromNative(item, category))
        .toList();
  }

  Future<AndroidExportDestination?> chooseDestination() async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'chooseDestination',
    );
    if (result == null) return null;
    return AndroidExportDestination(
      uri: result['uri']?.toString() ?? '',
      label: result['label']?.toString() ?? 'USB-C destination',
    );
  }

  Future<List<String>> createFolderStructure(
    AndroidExportDestination destination,
  ) async {
    if (!Platform.isAndroid) return [];
    final result = await _channel.invokeMethod<List<Object?>>(
      'createFolderStructure',
      {'destinationUri': destination.uri},
    );
    return (result ?? const []).map((item) => item.toString()).toList();
  }

  Future<TransferHistoryItem?> exportFiles({
    required List<TransferFile> files,
    required AndroidExportDestination destination,
  }) async {
    if (!Platform.isAndroid || files.isEmpty) return null;

    final payload = files
        .where((file) => file.sourcePath != null)
        .map(
          (file) => {
            'uri': file.sourcePath,
            'name': file.name,
            'targetFolder': file.targetFolder,
          },
        )
        .toList();
    if (payload.isEmpty) return null;

    await _channel.invokeMethod<void>('exportFiles', {
      'destinationUri': destination.uri,
      'files': payload,
    });

    final item = TransferHistoryItem(
      title: 'Export to USB Drive',
      direction: TransferDirection.exportToUsb,
      dateLabel: _formatDateTime(DateTime.now()),
      summary: TransferClassifier.summarize(files),
      destination: '${destination.label}/${GmpFolderStructure.root}',
    );
    await saveExportHistory(item);
    return item;
  }

  Future<List<TransferHistoryItem>> loadExportHistory() async {
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

  Future<void> saveExportHistory(TransferHistoryItem item) async {
    final history = await loadExportHistory();
    history.insert(0, item);
    final file = await _historyFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        history.take(80).map(_historyToJson).toList(),
      ),
    );
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'exportProgress') {
      final progress = (call.arguments as num?)?.toDouble() ?? 0;
      _progressController.add(progress.clamp(0, 1));
    }
  }

  TransferFile _fileFromNative(
    Map<Object?, Object?> item,
    TransferCategory requestedCategory,
  ) {
    final name = item['name']?.toString() ?? 'Untitled';
    final size = int.tryParse(item['size']?.toString() ?? '') ?? 0;
    final folder = GmpFolderStructure.folderForExtension(_extension(name));
    return TransferFile(
      name: name,
      sizeLabel: _formatBytes(size),
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

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1);
  }

  Future<File> _historyFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/export_history.json');
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
      title: json['title']?.toString() ?? 'Export to USB Drive',
      direction: TransferDirection.exportToUsb,
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
