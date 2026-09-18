import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'login_screen.dart';
import 'scan_qr_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _attendanceService = AttendanceService();

  static const primaryColor = Color(0xFF3B5FE0);
  static const primaryDark = Color(0xFF14213D);
  static const textDark = Color(0xFF1B2033);
  static const successColor = Color(0xFF1FA35A);
  static const warningColor = Color(0xFFD99A1A);
  static const dangerColor = Color(0xFFE4483A);
  static const bgColor = Color(0xFFF4F5F9);

  // Kutipan harian statis — rotasi otomatis berdasarkan hari (menggantikan Jadwal Pelajaran)
  static const List<String> _dailyQuotes = [
    'Kedisiplinan hari ini adalah kunci kesuksesan esok hari.',
    'Kehadiranmu adalah langkah pertama menuju prestasi.',
    'Konsistensi kecil yang dilakukan setiap hari akan membentuk hasil besar.',
    'Jangan biarkan alasan mengalahkan komitmenmu untuk hadir.',
    'Setiap menit yang tepat waktu adalah investasi masa depanmu.',
    'Disiplin adalah jembatan antara tujuan dan pencapaian.',
    'Rajin hadir hari ini, sukses menanti di masa depan.',
    'Waktu yang hilang tidak akan pernah kembali — hargai setiap kesempatan belajar.',
  ];

  bool _isLoading = true;
  Map<String, dynamic>? _studentProfile;
  Map<String, dynamic>? _todaySession;
  Map<String, dynamic>? _todayAttendance;
  Map<String, int> _monthlyRecap = {
    'sakit': 0,
    'izin': 0,
    'hadir': 0,
    'telat': 0,
    'alpa': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getStudentProfile();
      if (profile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final classId = profile['class_id'] as int?;
      Map<String, dynamic>? session;
      Map<String, dynamic>? attendance;

      if (classId != null) {
        session = await _attendanceService.getTodaySession(classId);
        if (session != null) {
          attendance = await _attendanceService.getAttendanceForSession(
            profile['id'],
            session['id'],
          );
        }
      }

      final recap = await _attendanceService.getMonthlyRecap(profile['id']);

      setState(() {
        _studentProfile = profile;
        _todaySession = session;
        _todayAttendance = attendance;
        _monthlyRecap = {..._monthlyRecap, ...recap};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return Strings.t('greeting_morning');
    if (hour < 15) return Strings.t('greeting_afternoon');
    if (hour < 18) return Strings.t('greeting_evening');
    return Strings.t('greeting_night');
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _todaysQuote() {
    final dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    return _dailyQuotes[dayOfYear % _dailyQuotes.length];
  }

  @override
  Widget build(BuildContext context) {
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

    final fullName =
        _studentProfile?['full_name'] ?? Strings.t('default_student');
    // TODO: sesuaikan key ini dengan nama kolom asli di tabel students/classes
    // students.class_id -> classes.name (bukan kolom langsung di students).
    // Butuh auth_service.dart meng-query dengan join, misal:
    // .select('*, classes(name, major)') lalu diakses lewat profile['classes']['name']
    final classData = _studentProfile?['classes'] as Map<String, dynamic>?;
    final className = classData?['name'] ?? '-';
    final nisn = _studentProfile?['nisn'] ?? '-';
    final status = _todayAttendance?['status']; // 'hadir' / 'telat' / null

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildTopBar(),
              _buildHeroAndSummary(fullName, className, nisn, status),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildScanCard(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuoteCard(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      // Tinggi header DIKUNCI di sini — berapa pun besar logo di dalamnya
      // (diatur lewat height di Image.asset di bawah), tinggi kotak putih
      // header ini TIDAK akan ikut berubah. Sebelumnya height header cuma
      // mengikuti ukuran logo (lewat padding vertical), makanya waktu logo
      // diperbesar, seluruh header ikut melar ke bawah.
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo AbSis — sama seperti yang dipakai di halaman Login,
          // menggantikan teks "AbSis" biar konsisten di seluruh app.
          // fit: BoxFit.contain memastikan logo diskalakan proporsional
          // pas ke tinggi yang ditentukan, tidak gepeng/kepotong.
          //
          // Kalau logo masih kelihatan kecil dibanding ruang yang ada,
          // naikkan angka height di bawah (misal ke 48 atau 52) — asal
          // tidak melebihi ~56 (tinggi header 64 dikurangi sedikit ruang
          // napas atas-bawah), header tetap tidak akan ikut membesar.
          Image.asset(
            'assets/images/LogoAbsis2.png',
            height: 70,
            fit: BoxFit.contain,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none, color: primaryDark),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: dangerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAndSummary(
    String fullName,
    String className,
    String nisn,
    String? status,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.school, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$className  •  NISN: $nisn',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildRingkasanCard(status),
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasanCard(String? status) {
    final bulanIni = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    final hadir = _monthlyRecap['hadir'] ?? 0;
    final telat = _monthlyRecap['telat'] ?? 0;
    final alpa = _monthlyRecap['alpa'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.t('attendance_summary_title'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${Strings.t('this_month_label')} ($bulanIni)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statChip(
                  successColor,
                  hadir,
                  _titleCase(Strings.t('status_present')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statChip(
                  warningColor,
                  telat,
                  _titleCase(Strings.t('status_late')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statChip(
                  dangerColor,
                  alpa,
                  _titleCase(Strings.t('status_alpa')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(Color color, int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanQrScreen()),
        );
        if (result == true) _loadData(); // refresh status kehadiran
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, Color(0xFF2A4BC0)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              Strings.t('scan_attendance_button'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Strings.t('record_attendance_today'),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: primaryColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.t('quote_of_the_day'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _todaysQuote(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}