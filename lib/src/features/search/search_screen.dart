import 'package:flutter/material.dart';

import '../../core/app_transfer_state.dart';
import '../../core/transfer_models.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_cards.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.state, super.key});

  final AppTransferState state;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final files = widget.state.selectedFiles.where(_matches).toList();

    return PageScaffold(
      title: l10n.text('manualSearch'),
      subtitle: 'Find files by name, extension, type, target folder, or date.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: l10n.text('searchHint'),
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (files.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.text('noResults')),
            ),
          )
        else
          FileListCard(title: l10n.search, files: files),
      ],
    );
  }

  bool _matches(TransferFile file) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return file.name.toLowerCase().contains(query) ||
        file.extension.contains(query) ||
        file.targetFolder.toLowerCase().contains(query) ||
        file.modifiedLabel.toLowerCase().contains(query) ||
        file.category.name.toLowerCase().contains(query);
  }
}
