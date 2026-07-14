import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();

  List<String> _provinces = [];
  String? _province;
  final Set<String> _roles = {'PROCESSOR'};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/provinces');
      final list = (res.data as List)
          .map((e) => (e as Map)['name'] as String)
          .toList();
      setState(() {
        _provinces = list;
        _province = list.contains('Kinshasa')
            ? 'Kinshasa'
            : (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {
      setState(() {
        _provinces = ['Kinshasa', 'Haut-Katanga', 'Nord-Kivu'];
        _province = 'Kinshasa';
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _company.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _province == null ||
        _roles.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(authControllerProvider.notifier).register({
      'email': _email.text.trim(),
      'password': _password.text,
      'fullName': _fullName.text.trim(),
      'companyName': _company.text.trim(),
      'province': _province,
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'phone': _phone.text.trim(),
      'whatsapp': _phone.text.trim(),
      'roles': _roles.toList(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email invalide',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe (8+)'),
              validator: (v) =>
                  v != null && v.length >= 8 ? null : 'Minimum 8 caractères',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              decoration: const InputDecoration(labelText: 'Raison sociale'),
              validator: (v) =>
                  v != null && v.trim().length >= 2 ? null : 'Obligatoire',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _province,
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _province = v),
              decoration: const InputDecoration(labelText: 'Province'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville (optionnel)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone / WhatsApp',
              ),
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : 'Obligatoire',
            ),
            const SizedBox(height: 16),
            Text(
              'Rôles de votre entreprise',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            CheckboxListTile(
              value: _roles.contains('SUPPLIER_MP'),
              onChanged: (v) => setState(() {
                v == true
                    ? _roles.add('SUPPLIER_MP')
                    : _roles.remove('SUPPLIER_MP');
              }),
              title: const Text('Fournisseur de matières premières'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _roles.contains('PROCESSOR'),
              onChanged: (v) => setState(() {
                v == true
                    ? _roles.add('PROCESSOR')
                    : _roles.remove('PROCESSOR');
              }),
              title: const Text('Transformateur / fabricant'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _roles.contains('BUYER'),
              onChanged: (v) => setState(() {
                v == true ? _roles.add('BUYER') : _roles.remove('BUYER');
              }),
              title: const Text('Acheteur B2B'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (auth.error != null)
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Création…' : 'Créer mon compte'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/cgu'),
              child: const Text('En créant un compte, j’accepte les CGU'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/manuel'),
              child: const Text('Lire le manuel d’utilisation'),
            ),
          ],
        ),
      ),
    );
  }
}
