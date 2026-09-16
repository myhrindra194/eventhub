import 'package:eventhub/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Affiché à la place de l'application lorsqu'une dépendance de démarrage —
/// Firebase — n'a pas pu être initialisée. Garde l'échec visible et
/// actionnable, au lieu de laisser un écran vide sans explication.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_off, size: 72),
                const SizedBox(height: 24),
                Text(
                  'Connexion à Firebase impossible',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vérifiez que lib/firebase_options.dart correspond au projet '
                  '(flutterfire configure) puis relancez l’application.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SelectableText(
                  '$error',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
