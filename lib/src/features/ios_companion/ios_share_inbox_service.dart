import 'dart:io';

import 'package:flutter/services.dart';

class IosSharedBatch {
  const IosSharedBatch({
    required this.id,
    required this.receivedAt,
    required this.items,
    required this.inboxFileName,
  });

  final String id;
  final DateTime? receivedAt;
  final List<IosSharedItem> items;
  final String inboxFileName;
}

class IosSharedItem {
  const IosSharedItem({
    required this.type,
    required this.name,
    required this.path,
    required this.uti,
    required this.exists,
    required this.sizeBytes,
    this.message,
  });

  final String type;
  final String name;
  final String path;
  final String uti;
  final bool exists;
  final int sizeBytes;
  final String? message;

  File get file => File(path);
}

class IosShareInboxService {
  static const _channel = MethodChannel('gmp_airdrop/ios_share_inbox');

  Future<List<IosSharedBatch>> getSharedInbox() async {
    if (!Platform.isIOS) return const [];

    final result = await _channel.invokeMethod<List<Object?>>(
      'getSharedInbox',
    );

    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(_batchFromNative)
        .where((batch) => batch.id.isNotEmpty)
        .toList();
  }

  Future<bool> clearSharedInbox(List<String> ids) async {
    if (!Platform.isIOS) return false;

    final result = await _channel.invokeMethod<bool>(
      'clearSharedInbox',
      {'ids': ids},
    );
    return result ?? false;
  }

  IosSharedBatch _batchFromNative(Map<Object?, Object?> json) {
    final items = json['items'];
    return IosSharedBatch(
      id: json['id']?.toString() ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? ''),
      inboxFileName: json['inboxFileName']?.toString() ?? '',
      items: items is List
          ? items
              .whereType<Map<Object?, Object?>>()
              .map(_itemFromNative)
              .toList()
          : const [],
    );
  }

  IosSharedItem _itemFromNative(Map<Object?, Object?> json) {
    final originalName = json['originalName']?.toString();
    final fileName = json['fileName']?.toString();
    final text = json['text']?.toString();
    final url = json['url']?.toString();
    return IosSharedItem(
      type: json['type']?.toString() ?? 'file',
      name: _firstNotEmpty([originalName, fileName, text, url, 'Shared item']),
      path: json['path']?.toString() ?? '',
      uti: json['uti']?.toString() ?? '',
      exists: json['exists'] == true,
      sizeBytes: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      message: json['message']?.toString(),
    );
  }

  String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return 'Shared item';
  }
}
