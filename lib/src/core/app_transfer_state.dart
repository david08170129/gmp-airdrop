import 'dart:async';
import 'dart:io';

import 'demo_transfer_data.dart';
import 'file_count_summary.dart';
import '../features/android/android_export_service.dart';
import '../features/wireless/wireless_receive_service.dart';
import '../features/windows/windows_import_service.dart';
import 'transfer_models.dart';

class AppTransferState {
  AppTransferState({
    List<TransferFile>? selectedFiles,
    List<TransferHistoryItem>? history,
    this.detectedDrive,
    this.exportProgress = 0,
    this.importProgress = 0,
  })  : selectedFiles = selectedFiles ?? <TransferFile>[],
        history = history ?? <TransferHistoryItem>[];

  final List<TransferFile> selectedFiles;
  final List<TransferHistoryItem> history;
  final AndroidExportService androidExportService = AndroidExportService();
  final WindowsImportService windowsImportService = WindowsImportService();
  final WirelessReceiveService wirelessReceiveService =
      WirelessReceiveService();
  final List<WirelessReceiveItem> wirelessReceivedFiles =
      <WirelessReceiveItem>[];
  StreamSubscription<WirelessReceiveItem>? _wirelessSubscription;
  AndroidExportDestination? androidExportDestination;
  UsbDrive? detectedDrive;
  WindowsImportScanResult? windowsImportScan;
  WirelessReceiveSession? wirelessSession;
  double exportProgress;
  double importProgress;

  FileCountSummary get selectedSummary {
    return TransferClassifier.summarize(selectedFiles);
  }

  FileCountSummary get importSummary {
    return windowsImportScan?.summary ?? FileCountSummary.empty;
  }

  List<TransferFile> get importFiles {
    return windowsImportScan?.files ?? const [];
  }

  Future<void> scanWindowsImport() async {
    final scan = await windowsImportService.detectGmpDrive();
    windowsImportScan = scan;
    detectedDrive = scan?.drive;
    importProgress = 0;
  }

  Future<void> loadWindowsImportHistory() async {
    final savedHistory = await windowsImportService.loadImportHistory();
    for (final item in savedHistory.reversed) {
      final alreadyLoaded = history.any(
        (existing) =>
            existing.direction == item.direction &&
            existing.dateLabel == item.dateLabel &&
            existing.destination == item.destination,
      );
      if (!alreadyLoaded) history.insert(0, item);
    }
  }

  Future<void> loadWirelessReceiveHistory() async {
    final savedHistory = await wirelessReceiveService.loadWirelessHistory();
    for (final item in savedHistory.reversed) {
      final alreadyLoaded = history.any(
        (existing) =>
            existing.direction == item.direction &&
            existing.dateLabel == item.dateLabel &&
            existing.destination == item.destination,
      );
      if (!alreadyLoaded) history.insert(0, item);
    }
  }

  Future<void> loadAndroidExportHistory() async {
    final savedHistory = await androidExportService.loadExportHistory();
    for (final item in savedHistory.reversed) {
      final alreadyLoaded = history.any(
        (existing) =>
            existing.direction == item.direction &&
            existing.dateLabel == item.dateLabel &&
            existing.destination == item.destination,
      );
      if (!alreadyLoaded) history.insert(0, item);
    }
  }

  Future<WirelessReceiveSession> startWirelessReceive({
    required void Function(WirelessReceiveItem item) onItem,
  }) async {
    wirelessSession = await wirelessReceiveService.start();
    await _wirelessSubscription?.cancel();
    _wirelessSubscription = wirelessReceiveService.events.listen((item) {
      final index = wirelessReceivedFiles.indexWhere(
        (existing) =>
            existing.name == item.name &&
            existing.savedPath == item.savedPath &&
            existing.receivedAt == item.receivedAt,
      );
      final wasComplete = index != -1 && wirelessReceivedFiles[index].complete;
      if (index == -1) {
        wirelessReceivedFiles.insert(0, item);
      } else {
        wirelessReceivedFiles[index] = item;
      }
      if (item.complete && !wasComplete) {
        history.insert(0, _wirelessHistoryItem(item));
      }
      onItem(item);
    });
    return wirelessSession!;
  }

