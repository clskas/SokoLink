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
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final roles = user?.roleLabels ?? const <String>[];

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
                  Text(user?.phone ?? user?.email ?? ''),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          user?.isPro == true
                              ? Icons.workspace_premium
                              : Icons.person_outline,
                          size: 18,
                        ),
                        label: Text(user?.isPro == true ? 'Plan Pro' : 'Plan Free'),
                      ),
                      ...roles.map((r) => Chip(label: Text(r))),
                    ],
                  ),
                  if (auth.isOffline)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Mode hors-ligne actif',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (user?.canManageCatalog == true)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mon catalogue'),
              subtitle: Text(
                user!.canSellMp && user.canSellFinished
                    ? 'MP et produits finis'
                    : user.canSellMp
                        ? 'Matières premières uniquement'
                        : 'Produits finis uniquement',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/catalog'),
            ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Documents de l’entreprise'),
            subtitle: const Text('RCCM, NIF, pièce d’identité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _uploadDocument(context, ref),
          ),
          if (user?.isPro != true)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(
                user?.planStatus == 'PENDING'
                    ? 'Demande Pro en cours'
                    : 'Passer au plan Pro',
              ),
              subtitle: const Text('Plus de produits et RFQ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: user?.planStatus == 'PENDING'
                  ? null
                  : () => _requestPro(context, ref),
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Manuel d’utilisation'),
            onTap: () => context.push('/legal/manuel'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Conditions d’utilisation'),
            onTap: () => context.push('/legal/cgu'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Confidentialité'),
            onTap: () => context.push('/legal/confidentialite'),
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
    String selected = 'RCCM';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Ajouter un document'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'RCCM', child: Text('RCCM')),
              DropdownMenuItem(value: 'NIF', child: Text('NIF')),
              DropdownMenuItem(value: 'ID_CARD', child: Text('Pièce d’identité')),
            ],
            onChanged: (v) {
              if (v != null) setLocal(() => selected = v);
            },
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
      ),
    );
    if (confirmed != true) return;

    final picked = await FilePicker.pickFiles(withData: true);
    if (picked == null || picked.files.single.bytes == null) return;

    try {
      final file = picked.files.single;
      await ref.read(dioProvider).post(
            '/me/company/documents',
            data: FormData.fromMap({
              'type': selected,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e))),
        );
      }
    }
  }

  Future<void> _requestPro(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(marketplaceApiProvider).post('/billing/pro-request');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre demande Pro a été envoyée.')),
        );
      }
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e))),
        );
      }
    }
  }
}
