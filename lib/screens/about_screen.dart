import 'package:flutter/material.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;

  // TODO: samakan dengan versi asli di pubspec.yaml, dan update setiap rilis.
  static const _appVersion = '1.0.0';

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
              child: ListView(
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
                    child: Text('${Strings.t('about_version')} $_appVersion',
                        style: const TextStyle(fontSize: 12, color: textGray)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Strings.t('about_description_title').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                        const SizedBox(height: 8),
                        Text(Strings.t('about_description_body'),
                            style: const TextStyle(fontSize: 13, color: textDark, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Strings.t('about_developer_title').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                        const SizedBox(height: 8),
                        Text(Strings.t('about_developer_body'),
                            style: const TextStyle(fontSize: 13, color: textDark, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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