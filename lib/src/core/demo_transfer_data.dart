import 'file_count_summary.dart';
import 'transfer_models.dart';

class DemoTransferData {
  static const drive = UsbDrive(
    label: 'Samsung 256GB',
    path: 'E:\\GMP_Airdrop',
    capacityLabel: '256 GB',
    freeLabel: '176 GB free',
    hasGmpFolder: true,
  );

  static final files = [
    TransferClassifier.fromName('IMG_4821.HEIC', '4.8 MB', 'Today'),
    TransferClassifier.fromName('Family_video.MOV', '182 MB', 'Today'),
    TransferClassifier.fromName('Invoice_2026.pdf', '560 KB', 'Yesterday'),
    TransferClassifier.fromName('Project_notes.md', '18 KB', 'Yesterday'),
    TransferClassifier.fromName('Budget.xlsx', '94 KB', 'Apr 28'),
    TransferClassifier.fromName('backup_script.py', '12 KB', 'Apr 27'),
    TransferClassifier.fromName('Travel_photo.jpg', '3.2 MB', 'Apr 26'),
    TransferClassifier.fromName('Presentation.pptx', '2.4 MB', 'Apr 20'),
  ];

  static final history = [
    TransferHistoryItem(
      title: 'Export to USB Drive',
      direction: TransferDirection.exportToUsb,
      dateLabel: 'Today, 10:42 AM',
      summary: const FileCountSummary(
        photos: 24,
        videos: 3,
        documents: 2,
        code: 1,
      ),
      destination: 'E:\\GMP_Airdrop',
    ),
    TransferHistoryItem(
      title: 'Import to Windows PC',
      direction: TransferDirection.importToPc,
      dateLabel: 'Yesterday, 5:18 PM',
      summary: const FileCountSummary(
        photos: 156,
        videos: 48,
        documents: 62,
        code: 12,
      ),
      destination: 'C:\\Users\\GMP\\GMP Airdrop',
    ),
  ];
}
