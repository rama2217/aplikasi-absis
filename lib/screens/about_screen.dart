import 'package:flutter/material.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import '../services/settings_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;

  // Dipakai kalau `about_version` di settings kosong / fetch gagal.
  static const _fallbackVersion = '1.0.0';

  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await SettingsService.fetchMobileSettings();
    if (!mounted) return;
    setState(() => _settings = data);
  }

  String get _version =>
      _settings[SettingsService.keyAboutVersion] ?? _fallbackVersion;

  // Isi dari settings kalau ada, kalau tidak pakai teks bawaan di Strings.
  String get _description =>
      _settings[SettingsService.keyAboutDescription] ??
      Strings.t('about_description_body');

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
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSettings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(Strings.t('about_tagline'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, color: textGray)),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text('${Strings.t('about_version')} $_version',
                          style: const TextStyle(fontSize: 12, color: textGray)),
                    ),
                    const SizedBox(height: 24),
                    _infoCard(
                      title: Strings.t('about_description_title'),
                      body: _description,
                    ),
                    const SizedBox(height: 16),
                    _infoCard(
                      title: Strings.t('about_developer_title'),
                      body: Strings.t('about_developer_body'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13, color: textDark, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: textDark),
          ),
          Expanded(
            child: Text(
              Strings.t('about_app_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}