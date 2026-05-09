import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_transfer_state.dart';
import '../../core/transfer_models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({
    required this.state,
    required this.onChanged,
    super.key,
  });

  final AppTransferState state;
  final void Function(VoidCallback update) onChanged;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  static const _largeFileWarningBytes = 1024 * 1024 * 1024;

  bool _busy = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destination = widget.state.androidExportDestination;
    final canExport = Platform.isAndroid &&
        destination != null &&
        widget.state.selectedFiles.isNotEmpty &&
        !_busy;

    return PageScaffold(
      title: l10n.text('exportWorkflow'),
      subtitle:
          'Select mobile content, categorize it, and export to the GMP_Airdrop folder on USB-C storage.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _pickFiles(TransferCategory.photos),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(l10n.selectPhotos),
                ),
                FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _pickFiles(TransferCategory.videos),
                  icon: const Icon(Icons.video_library_rounded),
                  label: Text(l10n.selectVideos),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _pickFiles(TransferCategory.documents),
                  icon: const Icon(Icons.folder_rounded),
                  label: Text(l10n.selectFiles),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _chooseDestination,
                  icon: const Icon(Icons.usb_rounded),
                  label: Text(l10n.text('chooseDrive')),
                ),
                OutlinedButton.icon(
                  onPressed: canExport ? _startExport : null,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.text('startExport')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        PremiumCompletionBanner(
          visible: !_busy && widget.state.exportProgress >= 1,
          message: _status ?? l10n.text('exportComplete'),
        ),
        MetricGrid(summary: widget.state.selectedSummary),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.usb_rounded, color: GmpColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${l10n.text('destination')}: '
                        '${destination?.label ?? 'Choose USB-C folder'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _busy && widget.state.exportProgress == 0
                    ? const PremiumLoadingBar()
                    : LinearProgressIndicator(
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        value: _busy || widget.state.exportProgress > 0
                            ? widget.state.exportProgress
                            : null,
                      ),
                const SizedBox(height: 8),
                Text(
                  _status ??
                      (widget.state.exportProgress >= 1
                          ? l10n.text('exportComplete')
                          : l10n.text('ready')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FileListCard(
          title: l10n.text('categorization'),
          files: widget.state.selectedFiles,
        ),
      ],
    );
  }

  Future<void> _pickFiles(TransferCategory category) async {
    if (!_ensureAndroid()) return;
    setState(() {
      _busy = true;
      _status = 'Opening Android file picker...';
    });
    await widget.state.pickAndroidExportFiles(category);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = _selectedFilesStatus();
    });
    widget.onChanged(() {});
  }

  Future<void> _chooseDestination() async {
    if (!_ensureAndroid()) return;
    setState(() {
      _busy = true;
      _status = 'Choose USB-C destination folder';
    });
    try {
      await widget.state.chooseAndroidExportDestination();
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = error.message ?? 'USB destination is not writable';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = widget.state.androidExportDestination == null
          ? 'No destination selected'
          : 'Destination ready';
    });
    widget.onChanged(() {});
  }

  Future<void> _startExport() async {
    setState(() {
      _busy = true;
      _status = 'Exporting files to GMP_Airdrop...';
    });
    try {
      await widget.state.exportAndroidFiles(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _status = 'Exporting ${(progress * 100).round()}%');
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = error.message ??
            'Export failed. Please choose the USB folder again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status =
          'Export complete: ${widget.state.selectedFiles.length} files saved to ${widget.state.androidExportDestination?.label ?? 'USB-C drive'}/GMP_Airdrop';
    });
    widget.onChanged(() {});
  }

  bool _ensureAndroid() {
    if (Platform.isAndroid) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Android USB-C export runs on the Android app.'),
      ),
    );
    return false;
  }

  String _selectedFilesStatus() {
    final files = widget.state.selectedFiles;
    if (files.isEmpty) return 'No files selected';
    final largeCount =
        files.where((file) => file.sizeBytes >= _largeFileWarningBytes).length;
    if (largeCount > 0) {
      return '${files.length} files selected. $largeCount very large file(s) may take longer; keep the USB-C drive connected.';
    }
    return '${files.length} files selected';
  }
}
