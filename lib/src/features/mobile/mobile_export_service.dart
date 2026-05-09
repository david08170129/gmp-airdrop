import 'package:file_picker/file_picker.dart';

enum MediaKind { photos, videos, files }

class MobileExportService {
  Future<int> pickFiles(MediaKind kind) async {
    final type = switch (kind) {
      MediaKind.photos => FileType.image,
      MediaKind.videos => FileType.video,
      MediaKind.files => FileType.any,
    };

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type,
    );

    return result?.files.length ?? 0;
  }

  Future<void> exportToUsb() async {
    // Platform-specific USB write permissions will be implemented per target.
    // iOS: Files app/document picker destination.
    // Android: Storage Access Framework for external USB volumes.
    // Windows: direct filesystem copy to removable drive.
  }
}
