import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_transfer_state.dart';
import '../../core/transfer_models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    required this.state,
    required this.onChanged,
    super.key,
  });

  final AppTransferState state;
  final void Function(VoidCallback update) onChanged;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Timer? _scanTimer;
  bool _scanning = false;
  bool _importing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    unawaited(widget.state.loadWindowsImportHistory());
    _scanDrive();
    _scanTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!_importing) _scanDrive(silent: true);
      },
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drive = widget.state.detectedDrive;
    final ready = widget.state.windowsImportScan != null;
    final summary = widget.state.importSummary;
    final progress = widget.state.importProgress;

    return PageScaffold(
      title: l10n.text('importWorkflow'),
      subtitle:
          'Import organized files from GMP_Airdrop on USB storage into Windows folders.',
      children: [
        PremiumHoverSurface(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color:
                            ready ? GmpColors.successSoft : GmpColors.blueSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        ready ? Icons.check_circle_rounded : Icons.usb_rounded,
                        color: ready ? GmpColors.success : GmpColors.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ready
                                ? l10n.text('usbDriveConnected')
                                : l10n.text('noDrive'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              _driveSubtitle(drive, ready, summary.total),
                              key: ValueKey(
                                '${drive?.path}-${summary.total}-$_status',
                              ),
                              style: const TextStyle(color: GmpColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _scanning || _importing ? null : _scanDrive,
                      icon: _scanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.radar_rounded),
                      label: Text(l10n.text('scanUsb')),
                    ),
                    FilledButton.icon(
                      onPressed: ready && !_importing && summary.total > 0
                          ? _importFiles
                          : null,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n.importFiles),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _importing && progress == 0
                    ? const PremiumLoadingBar()
                    : LinearProgressIndicator(
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        value: _importing || progress > 0 ? progress : null,
                      ),
                const SizedBox(height: 9),
                Text(
                  _status ??
                      (ready
                          ? l10n.text('readyForTransfer')
                          : l10n.text('waiting')),
                  style: const TextStyle(color: GmpColors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        PremiumCompletionBanner(
          visible: !_importing && progress >= 1,
          message: _status ?? l10n.text('importComplete'),
        ),
        MetricGrid(summary: summary),
        const SizedBox(height: 18),
        if (ready)
          FileListCard(
            title: '${l10n.fileCounts} (${widget.state.importFiles.length})',
            files: widget.state.importFiles.take(10).toList(),
          ),
      ],
    );
  }

  String _driveSubtitle(UsbDrive? drive, bool ready, int total) {
    if (_status != null && !ready) return _status!;
    if (drive == null) return 'Waiting for a USB drive with GMP_Airdrop';
    final space = drive.freeLabel.isEmpty ? '' : ' - ${drive.freeLabel} free';
    return '${drive.label}$space - $total files found';
  }

  Future<void> _scanDrive({bool silent = false}) async {
    if (_scanning || _importing) return;
    setState(() {
      _scanning = true;
      if (!silent) _status = 'Scanning Windows USB drives...';
    });

    await widget.state.scanWindowsImport();
    if (!mounted) return;

    setState(() {
      _scanning = false;
      _status = widget.state.windowsImportScan == null
          ? 'No GMP_Airdrop folder found on connected drives'
          : null;
    });
    widget.onChanged(() {});
  }

  Future<void> _importFiles() async {
    setState(() {
      _importing = true;
      _status = 'Importing files to Windows folders...';
    });

    await widget.state.importWindowsFiles(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _status = 'Importing ${(progress * 100).round()}%';
        });
      },
    );
    if (!mounted) return;

    setState(() {
      _importing = false;
      _status =
          'Import complete: ${widget.state.importSummary.total} files saved into Pictures, Videos, and Documents GMP_Airdrop folders';
    });
    widget.onChanged(() {});
  }
}
