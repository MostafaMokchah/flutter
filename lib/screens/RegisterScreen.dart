import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Inscription réussie!')),
  );
  // wait 2 seconds before navigating
  await Future.delayed(const Duration(seconds: 2));
  context.go('/dashboard');
}
 else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Inscription échouée.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FlutterLogo(size: 80),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Mot de passe trop court';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitRegister,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Créer un compte'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Vous avez déjà un compte ? Connectez-vous'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
