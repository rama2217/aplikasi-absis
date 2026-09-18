import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

/// Halaman pembuka aplikasi. Menampilkan logo AbSis dengan fade-in halus
/// di atas background biru solid, lalu setelah beberapa detik otomatis
/// pindah ke MainNavigation (kalau sesi login masih aktif) atau ke
/// LoginScreen (kalau belum login).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const bgColor = Colors.white;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    // Total waktu splash tampil di layar sebelum pindah halaman.
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final nextScreen = hasSession ? const MainNavigation() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 160,
              height: 160,
            ),
          ),
        ),
      ),
    );
  }
}