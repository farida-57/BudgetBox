import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_cubit.dart';
import '../widgets/auth_form_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final message = await context.read<AuthCubit>().register(
          displayName: _displayName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (message != null) {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _displayName,
                  label: 'Nom d\'affichage',
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _email,
                  label: 'Courriel',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Courriel invalide' : null,
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _password,
                  label: 'Mot de passe',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.length < 8)
                      ? '8 caractères minimum'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _confirm,
                  label: 'Confirmer le mot de passe',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => v != _password.text ? 'Les mots de passe diffèrent' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
