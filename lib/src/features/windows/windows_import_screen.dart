import 'package:flutter/material.dart';

import '../../core/file_count_summary.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import 'windows_import_service.dart';

class WindowsImportScreen extends StatefulWidget {
  const WindowsImportScreen({super.key});

  @override
  State<WindowsImportScreen> createState() => _WindowsImportScreenState();
}

class _WindowsImportScreenState extends State<WindowsImportScreen> {
  final _service = WindowsImportService();
  FileCountSummary _summary = FileCountSummary.empty;
  WindowsImportScanResult? _scan;
  bool _driveReady = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.windowsImport,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: GmpColors.text,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _detectDrive,
                  icon: const Icon(Icons.usb_rounded),
                  label: Text(l10n.detectDrive),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _driveReady
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _driveReady ? GmpColors.success : GmpColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Text(_driveReady ? l10n.driveReady : 'Waiting for drive'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fileCounts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CountTile(label: 'Photos', value: _summary.photos),
                    _CountTile(label: 'Videos', value: _summary.videos),
                    _CountTile(label: 'Documents', value: _summary.documents),
                    _CountTile(label: 'Code', value: _summary.code),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _driveReady ? _importFiles : null,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l10n.importFiles),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.search,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                const Text('No imports yet'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _detectDrive() async {
    final scan = await _service.detectGmpDrive();
    setState(() {
      _scan = scan;
      _summary = scan?.summary ?? FileCountSummary.empty;
      _driveReady = scan != null;
    });
  }

  Future<void> _importFiles() async {
    final scan = _scan;
    if (scan == null) return;
    await _service.importFiles(scan, onProgress: (_) {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import complete: ${scan.summary.total} files saved into Windows GMP_Airdrop folders',
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: GmpColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
