import 'package:flutter/material.dart';

import '../../core/app_transfer_state.dart';
import '../../core/transfer_models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/gmp_colors.dart';
import '../../widgets/app_cards.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.state, super.key});

  final AppTransferState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.history,
      subtitle: 'Review export and import sessions with counts and destinations.',
      children: [
        if (state.history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.text('emptyHistory')),
            ),
          )
        else
          for (final item in state.history) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: GmpColors.blueSoft,
                  child: Icon(_historyIcon(item.direction), color: GmpColors.blue),
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${item.dateLabel}\n${item.summary.total} files • ${item.destination}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  IconData _historyIcon(TransferDirection direction) {
    return switch (direction) {
      TransferDirection.exportToUsb => Icons.upload_file_rounded,
      TransferDirection.importToPc => Icons.download_rounded,
      TransferDirection.wirelessReceive => Icons.qr_code_2_rounded,
    };
  }
}
