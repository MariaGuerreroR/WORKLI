import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_registering) {
        await AuthService.instance.register(_name.text.trim(), _email.text.trim(), _password.text);
      } else {
        await AuthService.instance.login(_email.text.trim(), _password.text);
      }
      widget.onAuthenticated();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.loginWithGoogle();
      widget.onAuthenticated();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spaceXl),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.science, size: 54, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(_registering ? 'Crear cuenta' : 'Bienvenido a Workly', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 28),
                if (_registering) TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo'), validator: (v) => v == null || v.trim().isEmpty ? 'Escribe tu nombre' : null),
                if (_registering) const SizedBox(height: 14),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Escribe un email válido' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña'), validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 22),
                ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Procesando...' : (_registering ? 'Registrarme' : 'Iniciar sesión'))),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: _loading ? null : _google, icon: const Icon(Icons.login), label: const Text('Continuar con Google')),
                TextButton(onPressed: _loading ? null : () => setState(() { _registering = !_registering; _error = null; }), child: Text(_registering ? 'Ya tengo una cuenta' : 'Crear una cuenta')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}