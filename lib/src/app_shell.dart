import 'package:flutter/material.dart';

import 'core/app_transfer_state.dart';
import 'features/android_share/android_phone_share_screen.dart';
import 'features/export/export_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/import/import_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/usb/usb_detection_screen.dart';
import 'features/wireless/wireless_receive_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/gmp_colors.dart';
import 'widgets/gmp_logo.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _transferState = AppTransferState();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _transferState.loadAndroidExportHistory();
    await _transferState.loadWindowsImportHistory();
    await _transferState.loadWirelessReceiveHistory();
    if (mounted) setState(() {});
  }

  void _goTo(int index) {
    setState(() => _index = index);
  }

  void _refresh(VoidCallback update) {
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compactHeader = MediaQuery.sizeOf(context).width < 720;
    final destinations = [
      _Destination(Icons.home_rounded, l10n.home),
      _Destination(Icons.usb_rounded, l10n.usb),
      _Destination(Icons.qr_code_2_rounded, l10n.text('wirelessReceive')),
      _Destination(Icons.phone_iphone_rounded, l10n.text('sendToPhone')),
      _Destination(Icons.upload_file_rounded, l10n.export),
      _Destination(Icons.download_rounded, l10n.import),
      _Destination(Icons.history_rounded, l10n.history),
      _Destination(Icons.search_rounded, l10n.search),
      _Destination(Icons.settings_rounded, l10n.settings),
    ];
    final pages = [
      HomeScreen(state: _transferState, onNavigate: _goTo),
      UsbDetectionScreen(
        state: _transferState,
        onChanged: _refresh,
        onContinueExport: () => _goTo(4),
        onContinueImport: () => _goTo(5),
      ),
      WirelessReceiveScreen(state: _transferState, onChanged: _refresh),
      const AndroidPhoneShareScreen(),
      ExportScreen(state: _transferState, onChanged: _refresh),
      ImportScreen(state: _transferState, onChanged: _refresh),
      HistoryScreen(state: _transferState),
      SearchScreen(state: _transferState),
      SettingsScreen(onLocaleChanged: widget.onLocaleChanged),
    ];

    return Scaffold(
      backgroundColor: GmpColors.background,
      appBar: AppBar(
        titleSpacing: compactHeader ? 12 : 22,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GmpLogo(height: compactHeader ? 48 : 62),
            if (!compactHeader) ...[
              const SizedBox(width: 20),
              Container(width: 1, height: 34, color: GmpColors.line),
              const SizedBox(width: 18),
              Text(
                'Offline transfer platform',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GmpColors.text,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
        actions: compactHeader
            ? [
                IconButton(
                  onPressed: () => _goTo(8),
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: l10n.settings,
                ),
                const SizedBox(width: 8),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => _goTo(8),
                        child: const Text('English'),
                      ),
                      IconButton(
                        onPressed: () => _goTo(8),
                        icon: const Icon(Icons.settings_rounded),
                        tooltip: l10n.settings,
                      ),
                    ],
                  ),
                ),
              ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                _PremiumSidebar(
                  destinations: destinations,
                  selectedIndex: _index,
                  expanded: constraints.maxWidth >= 1180,
                  onSelected: _goTo,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: pages[_index],
                    ),
                  ),
                ),
              ],
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: pages[_index],
            ),
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _index,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                ),
            ],
            onDestinationSelected: _goTo,
          );
        },
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _PremiumSidebar extends StatelessWidget {
  const _PremiumSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 214 : 86,
      margin: const EdgeInsets.fromLTRB(14, 16, 10, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GmpColors.line.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            for (var index = 0; index < destinations.length; index++) ...[
              _SidebarItem(
                destination: destinations[index],
                selected: selectedIndex == index,
                expanded: expanded,
                onTap: () => onSelected(index),
              ),
              if (index == 5) const _SidebarDivider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 13 : 0,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? GmpColors.blueSoft
                  : _hovered
                      ? const Color(0xFFF7FAFF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: widget.expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.destination.icon,
                  size: 21,
                  color: active ? GmpColors.blue : GmpColors.muted,
                ),
                if (widget.expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.destination.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? GmpColors.text : GmpColors.muted,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: GmpColors.line.withValues(alpha: 0.68),
    );
  }
}
