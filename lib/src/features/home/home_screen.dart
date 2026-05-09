import 'package:flutter/material.dart';

import '../../core/app_transfer_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.state,
    required this.onNavigate,
    super.key,
  });

  final AppTransferState state;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drive = state.detectedDrive;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8FBFF),
                  Color(0xFFF3F7FF),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: GmpColors.line.withValues(alpha: 0.64)),
              boxShadow: [
                BoxShadow(
                  color: GmpColors.blue.withValues(alpha: 0.05),
                  blurRadius: 44,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  final copy = _HeroCopy(l10n: l10n, onNavigate: onNavigate);
                  final panel = _TransferPanel(state: state, l10n: l10n);

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy,
                        const SizedBox(height: 24),
                        panel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: copy),
                      const SizedBox(width: 32),
                      Expanded(flex: 4, child: panel),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SoftStat(
                label: l10n.text('readyStatus'),
                value: l10n.text('offlineOnly'),
                icon: Icons.lock_rounded,
              ),
              _SoftStat(
                label: l10n.text('selectedFiles'),
                value: '${state.selectedFiles.length}',
                icon: Icons.folder_copy_rounded,
              ),
              _SoftStat(
                label: l10n.text('detectedDrive'),
                value: drive?.label ?? l10n.text('waiting'),
                icon: Icons.usb_rounded,
              ),
              _SoftStat(
                label: l10n.text('lastTransfer'),
                value: state.history.isEmpty
                    ? l10n.text('waiting')
                    : state.history.first.dateLabel,
                icon: Icons.history_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: _RecentSummary(state: state, l10n: l10n),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.l10n, required this.onNavigate});

  final AppLocalizations l10n;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: GmpColors.blueSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.tagline,
            style: const TextStyle(
              color: GmpColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.text('homeTitle'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: GmpColors.text,
                fontWeight: FontWeight.w800,
                height: 1.04,
              ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.text('homeSubtitle'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: GmpColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => onNavigate(4),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(l10n.exportToUsb),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onNavigate(2),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: Text(l10n.text('wirelessReceive')),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onNavigate(3),
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(l10n.text('sendToPhone')),
            ),
            OutlinedButton.icon(
              onPressed: () => onNavigate(1),
              icon: const Icon(Icons.usb_rounded),
              label: Text(l10n.text('scanUsb')),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransferPanel extends StatelessWidget {
  const _TransferPanel({required this.state, required this.l10n});

  final AppTransferState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final progress = state.exportProgress > 0 ? state.exportProgress : 0.62;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF1F6FF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: GmpColors.blue.withValues(alpha: 0.07),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PulseDot(active: state.detectedDrive != null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.detectedDrive == null
                              ? l10n.text('deviceConnection')
                              : l10n.text('usbDriveConnected'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.detectedDrive?.label ?? 'Samsung 256GB',
                          style: const TextStyle(color: GmpColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                l10n.text('phoneUsbPc'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              const _FlowVisual(),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                value: progress,
              ),
              const SizedBox(height: 18),
              _PanelRow(
                  label: 'Photos', value: '${state.selectedSummary.photos}'),
              _PanelRow(
                  label: 'Videos', value: '${state.selectedSummary.videos}'),
              _PanelRow(
                  label: 'Documents',
                  value: '${state.selectedSummary.documents}'),
              _PanelRow(label: 'Status', value: l10n.text('readyForTransfer')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.active});

  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
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
        final scale = 1 + (_controller.value * 0.28);
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: GmpColors.successSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Transform.scale(
              scale: widget.active ? scale : 1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: widget.active ? GmpColors.success : GmpColors.blue,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowVisual extends StatelessWidget {
  const _FlowVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _FlowNode(icon: Icons.phone_iphone_rounded, label: 'Phone'),
        _FlowArrow(),
        _FlowNode(icon: Icons.usb_rounded, label: 'USB-C'),
        _FlowArrow(),
        _FlowNode(icon: Icons.desktop_windows_rounded, label: 'PC'),
      ],
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: GmpColors.blue),
          const SizedBox(height: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Icon(Icons.arrow_forward_rounded, color: GmpColors.muted),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SoftStat extends StatelessWidget {
  const _SoftStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 92,
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
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GmpColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _RecentSummary extends StatelessWidget {
  const _RecentSummary({required this.state, required this.l10n});

  final AppTransferState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final summary = state.selectedSummary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: GmpColors.blue.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('recentTransferSummary'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            _SummaryLine(
              label: l10n.text('photosTransferred'),
              value: summary.photos,
            ),
            _SummaryLine(
              label: l10n.text('videosTransferred'),
              value: summary.videos,
            ),
            _SummaryLine(
              label: l10n.text('documentsTransferred'),
              value: summary.documents,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
