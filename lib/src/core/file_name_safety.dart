import 'dart:io';

import 'package:path/path.dart' as p;

class FileNameSafety {
  static const _fallbackName = 'Untitled';
  static const _maxNameLength = 180;

  static String cleanFileName(String value) {
    final base = p.basename(value).trim();
    final cleaned = base
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();
    return _limitLength(cleaned.isEmpty ? _fallbackName : cleaned);
  }

  static String cleanPathSegment(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();
    return _limitLength(cleaned.isEmpty ? _fallbackName : cleaned);
  }

  static String safeRelativePath(String value) {
    final normalized = p.split(value.replaceAll('\\', '/'));
    final segments = normalized
        .where((segment) =>
            segment.isNotEmpty && segment != '.' && segment != '..')
        .map(cleanPathSegment)
        .toList();
    if (segments.isEmpty) return _fallbackName;
    return p.joinAll(segments);
  }

  static Future<File> uniqueFile(File target) async {
    final directory = target.parent;
    await directory.create(recursive: true);

    final safeName = cleanFileName(p.basename(target.path));
    final existing = await _existingNames(directory);
    if (!existing.contains(safeName.toLowerCase())) {
      return File(p.join(directory.path, safeName));
    }

    final extension = p.extension(safeName);
    final basename = p.basenameWithoutExtension(safeName);
    var index = 1;

    while (true) {
      final candidateName = _limitLength('$basename ($index)$extension');
      if (!existing.contains(candidateName.toLowerCase())) {
        return File(p.join(directory.path, candidateName));
      }
      index++;
    }
  }

  static Future<Set<String>> _existingNames(Directory directory) async {
    if (!await directory.exists()) return <String>{};
    return directory
        .list()
        .map((entity) => p.basename(entity.path).toLowerCase())
        .toSet();
  }

  static String _limitLength(String name) {
    if (name.length <= _maxNameLength) return name;
    final extension = p.extension(name);
    final basename = p.basenameWithoutExtension(name);
    final keep = (_maxNameLength - extension.length).clamp(20, _maxNameLength);
    return '${basename.substring(0, keep)}$extension';
  }
}
