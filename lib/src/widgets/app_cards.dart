import 'package:flutter/material.dart';

import '../core/file_count_summary.dart';
import '../core/transfer_models.dart';
import '../l10n/app_localizations.dart';
import '../theme/gmp_colors.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 28,
        compact ? 20 : 26,
        compact ? 18 : 28,
        42,
      ),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: GmpColors.text,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      fontSize: compact ? 34 : null,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: GmpColors.muted,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({required this.summary, super.key});

  final FileCountSummary summary;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = screenWidth < 480
        ? (screenWidth - 56).clamp(150, 280).toDouble()
        : 160.0;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        MetricTile(
            label: l10n.text('photos'),
            value: summary.photos,
            width: tileWidth),
        MetricTile(
            label: l10n.text('videos'),
            value: summary.videos,
            width: tileWidth),
        MetricTile(
          label: l10n.text('documents'),
          value: summary.documents,
          width: tileWidth,
        ),
        MetricTile(
            label: l10n.text('code'), value: summary.code, width: tileWidth),
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.width = 160,
    super.key,
  });

  final String label;
  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 104,
      child: PremiumHoverSurface(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: GmpColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(label, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class FileListCard extends StatelessWidget {
  const FileListCard({
    required this.title,
    required this.files,
    super.key,
  });

  final String title;
  final List<TransferFile> files;

  @override
  Widget build(BuildContext context) {
    return PremiumHoverSurface(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: GmpColors.blueSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GmpColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.inbox_rounded, color: GmpColors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No files selected yet',
                        style: TextStyle(
                          color: GmpColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final file in files)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(categoryIcon(file.category), color: GmpColors.blue),
                  title: Text(file.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${file.sizeLabel} - ${file.targetFolder}'),
                  trailing: Text(file.modifiedLabel),
                ),
          ],
        ),
      ),
    );
  }
}

class PremiumCompletionBanner extends StatelessWidget {
  const PremiumCompletionBanner({
    required this.visible,
    required this.message,
    super.key,
  });

  final bool visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: visible
          ? Container(
              key: const ValueKey('completion'),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GmpColors.successSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: GmpColors.success.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: GmpColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: GmpColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class PremiumLoadingBar extends StatefulWidget {
  const PremiumLoadingBar({super.key});

  @override
  State<PremiumLoadingBar> createState() => _PremiumLoadingBarState();
}

class _PremiumLoadingBarState extends State<PremiumLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return LinearProgressIndicator(
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
          value: 0.18 + (_controller.value * 0.52),
        );
      },
    );
  }
}

class PremiumHoverSurface extends StatefulWidget {
  const PremiumHoverSurface({required this.child, super.key});

  final Widget child;

  @override
  State<PremiumHoverSurface> createState() => _PremiumHoverSurfaceState();
}

class _PremiumHoverSurfaceState extends State<PremiumHoverSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: dark ? GmpColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? GmpColors.blue.withValues(alpha: 0.18)
                  : (dark ? GmpColors.darkLine : GmpColors.line)
                      .withValues(alpha: 0.7),
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: GmpColors.blue.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

IconData categoryIcon(TransferCategory category) {
  return switch (category) {
    TransferCategory.photos => Icons.image_rounded,
    TransferCategory.videos => Icons.movie_rounded,
    TransferCategory.documents => Icons.description_rounded,
    TransferCategory.code => Icons.code_rounded,
    TransferCategory.others => Icons.insert_drive_file_rounded,
  };
}