  Future<void> stopWirelessReceive() async {
    await _wirelessSubscription?.cancel();
    _wirelessSubscription = null;
    await wirelessReceiveService.stop();
    wirelessSession = null;
  }

  Future<void> receiveWirelessLocalFiles(List<File> files) async {
    if (_wirelessSubscription == null) {
      await startWirelessReceive(onItem: (_) {});
    }
    await wirelessReceiveService.receiveLocalFiles(files);
  }

  TransferHistoryItem _wirelessHistoryItem(WirelessReceiveItem item) {
    final summary = switch (item.category) {
      TransferCategory.photos => const FileCountSummary(
          photos: 1,
          videos: 0,
          documents: 0,
          code: 0,
        ),
      TransferCategory.videos => const FileCountSummary(
          photos: 0,
          videos: 1,
          documents: 0,
          code: 0,
        ),
      TransferCategory.documents ||
      TransferCategory.code ||
      TransferCategory.others =>
        const FileCountSummary(
          photos: 0,
          videos: 0,
          documents: 1,
          code: 0,
        ),
    };

    return TransferHistoryItem(
      title: 'Wireless receive complete: ${item.name}',
      direction: TransferDirection.wirelessReceive,
      dateLabel: _formatDateTime(item.receivedAt),
      summary: summary,
      destination: item.savedPath,
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> pickAndroidExportFiles(TransferCategory category) async {
    final files = await androidExportService.pickFiles(category);
    selectedFiles.addAll(files);
  }

  Future<void> chooseAndroidExportDestination() async {
    final destination = await androidExportService.chooseDestination();
    if (destination == null) return;
    androidExportDestination = destination;
    detectedDrive = UsbDrive(
      label: destination.label,
      path: '${destination.label}/GMP_Airdrop',
      capacityLabel: '',
      freeLabel: '',
      hasGmpFolder: true,
    );
    exportProgress = 0;
  }

  Future<List<String>> createAndroidFolderStructure() async {
    var destination = androidExportDestination;
    if (destination == null) {
      destination = await androidExportService.chooseDestination();
      if (destination == null) return const [];
      androidExportDestination = destination;
    }

    final folders =
        await androidExportService.createFolderStructure(destination);
    detectedDrive = UsbDrive(
      label: destination.label,
      path: '${destination.label}/GMP_Airdrop',
      capacityLabel: '',
      freeLabel: '',
      hasGmpFolder: folders.isNotEmpty,
    );
    return folders;
  }

  void scanDrive() {
    detectedDrive = DemoTransferData.drive;
  }

  void createFolderStructure() {
    detectedDrive = DemoTransferData.drive;
  }

  Future<void> exportAndroidFiles({
    required void Function(double progress) onProgress,
  }) async {
    final destination = androidExportDestination;
    if (destination == null || selectedFiles.isEmpty) return;

    exportProgress = 0;
    final subscription = androidExportService.progressStream.listen((progress) {
      exportProgress = progress;
      onProgress(progress);
    });
    try {
      final item = await androidExportService.exportFiles(
        files: selectedFiles,
        destination: destination,
      );
      exportProgress = 1;
      onProgress(1);
      if (item != null) history.insert(0, item);
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> importWindowsFiles({
    required void Function(double progress) onProgress,
  }) async {
    final scan = windowsImportScan;
    if (scan == null) return;

    importProgress = 0;
    final item = await windowsImportService.importFiles(
      scan,
      onProgress: (progress) {
        importProgress = progress;
        onProgress(progress);
      },
    );
    if (item == null) return;

    history.insert(
      0,
      item,
    );
  }
}
