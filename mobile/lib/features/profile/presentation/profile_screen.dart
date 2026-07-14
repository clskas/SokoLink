import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.companyName ?? 'Mon entreprise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Mon catalogue'),
            subtitle: const Text('Gérer mes produits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/catalog'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Documents de l’entreprise'),
            subtitle: const Text('Attestation, RCCM, certificats'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _uploadDocument(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Passer au plan Pro'),
            subtitle: const Text('Demander l’accès aux fonctions avancées'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _requestPro(context, ref),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    final type = TextEditingController(text: 'rccm');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un document'),
        content: TextField(
          controller: type,
          decoration: const InputDecoration(
            labelText: 'Type de document',
            hintText: 'Ex. RCCM, attestation, certificat',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Choisir un fichier'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      type.dispose();
      return;
    }
    final picked = await FilePicker.pickFiles(withData: true);
    if (picked == null || picked.files.single.bytes == null) {
      type.dispose();
      return;
    }
    try {
      final file = picked.files.single;
      await ref
          .read(dioProvider)
          .post(
            '/me/company/documents',
            data: FormData.fromMap({
              'type': type.text.trim(),
              'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
            }),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document envoyé pour vérification.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      type.dispose();
    }
  }

  Future<void> _requestPro(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(marketplaceApiProvider).post('/billing/pro-request');
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre demande Pro a été envoyée.')),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }
}
