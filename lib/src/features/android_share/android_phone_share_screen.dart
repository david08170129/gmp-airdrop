import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/transfer_models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';
import 'android_phone_share_service.dart';

class AndroidPhoneShareScreen extends StatefulWidget {
  const AndroidPhoneShareScreen({super.key});

  @override
  State<AndroidPhoneShareScreen> createState() =>
      _AndroidPhoneShareScreenState();
}

class _AndroidPhoneShareScreenState extends State<AndroidPhoneShareScreen> {
  final _service = AndroidPhoneShareService();
  final _selected = <TransferFile>[];
  final _downloads = <String, AndroidPhoneShareDownload>{};
  StreamSubscription<AndroidPhoneShareDownload>? _subscription;
  AndroidPhoneShareSession? _session;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _subscription = _service.events.listen((event) {
      if (!mounted) return;
      setState(() => _downloads[event.file.id] = event);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_service.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = _session != null;

    return PageScaffold(
      title: l10n.text('sendToPhoneTitle'),
      subtitle: l10n.text('sendToPhoneSubtitle'),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final setup = _ShareSetupCard(
                session: _session,
                busy: _busy,
                status: _status,
                selectedCount: _selected.length,
                sharedFiles: _service.files,
                onPickPhotos: () => _pick(TransferCategory.photos),
                onPickVideos: () => _pick(TransferCategory.videos),
                onPickFiles: () => _pick(TransferCategory.documents),
                onStart: _startShare,
                onStop: _stopShare,
              );
              final activity = _ShareActivityCard(
                files: _service.files,
                downloads: _downloads,
                running: running,
              );
              if (!wide) {
                return Column(
                  children: [
                    setup,
                    const SizedBox(height: 16),
                    activity,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: setup),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: activity),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pick(TransferCategory category) async {
    if (!_ensureAndroid()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _status = l10n.text('openingAndroidFilePicker');
    });
    try {
      final files = await _service.pickFiles(category);
      _selected.addAll(files);
      _status = _selected.isEmpty
          ? l10n.text('noFilesSelected')
          : '${_selected.length} ${l10n.text('filesSelected')}';
    } on PlatformException catch (error) {
      _status = error.message ?? l10n.text('couldNotSelectFiles');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startShare() async {
    if (!_ensureAndroid() || _selected.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _status = l10n.text('preparingLocalShare');
      _downloads.clear();
    });
    try {
      await _service.stop();
      _session = null;
      await _service.prepareFiles(_selected);
      final session = await _service.start();
      _session = session;
      _status =
          '${_service.files.length} ${l10n.text('filesReadyForIphoneDownload')}';
    } on PlatformException catch (error) {
      _status = error.message ?? l10n.text('couldNotPrepareFilesForSharing');
    } catch (error) {
      _status = '${l10n.text('couldNotStartPhoneShare')}: $error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopShare() async {
    final l10n = AppLocalizations.of(context);
    await _service.stop();
    if (!mounted) return;
    setState(() {
      _session = null;
      _status = l10n.text('phoneShareStopped');
    });
  }

  bool _ensureAndroid() {
    if (Platform.isAndroid) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).text('sendToPhoneAndroidOnly'),
        ),
      ),
    );
    return false;
  }
}

class _ShareSetupCard extends StatelessWidget {
  const _ShareSetupCard({
    required this.session,
    required this.busy,
    required this.status,
    required this.selectedCount,
    required this.sharedFiles,
    required this.onPickPhotos,
    required this.onPickVideos,
    required this.onPickFiles,
    required this.onStart,
    required this.onStop,
  });

