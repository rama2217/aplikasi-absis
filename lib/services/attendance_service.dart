import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class QrValidationException implements Exception {
  final String message;
  QrValidationException(this.message);
  @override
  String toString() => message;
}

class AttendanceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getTodaySession(int classId) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return await _client
        .from('attendance_sessions')
        .select()
        .eq('class_id', classId)
        .eq('session_date', dateStr)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getAttendanceForSession(String studentId, int sessionId) async {
    return await _client
        .from('attendances')
        .select()
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .maybeSingle();
  }

  /// Ambil setting global (misal qr_expiry_seconds)
  Future<int> _getSettingInt(String key, int fallback) async {
    final row = await _client.from('settings').select('value').eq('key', key).maybeSingle();
    if (row == null) return fallback;
    return int.tryParse(row['value'].toString()) ?? fallback;
  }

  /// Validasi hasil scan QR.
  /// Format isi QR (JSON): {"session_id": 12, "token": "abc123"}
  /// Melempar QrValidationException dengan pesan yang bisa ditampilkan ke user.
  Future<Map<String, dynamic>> validateScannedQr(String rawQrValue, String studentId) async {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(rawQrValue) as Map<String, dynamic>;
    } catch (_) {
      throw QrValidationException('QR Code tidak valid');
    }

    final sessionId = payload['session_id'];
    final token = payload['token'];
    if (sessionId == null || token == null) {
      throw QrValidationException('QR Code tidak valid');
    }

    final session = await _client
        .from('attendance_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (session == null) {
      throw QrValidationException('Sesi presensi tidak ditemukan');
    }

    // WAJIB: pastikan siswa yang scan memang murid dari kelas pemilik sesi
    // ini. Tanpa cek ini, siswa dari kelas manapun bisa submit presensi ke
    // sesi kelas lain hanya dengan scan QR yang salah kiosk (disengaja atau
    // tidak), karena token & expiry saja tidak membatasi kelas.
    final student = await _client
        .from('students')
        .select('class_id')
        .eq('id', studentId)
        .maybeSingle();

    if (student == null || student['class_id'] != session['class_id']) {
      throw QrValidationException('QR ini bukan untuk kelasmu');
    }

    if (session['is_active'] != true) {
      throw QrValidationException('Sesi presensi belum/sudah tidak aktif');
    }

    // Cek token cocok dengan token aktif saat ini (mencegah screenshot QR lama)
    if (session['current_qr_token'] != token) {
      throw QrValidationException('QR Code sudah kedaluwarsa, coba scan ulang');
    }

    // Cek selisih waktu generate QR vs sekarang
    final qrGeneratedAt = DateTime.parse(session['qr_generated_at']).toLocal();
    final expirySeconds = await _getSettingInt('qr_expiry_seconds', 15);
    final diff = DateTime.now().difference(qrGeneratedAt).inSeconds;

    if (diff > expirySeconds) {
      throw QrValidationException('QR Code kedaluwarsa');
    }

    // Cek sudah pernah absen di sesi ini
    final existing = await getAttendanceForSession(studentId, sessionId);
    if (existing != null) {
      throw QrValidationException('Kamu sudah melakukan presensi hari ini');
    }

    return session;
  }

  /// Tentukan status Hadir/Telat berdasarkan late_threshold di sesi
  String determineStatus(Map<String, dynamic> session) {
    final now = TimeOfDayCompare.now();
    final lateThreshold = session['late_threshold'] as String; // format "HH:mm:ss"
    final parts = lateThreshold.split(':');
    final thresholdMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

    return now > thresholdMinutes ? 'telat' : 'hadir';
  }

  /// Upload foto bukti ke Supabase Storage, return public/signed URL
  Future<String> uploadProofPhoto(String studentId, int sessionId, List<int> bytes) async {
    final fileName = '$studentId/$sessionId-${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('bukti-presensi').uploadBinary(
          fileName,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Karena bucket private, generate signed URL (berlaku lama, misal 1 tahun)
    final signedUrl = await _client.storage
        .from('bukti-presensi')
        .createSignedUrl(fileName, 60 * 60 * 24 * 365);

    return signedUrl;
  }

  /// Submit presensi final ke tabel attendances
  Future<void> submitAttendance({
    required String studentId,
    required Map<String, dynamic> session,
    required String photoUrl,
  }) async {
    final status = determineStatus(session);

    await _client.from('attendances').insert({
      'student_id': studentId,
      'session_id': session['id'],
      'status': status,
      'photo_url': photoUrl,
      // WAJIB diisi eksplisit -- kalau kolom ini NOT NULL tanpa default
      // di database, insert bakal gagal total tanpa scanned_at ini.
      // Dipakai juga oleh calculate_points() dan penentuan hadir/telat.
      'scanned_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, int>> getMonthlyRecap(String studentId) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final firstDayStr = '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01';

    final leaves = await _client
        .from('leave_requests')
        .select('type')
        .eq('student_id', studentId)
        .eq('status', 'approved')
        .gte('leave_date', firstDayStr);

    int sakit = 0;
    int izin = 0;
    for (final row in leaves) {
      if (row['type'] == 'sakit') sakit++;
      if (row['type'] == 'izin') izin++;
    }

    final attendances = await _client
        .from('attendances')
        .select('status, attendance_sessions!inner(session_date)')
        .eq('student_id', studentId)
        .gte('attendance_sessions.session_date', firstDayStr);

    int hadir = 0;
    int telat = 0;
    int alpa = 0;
    for (final row in attendances as List) {
      switch (row['status']) {
        case 'hadir':
          hadir++;
          break;
        case 'telat':
          telat++;
          break;
        case 'alpa':
          alpa++;
          break;
      }
    }

    return {
      'sakit': sakit,
      'izin': izin,
      'hadir': hadir,
      'telat': telat,
      'alpa': alpa,
    };
  }
}

/// Helper kecil untuk bandingkan jam sekarang (dalam menit) vs late_threshold
class TimeOfDayCompare {
  static int now() {
    final n = DateTime.now();
    return n.hour * 60 + n.minute;
  }
}