import 'package:flutter/material.dart';

class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key, required this.intent});

  final String intent;

  @override
  Widget build(BuildContext context) {
    final label = intent == 'mp' ? 'Matières premières' : 'Produits finis';
    return Scaffold(
      appBar: AppBar(title: Text('Recherche — $label')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Module recherche en cours d’implémentation (sprint catalogue).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
