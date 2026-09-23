import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'notification_screen.dart';

/// ============================================================
/// AbSis - Halaman Leaderboard
/// Berbasis POIN akumulasi dari rentang jam scan (v_leaderboard),
/// dengan tie-break fastest_scan_time. Filter Kelas/Jurusan/Sekolah
/// dipertahankan sesuai keputusan final — HANYA visual (card
/// identitas, podium, list) yang direstyle mengikuti referensi.
///
/// Sumber data: view `v_leaderboard` di Supabase, kolom:
///   student_id, full_name, class_id, class_name, major,
///   total_points, fastest_scan_time
/// ============================================================

class LeaderboardStreakScreen extends StatefulWidget {
  const LeaderboardStreakScreen({super.key});

  @override
  State<LeaderboardStreakScreen> createState() => _LeaderboardStreakScreenState();
}

class _StudentPoints {
  final String studentId;
  final String fullName;
  final String? className;
  final String? major;
  final String? avatarUrl;
  final int totalPoints;
  final String? fastestScanTime;

  _StudentPoints({
    required this.studentId,
    required this.fullName,
    required this.className,
    required this.major,
    required this.avatarUrl,
    required this.totalPoints,
    required this.fastestScanTime,
  });

  factory _StudentPoints.fromMap(Map<String, dynamic> map) {
    return _StudentPoints(
      studentId: map['student_id'],
      fullName: map['full_name'] ?? '-',
      className: map['class_name'],
      major: map['major'],
      avatarUrl: map['avatar_url'],
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      fastestScanTime: map['fastest_scan_time'],
    );
  }
}

/// Mode filter leaderboard: per kelas, per jurusan, per angkatan, atau seluruh sekolah
enum _LeaderboardScope { kelas, jurusan, angkatan, sekolah }

class _LeaderboardStreakScreenState extends State<LeaderboardStreakScreen> {
  // Design tokens — disamakan dengan palet Login/Beranda/History/Leave
  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;
  static const dangerColor = Color(0xFFE4483A);
  static const gold = Color(0xFFE0A020);
  static const silver = Color(0xFF9AA1AE);
  static const bronze = Color(0xFFCD7F32);
  static const pointsAccent = Color(0xFFD99A1A);

  final _client = Supabase.instance.client;
  final _authService = AuthService();

  bool _isLoading = true;
  List<_StudentPoints> _leaderboard = [];
  String? _currentStudentId;
  String? _myClassId;
  String? _myMajor;
  Map<String, dynamic>? _myProfile; // untuk avatar_url & nisn di card identitas
  _LeaderboardScope _scope = _LeaderboardScope.kelas;

  // Opsi dropdown untuk tiap tab (diambil dari tabel classes, sekali di awal)
  List<Map<String, dynamic>> _classOptions = [];
  List<String> _majorOptions = [];
  static const List<String> _gradeOptions = ['X', 'XI', 'XII'];

