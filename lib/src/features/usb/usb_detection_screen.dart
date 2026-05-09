import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_transfer_state.dart';
import '../../core/gmp_folder_structure.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class UsbDetectionScreen extends StatefulWidget {
  const UsbDetectionScreen({
    required this.state,
    required this.onChanged,
    required this.onContinueExport,
    required this.onContinueImport,
    super.key,
  });

  final AppTransferState state;
  final void Function(VoidCallback update) onChanged;
  final VoidCallback onContinueExport;
  final VoidCallback onContinueImport;

  @override
  State<UsbDetectionScreen> createState() => _UsbDetectionScreenState();
}

class _UsbDetectionScreenState extends State<UsbDetectionScreen> {
  bool _busy = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drive = widget.state.detectedDrive;
    final ready = drive?.hasGmpFolder ?? false;

    return PageScaffold(
      title: l10n.text('usbDetection'),
      subtitle:
          'Detect removable USB-C storage and verify the GMP_Airdrop folder before transfer.',
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: ready ? GmpColors.successSoft : GmpColors.blueSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          ready ? Icons.usb_rounded : Icons.usb_off_rounded,
                          color: ready ? GmpColors.success : GmpColors.blue,
                          size: 26,
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
                                  : l10n.text('deviceConnection'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _status ??
                                  (drive == null
                                      ? l10n.text('waiting')
                                      : '${drive.label} - ${l10n.text('readyForTransfer')}'),
                              style: TextStyle(
                                color: _status == null
                                    ? GmpColors.muted
                                    : ready
                                        ? GmpColors.success
                                        : GmpColors.text,
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
                        onPressed: _busy ? null : _scanUsb,
                        icon: const Icon(Icons.radar_rounded),
                        label: Text(l10n.text('scanUsb')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _createStructure,
                        icon: const Icon(Icons.create_new_folder_rounded),
                        label: Text(l10n.text('createStructure')),
                      ),
                      OutlinedButton.icon(
                        onPressed: ready ? widget.onContinueExport : null,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(l10n.export),
                      ),
                      OutlinedButton.icon(
                        onPressed: ready ? widget.onContinueImport : null,
                        icon: const Icon(Icons.download_rounded),
                        label: Text(l10n.import),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.folderPlan, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final folder in GmpFolderStructure.all)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_rounded, color: GmpColors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(folder)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanUsb() async {
    if (Platform.isAndroid) {
      setState(() {
        _busy = true;
        _status = 'Select the USB root folder in Android storage picker';
      });
      try {
        await widget.state.chooseAndroidExportDestination();
      } on PlatformException catch (error) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = error.message ?? 'Unable to access selected USB folder';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = widget.state.androidExportDestination == null
            ? 'No USB folder selected'
            : 'USB tree selected. Create GMP_Airdrop structure next.';
      });
      widget.onChanged(() {});
      return;
    }

    widget.onChanged(widget.state.scanDrive);
  }

  Future<void> _createStructure() async {
    if (!Platform.isAndroid) {
      widget.onChanged(widget.state.createFolderStructure);
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Creating GMP_Airdrop on selected USB root...';
    });
    try {
      final folders = await widget.state.createAndroidFolderStructure();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = folders.isEmpty
            ? 'No USB root selected'
            : 'Verified ${folders.length} GMP_Airdrop folders on USB';
      });
      widget.onChanged(() {});
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = error.message ?? 'Unable to create GMP_Airdrop on USB';
      });
    }
  }
}
