import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/app_shell.dart';
import 'src/features/ios_companion/ios_companion_shell.dart';
import 'src/l10n/app_localizations.dart';
import 'src/theme/gmp_theme.dart';

void main() {
  runApp(const GmpAirdropApp());
}

class GmpAirdropApp extends StatefulWidget {
  const GmpAirdropApp({super.key});

  @override
  State<GmpAirdropApp> createState() => _GmpAirdropAppState();
}

class _GmpAirdropAppState extends State<GmpAirdropApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMP Transfer',
      debugShowCheckedModeBanner: false,
      theme: GmpTheme.light(),
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Platform.isIOS
          ? const IosCompanionShell()
          : AppShell(onLocaleChanged: _setLocale),
    );
  }
}
