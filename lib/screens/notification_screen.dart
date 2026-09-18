import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import '../services/auth_service.dart';

/// Menampilkan notifikasi sesi presensi untuk HARI INI, dihitung langsung
/// dari tabel `attendance_sessions` milik kelas siswa — bukan log asli
/// notifikasi dari OS (Android/iOS tidak menyediakan API untuk membaca
/// riwayat notifikasi yang sudah tampil ke aplikasi pihak ketiga).
///
/// Sebelumnya halaman ini menampilkan jadwal pelajaran (`schedules`) —
/// fitur itu sudah dihapus karena tidak relevan dengan sistem presensi.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static const primaryColor = Color(0xFF0039A8);
  static const primaryContainer = Color(0xFF2451C9);
  static const bgColor = Color(0xFFF9F9FF);
  static const onSurface = Color(0xFF151C27);
  static const onSurfaceVariant = Color(0xFF434654);
  static const pastColor = Color(0xFF9AA1AE);
  static const nextColor = Color(0xFF3DDC97);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotifItem {
  final DateTime time;
  final String title;
  final String subtitle;
  final bool isClosing; // true = pengingat window akan ditutup

  _NotifItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.isClosing,
  });
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const int _closingReminderMinutes = 10;

  final _client = Supabase.instance.client;
  final _authService = AuthService();

  bool _isLoading = true;
  List<_NotifItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadTodayNotifications();
  }

  Future<void> _loadTodayNotifications() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getStudentProfile();
      final classId = profile?['class_id'];
      final now = DateTime.now();
      final isEnglish = AppLanguage.instance.isEnglish;

      final items = <_NotifItem>[];

      if (classId != null) {
        final todayStr = now.toIso8601String().split('T').first;

        final response = await _client
            .from('attendance_sessions')
            .select('id, session_date, window_start, window_end')
            .eq('class_id', classId)
            .eq('session_date', todayStr)
            .order('window_start', ascending: true);

        final sessions = List<Map<String, dynamic>>.from(response);

        for (final session in sessions) {
          final windowStartStr = session['window_start'] as String?;
          final windowEndStr = session['window_end'] as String?;
          if (windowStartStr == null || windowEndStr == null) continue;

          final openTime = _parseTimeToday(now, windowStartStr);
          final closeTime = _parseTimeToday(now, windowEndStr);
          if (openTime == null || closeTime == null) continue;

          items.add(_NotifItem(
            time: openTime,
            title: Strings.t('notification_session_open'),
            subtitle: isEnglish
                ? 'Attendance window is open, scan the QR code now'
                : 'Sesi presensi dibuka, scan QR sekarang',
            isClosing: false,
          ));

          final closingReminder = closeTime.subtract(const Duration(minutes: _closingReminderMinutes));
          items.add(_NotifItem(
            time: closingReminder,
            title: Strings.t('notification_session_closing'),
            subtitle: isEnglish
                ? 'Only $_closingReminderMinutes minutes left before it closes'
                : 'Tinggal $_closingReminderMinutes menit lagi sebelum ditutup',
            isClosing: true,
          ));
        }
      }

      items.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  DateTime? _parseTimeToday(DateTime today, String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(today.year, today.month, today.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final now = DateTime.now();
    // Index item "berikutnya": item pertama yang waktunya masih di depan now.
    final nextIndex = _items.indexWhere((item) => item.time.isAfter(now));

    return Scaffold(
      backgroundColor: NotificationScreen.bgColor,
      appBar: AppBar(
        title: Text(
          Strings.t('notifications_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: NotificationScreen.primaryColor),
        ),
        centerTitle: true,
        backgroundColor: NotificationScreen.bgColor,
        elevation: 0,
        foregroundColor: NotificationScreen.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NotificationScreen.primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    Strings.t('notifications_derived_note'),
                    style: const TextStyle(fontSize: 11, color: NotificationScreen.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text(
                            Strings.t('notifications_empty_today'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTodayNotifications,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final isPast = item.time.isBefore(now);
                              final isNext = index == nextIndex;
                              return _buildNotifCard(item, isPast: isPast, isNext: isNext);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotifCard(_NotifItem item, {required bool isPast, required bool isNext}) {
    final timeLabel =
        '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    String statusText;
    if (isNext) {
      statusColor = NotificationScreen.nextColor;
      statusText = Strings.t('notification_status_next');
    } else if (isPast) {
      statusColor = NotificationScreen.pastColor;
      statusText = Strings.t('notification_status_past');
    } else {
      statusColor = NotificationScreen.primaryContainer;
      statusText = Strings.t('notification_status_upcoming');
    }

    return Opacity(
      opacity: isPast && !isNext ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isNext ? Border.all(color: NotificationScreen.nextColor, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NotificationScreen.primaryContainer.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isClosing ? Icons.timer_outlined : Icons.qr_code_scanner,
                color: NotificationScreen.primaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: NotificationScreen.onSurface)),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 12, color: NotificationScreen.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: NotificationScreen.onSurface)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}