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
                        label: Text(
                          user?.isPro == true
                              ? (user?.planRenewsAt != null
                                  ? 'Pro · exp. ${_formatDate(user!.planRenewsAt!)}'
                                  : 'Plan Pro')
                              : 'Plan Free',
                        ),
                      ),
                      if (user?.isVerified == true)
                        const Chip(
                          avatar: Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.green,
                          ),
                          label: Text('Vérifié'),
                        ),
                      Chip(
                        avatar: const Icon(Icons.link, size: 18),
                        label: Text('${user?.leadCredits ?? 0} crédits'),
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
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Modifier l’entreprise'),
            subtitle: const Text('Nom, province, description, contacts'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editCompany(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Rôles de l’entreprise'),
            subtitle: Text(
              roles.isEmpty ? 'Aucun rôle défini' : roles.join(' · '),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editRoles(context, ref, user?.companyRoles ?? const []),
          ),
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
            leading: const Icon(Icons.folder_shared_outlined),
            title: const Text('Documents de l’entreprise'),
            subtitle: const Text('RCCM, NIF, pièce d’identité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _manageDocuments(context, ref),
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
          if (user?.isVerified != true)
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Obtenir le badge Vérifié'),
              subtitle: const Text('Renforcez la confiance des acheteurs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _requestPlan(
                context,
                ref,
                'VERIFY_YEAR',
                'Demande de badge Vérifié envoyée. En attente de validation du paiement.',
              ),
            ),
          ListTile(
            leading: const Icon(Icons.link_outlined),
            title: const Text('Crédits de mise en relation'),
            subtitle: Text(
              '${user?.leadCredits ?? 0} crédit(s) — répondez à plus de RFQ',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _requestPlan(
              context,
              ref,
              'LEAD_PACK',
              'Demande de pack de crédits envoyée. En attente de validation du paiement.',
            ),
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

  Future<void> _editCompany(BuildContext context, WidgetRef ref) async {
    final api = ref.read(marketplaceApiProvider);
    Map<String, dynamic> company;
    try {
      company = await api.get('/me/company');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
      return;
    }
    List<Map<String, dynamic>> provinces = [];
    try {
      provinces = await api.list('/provinces');
    } catch (_) {}

    final name = TextEditingController(text: company['name']?.toString() ?? '');
    final description = TextEditingController(
      text: company['description']?.toString() ?? '',
    );
    final city = TextEditingController(text: company['city']?.toString() ?? '');
    final phone = TextEditingController(
      text: company['phone']?.toString() ?? '',
    );
    final whatsapp = TextEditingController(
      text: company['whatsapp']?.toString() ?? '',
    );
    String? province = company['province']?.toString();

    if (!context.mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setLocal) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Modifier l’entreprise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              if (provinces.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: provinces.any((p) => p['name'] == province)
                      ? province
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Province'),
                  items: provinces
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['name']?.toString(),
                          child: Text(p['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => province = v),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: whatsapp,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Enregistrer'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      try {
        await api.patch('/me/company', {
          'name': name.text.trim(),
          if (province != null) 'province': province,
          'city': city.text.trim(),
          'phone': phone.text.trim(),
          'whatsapp': whatsapp.text.trim(),
          'description': description.text.trim(),
        });
        await ref.read(authControllerProvider.notifier).refreshUser();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entreprise mise à jour.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
        }
      }
    }
    name.dispose();
    description.dispose();
    city.dispose();
    phone.dispose();
    whatsapp.dispose();
  }

  Future<void> _manageDocuments(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _DocumentsSheet(ref: ref),
    );
  }

  Future<void> _editRoles(
    BuildContext context,
    WidgetRef ref,
    List<String> current,
  ) async {
    final selected = current.toSet();
    const labels = {
      'SUPPLIER_MP': 'Fournisseur MP',
      'PROCESSOR': 'Transformateur',
      'BUYER': 'Acheteur B2B',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Rôles de l’entreprise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: labels.entries
                .map(
                  (e) => CheckboxListTile(
                    value: selected.contains(e.key),
                    title: Text(e.value),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setLocal(() {
                      v == true ? selected.add(e.key) : selected.remove(e.key);
                    }),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(marketplaceApiProvider)
          .patch('/me/company', {'roles': selected.toList()});
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôles mis à jour.')),
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

  Future<void> _requestPlan(
    BuildContext context,
    WidgetRef ref,
    String planCode,
    String successMessage,
  ) async {
    try {
      await ref
          .read(marketplaceApiProvider)
          .post('/billing/payments', {'planCode': planCode});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
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

String _formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String _docTypeLabel(String? type) {
  switch (type) {
    case 'RCCM':
      return 'RCCM';
    case 'NIF':
      return 'NIF';
    case 'ID_CARD':
      return 'Pièce d’identité';
    default:
      return type ?? 'Document';
  }
}

({String label, Color color}) _docStatus(String? status) {
  switch (status) {
    case 'ACCEPTED':
      return (label: 'Validé', color: Colors.green);
    case 'REJECTED':
      return (label: 'Rejeté', color: Colors.red);
    default:
      return (label: 'En vérification', color: Colors.orange);
  }
}

class _DocumentsSheet extends ConsumerStatefulWidget {
  const _DocumentsSheet({required this.ref});
  final WidgetRef ref;
  @override
  ConsumerState<_DocumentsSheet> createState() => _DocumentsSheetState();
}

class _DocumentsSheetState extends ConsumerState<_DocumentsSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final company = await ref.read(marketplaceApiProvider).get('/me/company');
    final docs = company['documents'];
    return docs is List
        ? docs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
  }

  Future<void> _add() async {
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
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ref
          .read(marketplaceApiProvider)
          .delete('/me/company/documents/$id');
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, s) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Documents de l’entreprise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (s.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if ((s.data ?? []).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucun document. Ajoutez vos pièces officielles.'),
              )
            else
              ...(s.data ?? []).map((d) {
                final st = _docStatus(d['status']?.toString());
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_docTypeLabel(d['type']?.toString())),
                  subtitle: Text(
                    st.label,
                    style: TextStyle(color: st.color),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(d['id']?.toString() ?? ''),
                  ),
                );
              }),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Ajouter un document'),
            ),
          ],
        );
      },
    ),
  );
}
