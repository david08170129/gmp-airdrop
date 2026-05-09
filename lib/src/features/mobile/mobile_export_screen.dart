import 'package:flutter/material.dart';

import '../../core/gmp_folder_structure.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import 'mobile_export_service.dart';

class MobileExportScreen extends StatefulWidget {
  const MobileExportScreen({super.key});

  @override
  State<MobileExportScreen> createState() => _MobileExportScreenState();
}

class _MobileExportScreenState extends State<MobileExportScreen> {
  final _service = MobileExportService();
  int _selectedCount = 0;
  String _destination = 'No USB-C drive selected';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'GMP Airdrop Mobile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: GmpColors.text,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tagline,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionCard(
              icon: Icons.photo_library_rounded,
              label: l10n.selectPhotos,
              onTap: () => _pick(MediaKind.photos),
            ),
            _ActionCard(
              icon: Icons.video_library_rounded,
              label: l10n.selectVideos,
              onTap: () => _pick(MediaKind.videos),
            ),
            _ActionCard(
              icon: Icons.folder_rounded,
              label: l10n.selectFiles,
              onTap: () => _pick(MediaKind.files),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectedItems,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('$_selectedCount files selected'),
                const SizedBox(height: 20),
                Text(
                  l10n.usbDestination,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_destination),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _destination = 'USB-C Drive/GMP_Airdrop';
                  }),
                  icon: const Icon(Icons.usb_rounded),
                  label: Text(l10n.chooseDrive),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _selectedCount == 0 ? null : _export,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.exportToUsb),
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
                  l10n.folderPlan,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...GmpFolderStructure.all.map(
                  (folder) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(folder),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(MediaKind kind) async {
    final count = await _service.pickFiles(kind);
    setState(() => _selectedCount += count);
  }

  Future<void> _export() async {
    await _service.exportToUsb();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export task prepared for USB-C drive')),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: GmpColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