  final AndroidPhoneShareSession? session;
  final bool busy;
  final String? status;
  final int selectedCount;
  final List<AndroidPhoneShareFile> sharedFiles;
  final VoidCallback onPickPhotos;
  final VoidCallback onPickVideos;
  final VoidCallback onPickFiles;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final running = session != null;
    final l10n = AppLocalizations.of(context);
    return PremiumHoverSurface(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      running ? GmpColors.successSoft : GmpColors.blueSoft,
                  child: Icon(
                    running ? Icons.ios_share_rounded : Icons.qr_code_2_rounded,
                    color: running ? GmpColors.success : GmpColors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    running
                        ? l10n.text('iphoneDownloadPageLive')
                        : l10n.text('androidLocalShare'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (running)
              _DownloadQrCard(session: session!)
            else
              _ShareStartPanel(
                busy: busy,
                selectedCount: selectedCount,
                onPickPhotos: onPickPhotos,
                onPickVideos: onPickVideos,
                onPickFiles: onPickFiles,
              ),
            const SizedBox(height: 18),
            if (status != null)
              Text(status!, style: const TextStyle(color: GmpColors.muted)),
            if (running) ...[
              const SizedBox(height: 12),
              _InfoRow(
                  label: l10n.text('androidIp'), value: session!.ipAddress),
              _InfoRow(label: l10n.text('downloadUrl'), value: session!.url),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: busy || selectedCount == 0 ? null : onStart,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    running
                        ? l10n.text('refreshShare')
                        : l10n.text('startPhoneShare'),
                  ),
                ),
                if (running)
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_rounded),
                    label: Text(l10n.text('stopSharing')),
                  ),
              ],
            ),
            if (sharedFiles.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                '${sharedFiles.length} ${l10n.text('filesOnDownloadPage')}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareStartPanel extends StatelessWidget {
  const _ShareStartPanel({
    required this.busy,
    required this.selectedCount,
    required this.onPickPhotos,
    required this.onPickVideos,
    required this.onPickFiles,
  });

  final bool busy;
  final int selectedCount;
  final VoidCallback onPickPhotos;
  final VoidCallback onPickVideos;
  final VoidCallback onPickFiles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GmpColors.blueSoft.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GmpColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCount == 0
                ? l10n.text('chooseFilesFromAndroid')
                : '$selectedCount ${l10n.text('filesSelected')}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onPickPhotos,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(l10n.text('photos')),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onPickVideos,
                icon: const Icon(Icons.video_library_rounded),
                label: Text(l10n.text('videos')),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onPickFiles,
                icon: const Icon(Icons.folder_rounded),
                label: Text(l10n.text('files')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadQrCard extends StatelessWidget {
  const _DownloadQrCard({required this.session});

  final AndroidPhoneShareSession session;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: GmpColors.line),
          boxShadow: [
            BoxShadow(
              color: GmpColors.blue.withValues(alpha: 0.08),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: QrImageView(
          data: session.url,
          version: QrVersions.auto,
          size: 236,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: GmpColors.text,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: GmpColors.text,
          ),
        ),
      ),
    );
  }
}

class _ShareActivityCard extends StatelessWidget {
  const _ShareActivityCard({
    required this.files,
    required this.downloads,
    required this.running,
  });

  final List<AndroidPhoneShareFile> files;
  final Map<String, AndroidPhoneShareDownload> downloads;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumHoverSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('downloadActivity'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              _EmptyShareState(running: running)
            else
              for (final file in files.take(12)) ...[
                _ShareFileTile(file: file, download: downloads[file.id]),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _ShareFileTile extends StatelessWidget {
  const _ShareFileTile({required this.file, required this.download});

  final AndroidPhoneShareFile file;
  final AndroidPhoneShareDownload? download;

  @override
  Widget build(BuildContext context) {
    final progress = download?.progress ?? 0;
    final complete = download?.complete ?? false;
    final l10n = AppLocalizations.of(context);
    final typeLabel =
        file.typeLabel == 'File' ? l10n.text('files') : file.typeLabel;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(categoryIcon(file.category), color: GmpColors.blue),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${file.sizeLabel} - $typeLabel',
            overflow: TextOverflow.ellipsis,
          ),
          if (download != null) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ],
      ),
      trailing: Icon(
        complete ? Icons.check_circle_rounded : Icons.download_rounded,
        color: complete ? GmpColors.success : GmpColors.muted,
      ),
    );
  }
}

class _EmptyShareState extends StatelessWidget {
  const _EmptyShareState({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: running ? GmpColors.successSoft : GmpColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GmpColors.line),
      ),
      child: Column(
        children: [
          Icon(
            running ? Icons.radar_rounded : Icons.inbox_rounded,
            color: running ? GmpColors.success : GmpColors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            running
                ? l10n.text('waitingForIphoneDownloads')
                : l10n.text('noSharedFilesYet'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text('selectedFilesAppearBeforeQr'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: GmpColors.muted),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: GmpColors.muted)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
