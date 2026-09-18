import 'package:flutter/material.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(Strings.t('help_faq_section').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  _faqCard(),
                  const SizedBox(height: 24),
                  Text(Strings.t('help_contact_section').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  _contactCard(),
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
              Strings.t('help_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _faqCard() {
    final faqs = [
      (Strings.t('faq_qr_question'), Strings.t('faq_qr_answer')),
      (Strings.t('faq_password_question'), Strings.t('faq_password_answer')),
      (Strings.t('faq_alpa_question'), Strings.t('faq_alpa_answer')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          for (var i = 0; i < faqs.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF0F1F5)),
            _faqTile(faqs[i].$1, faqs[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(question,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textDark)),
        iconColor: primaryColor,
        collapsedIconColor: textGray,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer, style: const TextStyle(fontSize: 13, color: textGray, height: 1.4)),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.t('help_contact_notice'),
            style: const TextStyle(fontSize: 13, color: textGray, height: 1.4),
          ),
          const SizedBox(height: 16),
          _contactRow(Icons.phone_outlined, Strings.t('help_contact_admin_label'), '(TODO: nomor WA/telepon admin)'),
          const SizedBox(height: 12),
          _contactRow(Icons.email_outlined, Strings.t('help_contact_email_label'), '(TODO: email tata usaha sekolah)'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: textGray, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
