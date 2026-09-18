import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../languages/app_language.dart';
import 'auth_service.dart';

/// Menjadwalkan notifikasi lokal berdasarkan SESI PRESENSI siswa
/// (window presensi dibuka, window presensi akan ditutup).
/// Sebelumnya mengikuti jadwal pelajaran (`schedules`) — fitur itu sudah
/// dihapus karena tidak relevan dengan sistem presensi, jadi sumber
/// notifikasi sekarang diambil langsung dari tabel `attendance_sessions`
/// milik kelas siswa yang bersangkutan.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _client = Supabase.instance.client;
  final _authService = AuthService();
  bool _initialized = false;

  /// Berapa menit sebelum window_end untuk mengirim notifikasi "akan ditutup".
  static const int _closingReminderMinutes = 10;

  static const _androidDetails = AndroidNotificationDetails(
    'attendance_session_channel',
    'Sesi Presensi',
    channelDescription: 'Notifikasi window presensi dibuka dan akan ditutup',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Panggil sekali di awal (misal saat MainNavigation pertama kali dibuka).
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Asumsi zona waktu sekolah WIB. Sesuaikan kalau lokasi sekolah beda zona.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+ butuh izin runtime untuk menampilkan notifikasi.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    // Android 12+ butuh izin khusus supaya notifikasi terjadwal muncul TEPAT waktu.
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Ambil sesi presensi mendatang (hari ini dan seterusnya) untuk kelas
  /// siswa yang sedang login.
  Future<List<Map<String, dynamic>>> _getUpcomingSessionsForCurrentStudent() async {
    final profile = await _authService.getStudentProfile();
    final classId = profile?['class_id'];
    if (classId == null) return [];

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('attendance_sessions')
        .select('id, session_date, window_start, window_end')
        .eq('class_id', classId)
        .gte('session_date', todayStr)
        .order('session_date', ascending: true)
        .limit(14); // ±2 minggu ke depan, cukup untuk penjadwalan notifikasi

    return List<Map<String, dynamic>>.from(response);
  }

  /// Hapus semua notifikasi lama, lalu jadwalkan ulang dari sesi presensi
  /// terbaru milik kelas siswa yang sedang login. Aman dipanggil berkali-kali
  /// (misal tiap kali MainNavigation dibuka) — hanya makan waktu singkat.
  Future<void> syncSessionNotifications() async {
    if (!_initialized) await init();

    await _plugin.cancelAll();

    final sessions = await _getUpcomingSessionsForCurrentStudent();
    final isEnglish = AppLanguage.instance.isEnglish;

    int id = 0;
    for (final session in sessions) {
      final sessionDateStr = session['session_date'] as String?;
      final windowStartStr = session['window_start'] as String?;
      final windowEndStr = session['window_end'] as String?;
      if (sessionDateStr == null || windowStartStr == null || windowEndStr == null) continue;

      final openTime = _combineDateAndTime(sessionDateStr, windowStartStr);
      final closeTime = _combineDateAndTime(sessionDateStr, windowEndStr);
      if (openTime == null || closeTime == null) continue;

      // Notifikasi: window presensi dibuka
      if (openTime.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          id: id++,
          title: isEnglish ? 'Attendance window is open' : 'Sesi presensi dibuka',
          body: isEnglish
              ? 'You can scan the QR code now to mark attendance.'
              : 'Kamu bisa scan QR sekarang untuk melakukan presensi.',
          scheduledDate: openTime,
          notificationDetails: _notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // Notifikasi: window presensi akan ditutup sebentar lagi
      final closingReminder = closeTime.subtract(const Duration(minutes: _closingReminderMinutes));
      if (closingReminder.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          id: id++,
          title: isEnglish ? 'Attendance window closing soon' : 'Sesi presensi akan ditutup',
          body: isEnglish
              ? 'Only $_closingReminderMinutes minutes left to scan the QR code.'
              : 'Tinggal $_closingReminderMinutes menit lagi untuk scan QR presensi.',
          scheduledDate: closingReminder,
          notificationDetails: _notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  /// Gabungkan tanggal (`yyyy-MM-dd`) dan jam (`HH:mm[:ss]`) menjadi
  /// TZDateTime pada zona waktu lokal.
  tz.TZDateTime? _combineDateAndTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);
      final timeParts = timeStr.split(':');
      if (timeParts.length < 2) return null;
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) return null;

      return tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Batalkan semua notifikasi (misal dipanggil saat logout).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}