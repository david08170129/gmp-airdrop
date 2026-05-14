import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_transfer_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';
import 'wireless_receive_service.dart';

class WirelessReceiveScreen extends StatefulWidget {
  const WirelessReceiveScreen({
    required this.state,
    required this.onChanged,
    super.key,
  });

  final AppTransferState state;
  final void Function(VoidCallback update) onChanged;

  @override
  State<WirelessReceiveScreen> createState() => _WirelessReceiveScreenState();
}

class _WirelessReceiveScreenState extends State<WirelessReceiveScreen> {
  static const _dropChannel = MethodChannel('gmp_airdrop/windows_drop');

  bool _starting = false;
  bool _dragging = false;
  bool _dropBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _dropChannel.setMethodCallHandler(_handleWindowsDropCall);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _dropChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = widget.state.wirelessSession;
    final running = session != null;
    final activeFiles = widget.state.wirelessReceivedFiles
        .where((file) => !file.complete)
        .toList();

    return Stack(
      children: [
        PageScaffold(
          title: l10n.text('wirelessReceive'),
          subtitle: Platform.isAndroid
              ? 'Scan the QR code with iPhone Safari to upload directly to this Android device over the same local Wi-Fi network.'
              : 'Scan the QR code with iPhone Safari or Android Chrome to upload directly to this Windows PC over the same local Wi-Fi network.',
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: activeFiles.isEmpty
                  ? const SizedBox.shrink()
                  : _FloatingProgressStrip(files: activeFiles),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  final setup = _ReceiveSetupCard(
                    session: session,
                    starting: _starting,
                    error: _error,
                    onStart: _start,
                    onStop: _stop,
                  );
                  final history = _ReceiveHistoryCard(
                    files: widget.state.wirelessReceivedFiles,
                    running: running,
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        setup,
                        const SizedBox(height: 16),
                        history,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: setup),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: history),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (Platform.isWindows)
                    _DropHintTile(active: _dragging, busy: _dropBusy),
                  _PathTile(
                    icon: Icons.image_rounded,
                    label: 'Photos',
                    path: Platform.isAndroid
                        ? 'App storage/GMP_Airdrop/Wireless/Photos'
                        : r'Pictures\GMP_Airdrop\Wireless\Photos',
                  ),
                  _PathTile(
                    icon: Icons.movie_rounded,
                    label: 'Videos',
                    path: Platform.isAndroid
                        ? 'App storage/GMP_Airdrop/Wireless/Videos'
                        : r'Videos\GMP_Airdrop\Wireless\Videos',
                  ),
                  _PathTile(
                    icon: Icons.description_rounded,
                    label: 'Documents',
                    path: Platform.isAndroid
                        ? 'App storage/GMP_Airdrop/Wireless/Documents'
                        : r'Documents\GMP_Airdrop\Wireless\Documents',
                  ),
                  _StatusTile(running: running),
                ],
              ),
            ),
          ],
        ),
        IgnorePointer(
          ignoring: !_dragging,
          child: AnimatedOpacity(
            opacity: _dragging ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: const _DropOverlay(),
          ),
        ),
      ],
    );
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.state.startWirelessReceive(
        onItem: (_) {
          if (!mounted) return;
          widget.onChanged(() {});
        },
      );
    } catch (error) {
      _error = 'Could not start wireless receive: $error';
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    await widget.state.stopWirelessReceive();
    if (!mounted) return;
    setState(() {});
  }

  Future<dynamic> _handleWindowsDropCall(MethodCall call) async {
    if (call.method != 'filesDropped') return null;
    final paths = (call.arguments as List?)?.whereType<String>().toList() ?? [];
    await _handleDroppedPaths(paths);
    return null;
  }

  Future<void> _handleDroppedPaths(List<String> paths) async {
    final files =
        paths.map(File.new).where((file) => file.path.isNotEmpty).toList();
    if (files.isEmpty) {
      setState(() => _dragging = false);
      return;
    }

    setState(() {
      _dragging = false;
      _dropBusy = true;
      _error = null;
    });
    try {
      if (widget.state.wirelessSession == null) {
        await widget.state.startWirelessReceive(
          onItem: (_) {
            if (!mounted) return;
            widget.onChanged(() {});
          },
        );
      }
      await widget.state.receiveWirelessLocalFiles(files);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer complete: ${files.length} files received',
            ),
          ),
        );
      }
    } catch (error) {
      _error = 'Could not save dropped files: $error';
    } finally {
      if (mounted) setState(() => _dropBusy = false);
    }
  }
}

class _ReceiveSetupCard extends StatelessWidget {
  const _ReceiveSetupCard({
    required this.session,
    required this.starting,
    required this.error,
    required this.onStart,
    required this.onStop,
  });

  final WirelessReceiveSession? session;
  final bool starting;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final running = session != null;
    return PremiumHoverSurface(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LiveActivityIcon(active: running || starting),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      running
                          ? 'Wireless receive is live'
                          : 'Start local receive server',
                      key: ValueKey(running),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                if (running) const _LivePill(),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: running
                  ? _QrCard(session: session!)
                  : _StartReceivePanel(
                      starting: starting,
                      error: error,
                      onStart: onStart,
                    ),
            ),
            if (running) ...[
              const SizedBox(height: 18),
              _InfoRow(
                label: Platform.isAndroid ? 'Android IP' : 'PC IP address',
                value: session!.ipAddress,
              ),
              _InfoRow(label: 'Receive URL', value: session!.url),
              _InfoRow(
                label: 'Available',
                value: _formatBytes(session!.availableBytes),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text('Stop receiving'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 0) return 'Unknown';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final decimals = unitIndex == 0 || size >= 10 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
}

class _StartReceivePanel extends StatelessWidget {
  const _StartReceivePanel({
    required this.starting,
    required this.error,
    required this.onStart,
  });

  final bool starting;
  final String? error;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('start-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            color: GmpColors.blueSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GmpColors.line.withValues(alpha: 0.8)),
          ),
          child: starting ? const _QrSkeleton() : const _QuietEmptyState(),
        ),
        const SizedBox(height: 16),
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: starting ? null : onStart,
          icon: starting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(starting ? 'Starting...' : 'Start wireless receive'),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.session});

  final WirelessReceiveSession session;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('qr-card'),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF7FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: GmpColors.line.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: GmpColors.blue.withValues(alpha: 0.08),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: GmpColors.line),
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
        ),
      ),
    );
  }
}

