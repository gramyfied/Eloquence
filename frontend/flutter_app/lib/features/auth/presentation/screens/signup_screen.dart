import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/auth_provider.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _logger = Logger();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Validation email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email invalide';
    }
    return null;
  }

  // Validation mot de passe
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    return null;
  }

  // Validation confirmation mot de passe
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation requise';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  // Inscription
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      _logger.w('❌ SignUpScreen: Validation du formulaire échouée');
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez accepter les conditions d\'utilisation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    _logger.i('🔄 SignUpScreen: Tentative d\'inscription pour $email');

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signUp(
        email: email,
        password: password,
        displayName: displayName.isNotEmpty ? displayName : null,
      );
      
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        _logger.i('✅ SignUpScreen: Inscription réussie - ${authState.user!.email}');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      _logger.e('❌ SignUpScreen: Erreur d\'inscription - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'inscription: ${e.toString()}'),
            backgroundColor: EloquenceColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.state == AuthState.loading;

    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EloquenceColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                Text(
                  'Créer un compte',
                  style: EloquenceTextStyles.headline1.copyWith(
                    color: EloquenceColors.cyan,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Rejoignez Eloquence dès aujourd\'hui',
                  style: EloquenceTextStyles.bodyLarge.copyWith(
                    color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Champ nom d'affichage
                TextFormField(
                  controller: _displayNameController,
                  textCapitalization: TextCapitalization.words,
                  style: EloquenceTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Nom d\'affichage (optionnel)',
                    labelStyle: EloquenceTextStyles.bodyMedium.copyWith(
                      color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: EloquenceColors.cyan,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.cyan),
                    ),
                    filled: true,
                    fillColor: EloquenceColors.glassBackground,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Champ email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: _validateEmail,
                  style: EloquenceTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: EloquenceTextStyles.bodyMedium.copyWith(
                      color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: EloquenceColors.cyan,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.cyan),
                    ),
                    filled: true,
                    fillColor: EloquenceColors.glassBackground,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: _validatePassword,
                  style: EloquenceTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: EloquenceTextStyles.bodyMedium.copyWith(
                      color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: EloquenceColors.cyan,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.cyan),
                    ),
                    filled: true,
                    fillColor: EloquenceColors.glassBackground,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Champ confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  validator: _validateConfirmPassword,
                  style: EloquenceTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    labelStyle: EloquenceTextStyles.bodyMedium.copyWith(
                      color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: EloquenceColors.cyan,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: EloquenceColors.cyan),
                    ),
                    filled: true,
                    fillColor: EloquenceColors.glassBackground,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Accepter les conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: EloquenceColors.cyan,
                    ),
                    const Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                        style: EloquenceTextStyles.caption,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bouton inscription
                ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EloquenceColors.cyan,
                    foregroundColor: EloquenceColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(EloquenceColors.navy),
                          ),
                        )
                      : Text(
                          'S\'inscrire',
                          style: EloquenceTextStyles.buttonLarge.copyWith(
                            color: EloquenceColors.navy,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Lien connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ? ',
                      style: EloquenceTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Se connecter',
                        style: EloquenceTextStyles.bodyMedium.copyWith(
                          color: EloquenceColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}