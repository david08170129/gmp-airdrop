import 'dart:io';

import 'package:flutter/services.dart';

enum IosPickerKind { photos, videos, files }

class IosPickedFile {
  const IosPickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.type,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String type;

  File get file => File(path);
}

class IosNativePickerService {
  static const _channel = MethodChannel('gmp_airdrop/ios_picker');

  Future<List<IosPickedFile>> pick(IosPickerKind kind) async {
    if (!Platform.isIOS) return const [];

    final result = await _channel.invokeMethod<List<Object?>>(
      'pickFiles',
      {'kind': kind.name},
    );

    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(_fromNative)
        .where((file) => file.path.isNotEmpty)
        .toList();
  }

  IosPickedFile _fromNative(Map<Object?, Object?> item) {
    return IosPickedFile(
      path: item['path']?.toString() ?? '',
      name: item['name']?.toString() ?? 'Selected file',
      sizeBytes: int.tryParse(item['size']?.toString() ?? '') ?? 0,
      type: item['type']?.toString() ?? '',
    );
  }
}
