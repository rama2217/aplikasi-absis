import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'home_screen.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _nisnController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const primaryColor = Color(0xFF3B5FE0);
  static const primaryDark = Color(0xFF14213D);
  static const accentGreen = Color(0xFF3DDC97);
  static const dangerColor = Color(0xFFE5484D);
  static const bgColor = Color(0xFFFFFFFF);
  static const fieldLabelColor = Color(0xFF1B2033);

  @override
  void dispose() {
    _nisnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final nisn = _nisnController.text.trim();
    final password = _passwordController.text;

    if (nisn.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = Strings.t('login_id_password_required'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.loginWithNisn(nisn, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } on AuthException catch (_) {
      setState(() => _errorMessage = Strings.t('login_invalid_credentials'));
    } catch (e) {
      setState(() => _errorMessage = Strings.t('generic_error_retry'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/LogoAbsis2.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  Strings.t('login_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2033),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Strings.t('login_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 32),

                // ID Siswa field
                Text(
                  Strings.t('student_id_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fieldLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nisnController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: Strings.t('student_id_hint'),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                Text(
                  Strings.t('password_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fieldLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: Strings.t('password_hint'),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: dangerColor, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 12),

                // Lupa kata sandi
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implementasi reset password
                    },
                    child: Text(
                      Strings.t('forgot_password'),
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Masuk
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          Strings.t('login_button'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    Strings.t('login_footer'),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}