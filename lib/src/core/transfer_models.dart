import 'file_count_summary.dart';
import 'gmp_folder_structure.dart';

enum TransferCategory { photos, videos, documents, code, others }

enum TransferDirection { exportToUsb, importToPc, wirelessReceive }

class TransferFile {
  const TransferFile({
    required this.name,
    required this.sizeLabel,
    required this.modifiedLabel,
    required this.category,
    required this.targetFolder,
    this.sizeBytes = 0,
    this.sourcePath,
    this.relativePath,
  });

  final String name;
  final String sizeLabel;
  final String modifiedLabel;
  final TransferCategory category;
  final String targetFolder;
  final int sizeBytes;
  final String? sourcePath;
  final String? relativePath;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

class UsbDrive {
  const UsbDrive({
    required this.label,
    required this.path,
    required this.capacityLabel,
    required this.freeLabel,
    required this.hasGmpFolder,
  });

  final String label;
  final String path;
  final String capacityLabel;
  final String freeLabel;
  final bool hasGmpFolder;
}

class TransferHistoryItem {
  const TransferHistoryItem({
    required this.title,
    required this.direction,
    required this.dateLabel,
    required this.summary,
    required this.destination,
  });

  final String title;
  final TransferDirection direction;
  final String dateLabel;
  final FileCountSummary summary;
  final String destination;
}

class TransferClassifier {
  static TransferFile fromName(String name, String size, String modified) {
    final extension = name.contains('.') ? name.split('.').last : '';
    final folder = GmpFolderStructure.folderForExtension(extension);
    return TransferFile(
      name: name,
      sizeLabel: size,
      modifiedLabel: modified,
      category: categoryForFolder(folder),
      targetFolder: folder,
    );
  }

  static TransferCategory categoryForFolder(String folder) {
    if (folder == GmpFolderStructure.photos) return TransferCategory.photos;
    if (folder == GmpFolderStructure.videos) return TransferCategory.videos;
    if (folder == GmpFolderStructure.python) return TransferCategory.code;
    if (folder.startsWith('${GmpFolderStructure.root}/Documents')) {
      return TransferCategory.documents;
    }
    return TransferCategory.others;
  }

  static FileCountSummary summarize(List<TransferFile> files) {
    var photos = 0;
    var videos = 0;
    var documents = 0;
    var code = 0;
    for (final file in files) {
      switch (file.category) {
        case TransferCategory.photos:
          photos++;
        case TransferCategory.videos:
          videos++;
        case TransferCategory.documents:
          documents++;
        case TransferCategory.code:
          code++;
        case TransferCategory.others:
          documents++;
      }
    }
    return FileCountSummary(
      photos: photos,
      videos: videos,
      documents: documents,
      code: code,
    );
  }
}