class _QuietEmptyState extends StatelessWidget {
  const _QuietEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.qr_code_2_rounded,
        size: 78,
        color: GmpColors.blue,
      ),
    );
  }
}

class _QrSkeleton extends StatefulWidget {
  const _QrSkeleton();

  @override
  State<_QrSkeleton> createState() => _QrSkeletonState();
}

class _QrSkeletonState extends State<_QrSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(
          Colors.white,
          GmpColors.blueSoft,
          _controller.value,
        )!;
        return Center(
          child: Container(
            width: 134,
            height: 134,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}

class _LiveActivityIcon extends StatefulWidget {
  const _LiveActivityIcon({required this.active});

  final bool active;

  @override
  State<_LiveActivityIcon> createState() => _LiveActivityIconState();
}

class _LiveActivityIconState extends State<_LiveActivityIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = widget.active ? 1 + (_controller.value * 0.09) : 1.0;
        return Transform.scale(
          scale: pulse,
          child: CircleAvatar(
            radius: 22,
            backgroundColor:
                widget.active ? GmpColors.successSoft : GmpColors.blueSoft,
            child: Icon(
              widget.active
                  ? Icons.wifi_tethering_rounded
                  : Icons.qr_code_2_rounded,
              color: widget.active ? GmpColors.success : GmpColors.blue,
            ),
          ),
        );
      },
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GmpColors.successSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Live',
        style: TextStyle(
          color: GmpColors.success,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReceiveHistoryCard extends StatelessWidget {
  const _ReceiveHistoryCard({required this.files, required this.running});

  final List<WirelessReceiveItem> files;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return PremiumHoverSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receive progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              _ReceiveEmptyState(running: running)
            else
              _AnimatedReceiveList(files: files.take(12).toList()),
          ],
        ),
      ),
    );
  }
}

class _AnimatedReceiveList extends StatelessWidget {
  const _AnimatedReceiveList({required this.files});

  final List<WirelessReceiveItem> files;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < files.length; index++) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: 1),
            duration: Duration(milliseconds: 220 + (index * 24).clamp(0, 120)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: child,
                ),
              );
            },
            child: _ReceiveFileTile(file: files[index]),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _ReceiveFileTile extends StatelessWidget {
  const _ReceiveFileTile({required this.file});

  final WirelessReceiveItem file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(categoryIcon(file.category), color: GmpColors.blue),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: file.progress.clamp(0, 1),
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 4),
          Text(
            file.complete
                ? '${_formatBytes(file.sizeBytes)} saved'
                : '${(file.progress * 100).toStringAsFixed(0)}% receiving',
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Icon(
          file.complete
              ? Icons.check_circle_rounded
              : Icons.downloading_rounded,
          key: ValueKey(file.complete),
          color: file.complete ? GmpColors.success : GmpColors.blue,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = unitIndex == 0 || size >= 10 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}

class _ReceiveEmptyState extends StatelessWidget {
  const _ReceiveEmptyState({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: running ? GmpColors.successSoft : GmpColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GmpColors.line.withValues(alpha: 0.75)),
      ),
      child: Column(
        children: [
          Icon(
            running ? Icons.radar_rounded : Icons.inbox_rounded,
            color: running ? GmpColors.success : GmpColors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            running ? 'Waiting for the next upload' : 'No uploads yet',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            running
                ? 'Live activity will appear here as files arrive.'
                : 'Start receiving to show wireless transfer activity.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: GmpColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FloatingProgressStrip extends StatelessWidget {
  const _FloatingProgressStrip({required this.files});

  final List<WirelessReceiveItem> files;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final file in files.take(3))
            SizedBox(
              width: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: GmpColors.blue.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: GmpColors.blue.withValues(alpha: 0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.downloading_rounded,
                          color: GmpColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: file.progress.clamp(0, 1),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.78),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: GmpColors.blue.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: GmpColors.blue.withValues(alpha: 0.12),
                blurRadius: 38,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_download_rounded,
                  size: 42, color: GmpColors.blue),
              SizedBox(height: 12),
              Text(
                'Release to save',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              SizedBox(height: 6),
              Text(
                'Files will land in the same wireless folders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GmpColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropHintTile extends StatelessWidget {
  const _DropHintTile({required this.active, required this.busy});

  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 108,
      child: PremiumHoverSurface(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? GmpColors.blueSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(
                busy ? Icons.downloading_rounded : Icons.file_download_rounded,
                color: active ? GmpColors.blue : GmpColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      busy ? 'Receiving files...' : 'Ready to receive files',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active ? 'Release anywhere' : 'Windows local drop ready',
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: GmpColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _PathTile extends StatelessWidget {
  const _PathTile({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 108,
      child: PremiumHoverSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: GmpColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: GmpColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 108,
      child: PremiumHoverSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                running ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: running ? GmpColors.success : GmpColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Network mode',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      running
                          ? 'Local receive server active'
                          : 'Server stopped',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GmpColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
