import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Design tokens — disamakan dengan palet Login/Beranda/History/Leave/Leaderboard
  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;
  static const dangerColor = Color(0xFFE4483A);

  final _authService = AuthService();
  final _client = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  String? _className;
  String? _homeroomTeacherName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _authService.getStudentProfile();
    String? className;
    String? homeroomTeacherName;

    if (data?['class_id'] != null) {
      final classData = await _client
          .from('classes')
          .select('name, homeroom_teacher_id')
          .eq('id', data!['class_id'])
          .maybeSingle();
      className = classData?['name'];

      if (classData?['homeroom_teacher_id'] != null) {
        final teacherData = await _client
            .from('users')
            .select('name')
            .eq('id', classData!['homeroom_teacher_id'])
            .maybeSingle();
        homeroomTeacherName = teacherData?['name'];
      }
    }

    setState(() {
      _profile = data;
      _className = className;
      _homeroomTeacherName = homeroomTeacherName;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await NotificationService.instance.cancelAll();
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan AppLanguage supaya layar ini otomatis rebuild saat
    // toggle bahasa ditekan.
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final fullName = _profile?['full_name'] ?? '-';
    final nisn = _profile?['nisn'] ?? '-';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopBar(),
            _buildHeroAndInfo(fullName, nisn),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAccountCard(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 32),
          const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                },
                icon: const Icon(Icons.notifications_none, color: textDark),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: dangerColor, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAndInfo(String fullName, String nisn) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 56),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, Color(0xFF2A4BC0)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  backgroundImage:
                      _profile?['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
                  child: _profile?['avatar_url'] == null
                      ? Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 32, color: primaryColor, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 3),
              Text(
                _className != null ? '$_className  •  NISN: $nisn' : 'NISN: $nisn',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildInfoCard(nisn),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String nisn) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Strings.t('section_personal_data'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          initialAddress: _profile?['address'],
                          initialPhoneNumber: _profile?['phone_number'],
                          initialAvatarUrl: _profile?['avatar_url'],
                        ),
                      ),
                    );
                    if (updated == true) {
                      setState(() => _isLoading = true);
                      _loadProfile();
                    }
                  },
                  child: const Icon(Icons.edit_outlined, size: 16, color: textGray),
                ),
              ],
            ),
          ),
          _infoRow(Icons.person_outline, Strings.t('homeroom_teacher'), _homeroomTeacherName ?? '-'),
          _infoRow(Icons.email_outlined, Strings.t('email'), '$nisn@absis.internal'),
          _infoRow(Icons.phone_outlined, Strings.t('phone'), _profile?['phone_number'] ?? '-'),
          _infoRow(Icons.location_on_outlined, Strings.t('address'), _profile?['address'] ?? '-', isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F1F5))),
      ),
      child: Row(
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
                Text(value, style: const TextStyle(fontSize: 13.5, color: textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.lock_reset_outlined,
            label: Strings.t('change_password'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          _languageRow(),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          _actionRow(
            icon: Icons.help_outline,
            label: Strings.t('help'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          _actionRow(
            icon: Icons.info_outline,
            label: Strings.t('about_app'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          _actionRow(
            icon: Icons.logout,
            label: Strings.t('logout'),
            color: dangerColor,
            onTap: _handleLogout,
            showChevron: false,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color color = textDark,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color == textDark ? textGray : color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
            if (showChevron) const Icon(Icons.chevron_right, size: 18, color: textGray),
          ],
        ),
      ),
    );
  }

  Widget _languageRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.language, size: 19, color: textGray),
          const SizedBox(width: 12),
          Expanded(child: Text(Strings.t('language'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark))),
          Text(
            AppLanguage.instance.isEnglish ? Strings.t('language_english') : Strings.t('language_indonesian'),
            style: const TextStyle(color: textGray, fontSize: 12.5),
          ),
          Switch(
            value: AppLanguage.instance.isEnglish,
            activeColor: primaryColor,
            onChanged: (_) => AppLanguage.instance.toggle(),
          ),
        ],
      ),
    );
  }
}