  // Pilihan spesifik user di tiap tab -- null berarti belum dipilih manual,
  // jadi fallback ke kelas/jurusan/angkatan siswa sendiri.
  String? _selectedClassId;
  String? _selectedMajor;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadFilterOptions();
    await _loadLeaderboard();
  }

  /// Ambil daftar kelas & jurusan sekali di awal, untuk isi dropdown filter.
  /// Angkatan (grade) pakai daftar tetap X/XI/XII, tidak perlu query.
  Future<void> _loadFilterOptions() async {
    try {
      final rows = await _client.from('classes').select('id, name, major, grade').order('name');
      final classes = List<Map<String, dynamic>>.from(rows);

      final majors = classes
          .map((c) => c['major'] as String?)
          .where((m) => m != null && m.isNotEmpty)
          .map((m) => m!)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _classOptions = classes;
        _majorOptions = majors;
      });
    } catch (e) {
      // Kalau gagal, dropdown Kelas/Jurusan tetap kosong -- leaderboard
      // masih bisa dipakai lewat fallback kelas/jurusan sendiri.
    }
  }

  /// Cari grade (X/XI/XII) dari class_id, berdasarkan _classOptions yang
  /// sudah dimuat lewat _loadFilterOptions().
  String? _gradeOfClass(String? classId) {
    if (classId == null) return null;
    for (final c in _classOptions) {
      if (c['id'].toString() == classId) return c['grade'] as String?;
    }
    return null;
  }

  void _onFilterValueChanged() {
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      _currentStudentId = _authService.currentUser?.id;
      final profile = await _authService.getStudentProfile();
      _myProfile = profile;
      _myClassId = profile?['class_id']?.toString();
      _myMajor = profile?['major'] as String?;

      // Default awal (sekali saja): kalau user belum pernah pilih manual
      // di tab ini, pakai kelas/jurusan/angkatan siswa sendiri.
      _selectedClassId ??= _myClassId;
      _selectedMajor ??= _myMajor;
      _selectedGrade ??= _gradeOfClass(_myClassId);

      var query = _client.from('v_leaderboard').select();

      switch (_scope) {
        case _LeaderboardScope.kelas:
          if (_selectedClassId != null) {
            query = query.eq('class_id', _selectedClassId!);
          }
          break;
        case _LeaderboardScope.jurusan:
          if (_selectedMajor != null) {
            query = query.eq('major', _selectedMajor!);
          }
          break;
        case _LeaderboardScope.angkatan:
          if (_selectedGrade != null) {
            query = query.eq('grade', _selectedGrade!);
          }
          break;
        case _LeaderboardScope.sekolah:
          // tanpa filter tambahan, seluruh sekolah
          break;
      }

      final response = await query
          .order('total_points', ascending: false)
          .order('fastest_scan_time', ascending: true);

      final list = List<Map<String, dynamic>>.from(response)
          .map((m) => _StudentPoints.fromMap(m))
          .toList();

      setState(() {
        _leaderboard = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onScopeChanged(_LeaderboardScope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final myRank = _leaderboard.indexWhere((s) => s.studentId == _currentStudentId);
    final myPoints = myRank >= 0 ? _leaderboard[myRank] : null;

    final hasHero = myPoints != null || _leaderboard.length >= 3;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildTopBar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        children: [
                          _buildScopeSelector(),
                          if (_scope != _LeaderboardScope.sekolah) ...[
                            const SizedBox(height: 10),
                            _buildFilterDropdown(),
                          ],
                        ],
                      ),
                    ),
                    if (hasHero) ...[
                      _buildHeroSection(myPoints, myRank + 1),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 4),
                    if (_leaderboard.isEmpty)
                      _buildEmptyState()
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(Strings.t('all_students'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: _leaderboard
                              .asMap()
                              .entries
                              .skip(_leaderboard.length >= 3 ? 3 : 0)
                              .map((entry) {
                            final rank = entry.key + 1;
                            final student = entry.value;
                            final isMe = student.studentId == _currentStudentId;
                            return _buildRankRow(rank, student, isMe: isMe);
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.leaderboard_outlined, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(Strings.t('no_points_data_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
          const SizedBox(height: 6),
          Text(Strings.t('no_points_data_body'),
              textAlign: TextAlign.center, style: TextStyle(color: textGray, fontSize: 12.5)),
        ],
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
          Text(Strings.t('leaderboard_title'),
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

  // ---------- Filter kelas / jurusan / sekolah (logic tidak diubah) ----------
  Widget _buildScopeSelector() {
    Widget chip(String label, _LeaderboardScope scope) {
      final selected = _scope == scope;
      return Expanded(
        child: GestureDetector(
          onTap: () => _onScopeChanged(scope),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? primaryColor : const Color(0xFFEDEFF5),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textGray,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(Strings.t('scope_class'), _LeaderboardScope.kelas),
        chip(Strings.t('scope_major'), _LeaderboardScope.jurusan),
        chip(Strings.t('scope_batch'), _LeaderboardScope.angkatan),
        chip(Strings.t('scope_school'), _LeaderboardScope.sekolah),
      ],
    );
  }

  // ---------- Dropdown pilihan spesifik (kelas mana / jurusan mana / angkatan mana) ----------
  Widget _buildFilterDropdown() {
    switch (_scope) {
      case _LeaderboardScope.kelas:
        return _dropdownBox<String>(
          value: _selectedClassId,
          hint: Strings.t('select_class_hint'),
          items: _classOptions
              .map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'] as String)))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedClassId = val);
            _onFilterValueChanged();
          },
        );
      case _LeaderboardScope.jurusan:
        return _dropdownBox<String>(
          value: _selectedMajor,
          hint: Strings.t('select_major_hint'),
          items: _majorOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            setState(() => _selectedMajor = val);
            _onFilterValueChanged();
          },
        );
      case _LeaderboardScope.angkatan:
        return _dropdownBox<String>(
          value: _selectedGrade,
          hint: Strings.t('select_grade_hint'),
          items: _gradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (val) {
            setState(() => _selectedGrade = val);
            _onFilterValueChanged();
          },
        );
      case _LeaderboardScope.sekolah:
        return const SizedBox.shrink();
    }
  }

  Widget _dropdownBox<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: textGray)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: textGray, size: 20),
          style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------- Hero biru: card identitas + podium ----------
  Widget _buildHeroSection(_StudentPoints? me, int myRank) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          if (me != null) _buildIdentityCard(me, myRank),
          if (_leaderboard.length >= 3) ...[
            const SizedBox(height: 24),
            _buildPodium(),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentityCard(_StudentPoints me, int rank) {
    final avatarUrl = _myProfile?['avatar_url'] as String?;
    final nisn = _myProfile?['nisn'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 14)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${me.className ?? '-'}  •  NISN $nisn',
                    style: const TextStyle(color: textGray, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Strings.t('rank_label'),
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
              Text('#$rank',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
              Text('${me.totalPoints} ${Strings.t('points_unit')}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: pointsAccent)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Podium untuk 3 besar ----------
  Widget _buildPodium() {
    final top3 = _leaderboard.take(3).toList();
    // urutan visual: 2nd - 1st - 3rd
    final ordered = [
      if (top3.length > 1) top3[1],
      top3[0],
      if (top3.length > 2) top3[2],
    ];
    final heights = [70.0, 90.0, 56.0];
    final ringColors = [silver, gold, bronze];
    final ranks = top3.length > 2 ? [2, 1, 3] : [2, 1];

    // Tidak pakai SizedBox(height: tetap) di sini -- kolom peringkat 1 lebih
    // tinggi dari 2 & 3 (ada trophy icon + avatar lebih besar + bar lebih
    // tinggi), jadi tinggi total tiap kolom berbeda. Row dibiarkan
    // menghitung tinggi alaminya sendiri (mengikuti kolom tertinggi),
    // supaya tidak overflow dan supaya alignment .end tetap membuat semua
    // bar duduk sejajar di baseline yang sama.
    return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(ordered.length, (i) {
          final student = ordered[i];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ranks[i] == 1)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.emoji_events, color: gold, size: 20),
                  ),
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColors[i], width: 2.5)),
                  child: CircleAvatar(
                    radius: ranks[i] == 1 ? 26 : 20,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    // Pakai foto profil asli kalau ada, sama seperti di
                    // _buildIdentityCard() -- sebelumnya podium selalu
                    // nampilin inisial huruf walau siswa punya avatar_url.
                    backgroundImage: (student.avatarUrl != null && student.avatarUrl!.isNotEmpty)
                        ? NetworkImage(student.avatarUrl!)
                        : null,
                    child: (student.avatarUrl == null || student.avatarUrl!.isEmpty)
                        ? Text(
                            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                            style: TextStyle(
                                color: primaryColor, fontWeight: FontWeight.bold, fontSize: ranks[i] == 1 ? 18 : 14),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(student.fullName.split(' ').first,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${student.totalPoints} ${Strings.t('points_unit')}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(ranks[i] == 1 ? 0.35 : 0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${ranks[i]}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          );
        }),
      );
  }

  // ---------- Baris ranking (list lengkap) ----------
  Widget _buildRankRow(int rank, _StudentPoints student, {required bool isMe}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? primaryColor.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMe ? Border.all(color: primaryColor, width: 1.3) : null,
        boxShadow: isMe ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: textGray, fontSize: 14)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Text(Strings.t('you_tag'),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 12)),
                    ],
                  ],
                ),
                if (student.className != null)
                  Text(student.className!, style: const TextStyle(fontSize: 11, color: textGray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: pointsAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('${student.totalPoints} ${Strings.t('points_unit')}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: pointsAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}