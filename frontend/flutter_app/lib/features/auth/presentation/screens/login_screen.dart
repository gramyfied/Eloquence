import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logger = Logger();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isDeveloperMode = false;

  @override
  void initState() {
    super.initState();
    _logger.i('🔐 LoginScreen: Initialisation de l\'écran de connexion');
    
    // Mode développeur - credentials préremplis
    _emailController.text = 'dev@eloquence.fr';
    _passwordController.text = 'DevPassword123!';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  // Connexion développeur (bypass)
  Future<void> _developerLogin() async {
    _logger.w('🚧 MODE DÉVELOPPEUR: Connexion directe sans authentification');
    
    // Simuler un utilisateur développeur
    final devUser = AppUser(
      id: 'dev-user-123',
      email: 'dev@eloquence.fr',
      displayName: 'Développeur Eloquence',
      avatarUrl: null,
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
      isEmailConfirmed: true,
    );

    // Bypass direct du state d'authentification
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.setDeveloperUser(devUser);
    
    _logger.i('✅ MODE DÉVELOPPEUR: Utilisateur connecté - ${devUser.displayName}');
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // Connexion normale via Supabase
  Future<void> _normalLogin() async {
    if (!_formKey.currentState!.validate()) {
      _logger.w('❌ LoginScreen: Validation du formulaire échouée');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    _logger.i('🔄 LoginScreen: Tentative de connexion pour $email');

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signIn(email: email, password: password);
      
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        _logger.i('✅ LoginScreen: Connexion réussie - ${authState.user!.email}');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      _logger.e('❌ LoginScreen: Erreur de connexion - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo et titre
                const Icon(
                  Icons.psychology,
                  size: 80,
                  color: EloquenceColors.cyan,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Eloquence',
                  style: EloquenceTextStyles.headline1.copyWith(
                    color: EloquenceColors.cyan,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous à votre compte',
                  style: EloquenceTextStyles.bodyLarge.copyWith(
                    color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),

                // Mode développeur toggle
                Card(
                  color: _isDeveloperMode ? ConfidenceBoostColors.warningOrange.withAlpha((255 * 0.1).round()) : EloquenceColors.glassBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          color: _isDeveloperMode ? ConfidenceBoostColors.warningOrange : EloquenceColors.white.withAlpha((255 * 0.7).round()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mode Développeur',
                            style: EloquenceTextStyles.bodyMedium.copyWith(
                              color: _isDeveloperMode ? ConfidenceBoostColors.warningOrange : EloquenceColors.white.withAlpha((255 * 0.7).round()),
                            ),
                          ),
                        ),
                        Switch(
                          value: _isDeveloperMode,
                          onChanged: (value) {
                            setState(() {
                              _isDeveloperMode = value;
                            });
                            _logger.i('🚧 Mode développeur: ${value ? "ACTIVÉ" : "DÉSACTIVÉ"}');
                          },
                          activeColor: ConfidenceBoostColors.warningOrange,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
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
                
                // Se souvenir de moi
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: EloquenceColors.cyan,
                    ),
                    const Text(
                      'Se souvenir de moi',
                      style: EloquenceTextStyles.bodyMedium,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Boutons de connexion
                if (_isDeveloperMode) ...[
                  // Bouton développeur
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _developerLogin,
                    icon: const Icon(Icons.build),
                    label: const Text('Connexion Développeur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConfidenceBoostColors.warningOrange,
                      foregroundColor: EloquenceColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Bouton connexion normale
                ElevatedButton(
                  onPressed: isLoading ? null : _normalLogin,
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
                          'Se connecter',
                          style: EloquenceTextStyles.buttonLarge.copyWith(
                            color: EloquenceColors.navy,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Mot de passe oublié
                TextButton(
                  onPressed: () {
                    _logger.i('🔄 Navigation vers mot de passe oublié');
                    // TODO: Implémenter écran mot de passe oublié
                  },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: EloquenceTextStyles.bodyMedium.copyWith(
                      color: EloquenceColors.cyan,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Lien inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ? ',
                      style: EloquenceTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        _logger.i('🔄 Navigation vers inscription');
                        Navigator.of(context).pushNamed('/signup');
                      },
                      child: Text(
                        'S\'inscrire',
                        style: EloquenceTextStyles.bodyMedium.copyWith(
                          color: EloquenceColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Debug info en mode développeur
                if (_isDeveloperMode) ...[
                  const SizedBox(height: 32),
                  Card(
                    color: ConfidenceBoostColors.warningOrange.withAlpha((255 * 0.1).round()),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚧 DEBUG INFO',
                            style: EloquenceTextStyles.bodyMedium.copyWith(
                              color: ConfidenceBoostColors.warningOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'État auth: ${authState.state}',
                            style: EloquenceTextStyles.caption,
                          ),
                          Text(
                            'Email: ${_emailController.text}',
                            style: EloquenceTextStyles.caption,
                          ),
                          Text(
                            'Loading: $isLoading',
                            style: EloquenceTextStyles.caption,
                          ),
                          if (authState.user != null)
                            Text(
                              'Utilisateur: ${authState.user!.displayName}',
                              style: EloquenceTextStyles.caption,
                            ),
                          if (authState.error != null)
                            Text(
                              'Erreur: ${authState.error}',
                              style: EloquenceTextStyles.caption.copyWith(
                                color: EloquenceColors.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}