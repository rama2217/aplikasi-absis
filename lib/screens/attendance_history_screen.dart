import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/leave_request_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'notification_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // Design tokens — disamakan dengan palet di Login/Beranda/Main Navigation
  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;
  static const surfaceContainerHigh = Color(0xFFEFF1F7);
  static const hadirColor = Color(0xFF1FA35A);
  static const telatColor = Color(0xFFD99A1A);
  static const alpaColor = Color(0xFFE4483A);

  final _client = Supabase.instance.client;
  final _authService = AuthService();
  final _leaveService = LeaveRequestService();

  // 0 = tab Riwayat Presensi, 1 = tab Riwayat Izin
  int _selectedTab = 0;

  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  late DateTime _selectedMonth;
  final List<DateTime> _monthOptions = [];

  bool _isLoadingLeave = false;
  List<Map<String, dynamic>> _leaveHistory = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    for (int i = -1; i <= 1; i++) {
      _monthOptions.add(DateTime(now.year, now.month + i, 1));
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final studentId = _authService.currentUser?.id;
      if (studentId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      final firstDayStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final lastDayStr = DateFormat('yyyy-MM-dd').format(lastDay);

      final response = await _client
          .from('attendances')
          .select('*, attendance_sessions!inner(session_date)')
          .eq('student_id', studentId)
          .gte('attendance_sessions.session_date', firstDayStr)
          .lte('attendance_sessions.session_date', lastDayStr)
          .order('scanned_at', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load attendance history: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaveHistory() async {
    setState(() => _isLoadingLeave = true);
    try {
      final studentId = _authService.currentUser?.id;
      if (studentId == null) {
        setState(() => _isLoadingLeave = false);
        return;
      }

      final rows = await _leaveService.getMyLeaveRequests(studentId);
      setState(() {
        _leaveHistory = rows;
        _isLoadingLeave = false;
      });
    } catch (e) {
      debugPrint('Error load leave history: $e');
      setState(() => _isLoadingLeave = false);
    }
  }

  int get _hadirCount => _history.where((h) => h['status'] == 'hadir').length;
  int get _telatCount => _history.where((h) => h['status'] == 'telat').length;
  int get _alpaCount => _history.where((h) => h['status'] == 'alpa').length;

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
            _buildTopBar(),
            _buildSegmentedTab(),
            if (_selectedTab == 0) ...[
              _buildMonthSelector(),
              _buildSummaryCard(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _history.isEmpty
                        ? Center(
                            child: Text(Strings.t('no_history_this_month'),
                                style: const TextStyle(color: Colors.grey)),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _history.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _buildHistoryItem(_history[index]),
                            ),
                          ),
              ),
            ] else
              Expanded(
                child: _isLoadingLeave
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _leaveHistory.isEmpty
                        ? Center(
                            child: Text(Strings.t('no_leave_history'),
                                style: const TextStyle(color: Colors.grey)),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLeaveHistory,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              itemCount: _leaveHistory.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _buildLeaveHistoryItem(_leaveHistory[index]),
                            ),
                          ),
              ),
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
          const Text(
            'History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_none, color: textDark),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: alpaColor, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: _segmentButton(0, Strings.t('tab_attendance_history'))),
            Expanded(child: _segmentButton(1, Strings.t('tab_leave_history'))),
          ],
        ),
      ),
    );
  }

  Widget _segmentButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 1 && _leaveHistory.isEmpty && !_isLoadingLeave) {
          _loadLeaveHistory();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : textGray,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _monthOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = _monthOptions[index];
          final isSelected = month.month == _selectedMonth.month && month.year == _selectedMonth.year;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMonth = month);
              _loadHistory();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : const Color(0xFFEDEFF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('MMMM', 'id_ID').format(month),
                style: TextStyle(
                  color: isSelected ? Colors.white : textGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth).toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY: $monthLabel',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textGray,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryChip(hadirColor, _hadirCount, Strings.t('status_present'))),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(telatColor, _telatCount, Strings.t('status_late'))),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(alpaColor, _alpaCount, Strings.t('status_alpa'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(Color color, int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final sessionDate = item['attendance_sessions']?['session_date'];
    final status = item['status'] as String? ?? 'alpa';
    final scannedAt = item['scanned_at'];

    final dateFormatted = sessionDate != null
        ? DateFormat('d MMMM yyyy').format(DateTime.parse(sessionDate))
        : '-';
    final timeFormatted =
        scannedAt != null ? DateFormat('hh:mm a').format(DateTime.parse(scannedAt).toLocal()) : '--:--';

    Color statusColor;
    String badgeText;
    IconData rowIcon;
    IconData badgeIcon;
    switch (status) {
      case 'hadir':
        statusColor = hadirColor;
        badgeText = Strings.t('status_present');
        rowIcon = Icons.calendar_month_rounded;
        badgeIcon = Icons.check_circle_rounded;
        break;
      case 'telat':
        statusColor = telatColor;
        badgeText = Strings.t('status_late');
        rowIcon = Icons.access_time_filled_rounded;
        badgeIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = alpaColor;
        badgeText = Strings.t('status_alpa');
        rowIcon = Icons.event_busy_rounded;
        badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(rowIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormatted,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(status == 'alpa' ? '--:--' : timeFormatted,
                    style: const TextStyle(color: textGray, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 13, color: statusColor),
                const SizedBox(width: 4),
                Text(badgeText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistoryItem(Map<String, dynamic> item) {
    final leaveDate = item['leave_date'];
    final type = item['type'] as String? ?? 'izin'; // 'sakit' atau 'izin'
    final status = item['status'] as String? ?? 'pending';
    final reason = item['reason'] as String? ?? '-';

    final dateFormatted =
        leaveDate != null ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.parse(leaveDate)) : '-';
    final typeLabel = type == 'sakit' ? Strings.t('sick') : Strings.t('permission');

    Color statusColor;
    String badgeText;
    switch (status) {
      case 'approved':
        statusColor = hadirColor;
        badgeText = Strings.t('leave_status_approved');
        break;
      case 'rejected':
        statusColor = alpaColor;
        badgeText = Strings.t('leave_status_rejected');
        break;
      default:
        statusColor = telatColor;
        badgeText = Strings.t('leave_status_pending');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              type == 'sakit' ? Icons.medical_services_outlined : Icons.event_busy_outlined,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormatted,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('$typeLabel · $reason',
                    style: const TextStyle(color: textGray, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badgeText,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}