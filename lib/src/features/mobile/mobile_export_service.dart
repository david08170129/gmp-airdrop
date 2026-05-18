import 'package:file_picker/file_picker.dart';

enum MediaKind { photos, videos, files }

class MobileExportPickResult {
  const MobileExportPickResult({
    required this.count,
    required this.totalBytes,
    this.tooLargeCount = 0,
  });

  final int count;
  final int totalBytes;
  final int tooLargeCount;
}

class MobileExportService {
  static const maxVideoBytes = 10 * 1024 * 1024 * 1024;

  Future<MobileExportPickResult> pickFiles(MediaKind kind) async {
    final type = switch (kind) {
      MediaKind.photos => FileType.image,
      MediaKind.videos => FileType.video,
      MediaKind.files => FileType.any,
    };

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type,
      withData: false,
      withReadStream: true,
    );

    final files = result?.files ?? const <PlatformFile>[];
    final tooLargeCount = kind == MediaKind.videos
        ? files.where((file) => file.size > maxVideoBytes).length
        : 0;
    return MobileExportPickResult(
      count: files.length,
      totalBytes: files.fold<int>(0, (total, file) => total + file.size),
      tooLargeCount: tooLargeCount,
    );
  }

  Future<void> exportToUsb() async {
    // Platform-specific USB write permissions will be implemented per target.
    // iOS: Files app/document picker destination.
    // Android: Storage Access Framework for external USB volumes.
    // Windows: direct filesystem copy to removable drive.
  }
}
