import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

class OtpPhoneScreen extends ConsumerStatefulWidget {
  const OtpPhoneScreen({super.key});

  @override
  ConsumerState<OtpPhoneScreen> createState() => _OtpPhoneScreenState();
}

class _OtpPhoneScreenState extends ConsumerState<OtpPhoneScreen> {
  final _phone = TextEditingController(text: '+243');
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok =
        await ref.read(authControllerProvider.notifier).requestOtp(_phone.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.push('/otp/verify');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/branding/sokolink-icon.png',
                  width: 88,
                  height: 88,
                  errorBuilder: (_, __, ___) => const Icon(Icons.link, size: 72),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SokoLink',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connexion par OTP téléphone.\nEnsuite un code PIN local (sans coût SMS).',
              textAlign: TextAlign.center,
            ),
            if (auth.isOffline)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Mode hors-ligne : utilisez votre PIN si déjà configuré.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 32),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro WhatsApp / mobile',
                hintText: '+2438XXXXXXX',
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Envoi…' : 'Recevoir le code OTP'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/cgu'),
              child: const Text('CGU'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final devCode = ref.read(authControllerProvider).devCode;
    if (devCode != null && devCode.isNotEmpty) {
      _code.text = devCode;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(code: _code.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == 'needs_profile') {
      context.push('/otp/profile');
    } else if (result == 'needs_pin_setup') {
      context.go('/pin/setup');
    } else if (result == 'needs_pin_unlock') {
      context.go('/pin/unlock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Code OTP')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Code envoyé au ${auth.phone ?? ''}'),
          if (auth.devCode != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Mode démo — aucun SMS envoyé',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    auth.devCode!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Code déjà pré-rempli ci-dessous — appuyez sur Valider',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Code à 6 chiffres'),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Vérification…' : 'Valider'),
          ),
        ],
      ),
    );
  }
}

class OtpProfileScreen extends ConsumerStatefulWidget {
  const OtpProfileScreen({super.key});

  @override
  ConsumerState<OtpProfileScreen> createState() => _OtpProfileScreenState();
}

class _OtpProfileScreenState extends ConsumerState<OtpProfileScreen> {
  final _code = TextEditingController();
  final _company = TextEditingController();
  final _name = TextEditingController();
  final _roles = <String>{'PROCESSOR'};
  String? _province;
  List<Map<String, dynamic>> _provinces = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    final devCode = ref.read(authControllerProvider).devCode;
    if (devCode != null && devCode.isNotEmpty) {
      _code.text = devCode;
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final list = await ref.read(marketplaceApiProvider).list('/provinces');
      setState(() {
        _provinces = list;
        _province = list.isNotEmpty
            ? (list.firstWhere(
                  (e) => e['name'] == 'Kinshasa',
                  orElse: () => list.first,
                )['name']
                ?.toString())
            : 'Kinshasa';
      });
    } catch (_) {
      setState(() {
        _provinces = [
          {'name': 'Kinshasa'},
          {'name': 'Haut-Katanga'},
        ];
        _province = 'Kinshasa';
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _company.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_province == null || _roles.isEmpty || _company.text.trim().length < 2) {
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(
          code: _code.text.trim(),
          fullName: _name.text.trim(),
          companyName: _company.text.trim(),
          province: _province,
          roles: _roles.toList(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == 'needs_pin_setup') context.go('/pin/setup');
    if (result == 'needs_pin_unlock') context.go('/pin/unlock');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil entreprise')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Premier accès : renseignez votre entreprise et le même code OTP.',
          ),
          if (auth.devCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Mode démo — code : ${auth.devCode} (déjà pré-rempli)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Code OTP'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Votre nom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _company,
            decoration: const InputDecoration(labelText: 'Raison sociale'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _province,
            items: _provinces
                .map(
                  (p) => DropdownMenuItem(
                    value: p['name']?.toString(),
                    child: Text(p['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _province = v),
            decoration: const InputDecoration(labelText: 'Province'),
          ),
          CheckboxListTile(
            value: _roles.contains('SUPPLIER_MP'),
            onChanged: (v) => setState(() {
              v == true
                  ? _roles.add('SUPPLIER_MP')
                  : _roles.remove('SUPPLIER_MP');
            }),
            title: const Text('Fournisseur MP'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _roles.contains('PROCESSOR'),
            onChanged: (v) => setState(() {
              v == true ? _roles.add('PROCESSOR') : _roles.remove('PROCESSOR');
            }),
            title: const Text('Transformateur'),
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
            child: Text(_loading ? 'Création…' : 'Continuer'),
          ),
        ],
      ),
    );
  }
}

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pin.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes PIN ne correspondent pas')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok =
        await ref.read(authControllerProvider.notifier).setupPin(_pin.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un code PIN')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Ce PIN reste sur cet appareil. Les prochaines connexions n’enverront plus d’OTP.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'PIN (4 à 6 chiffres)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'Confirmer le PIN'),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Enregistrement…' : 'Activer le PIN'),
          ),
        ],
      ),
    );
  }
}

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pin = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .unlockWithPin(_pin.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text(
              'Bonjour${auth.user?.fullName != null ? ', ${auth.user!.fullName}' : ''}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              auth.isOffline
                  ? 'Hors-ligne — déverrouillez avec votre PIN local'
                  : 'Entrez votre code PIN local',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: 'PIN'),
              onSubmitted: (_) => _submit(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? '…' : 'Déverrouiller'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Se déconnecter / nouvel OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
