import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale?> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.settings,
      subtitle: 'Configure language, platform behavior, storage rules, and privacy defaults.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onLocaleChanged(null),
                      icon: const Icon(Icons.language_rounded),
                      label: Text(l10n.systemLanguage),
                    ),
                    OutlinedButton(
                      onPressed: () => onLocaleChanged(const Locale('en')),
                      child: Text(l10n.english),
                    ),
                    OutlinedButton(
                      onPressed: () => onLocaleChanged(const Locale('zh')),
                      child: Text(l10n.chinese),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SettingsGroup(
          title: l10n.text('platforms'),
          children: const [
            _SettingsRow(
              icon: Icons.phone_iphone_rounded,
              title: 'iOS / Android',
              subtitle: 'Use the system file picker and USB-C storage destination.',
            ),
            _SettingsRow(
              icon: Icons.desktop_windows_rounded,
              title: 'Windows desktop',
              subtitle: 'Detect removable drives and import GMP_Airdrop folders.',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsGroup(
          title: l10n.text('storage'),
          children: const [
            _SettingsRow(
              icon: Icons.folder_copy_rounded,
              title: 'Automatic folder creation',
              subtitle: 'Always organize files under GMP_Airdrop by type.',
            ),
            _SettingsRow(
              icon: Icons.history_rounded,
              title: 'Local import history',
              subtitle: 'Keep transfer records on this device only.',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsGroup(
          title: l10n.text('privacy'),
          children: [
            _SettingsRow(
              icon: Icons.lock_rounded,
              title: l10n.text('offlineOnly'),
              subtitle: 'No cloud sync or AI features are enabled in v0.1.',
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: GmpColors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
