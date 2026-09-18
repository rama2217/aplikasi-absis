import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'attendance_history_screen.dart';
import 'leave_request_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_streak_screen.dart';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const primaryColor = Color(0xFF3B5FE0);

  // _screens sekarang dibuat di dalam method (bukan `const` field lagi),
  // karena LeaveRequestScreen butuh callback `onSubmitted` yang mengacu ke
  // `this` (_MainNavigationState) — closure seperti ini tidak bisa dipakai
  // dalam const constructor.
  List<Widget> get _screens => [
        const HomeScreen(),
        const AttendanceHistoryScreen(),
        LeaveRequestScreen(
          // Dipanggil dari LeaveRequestScreen setelah pengajuan izin
          // berhasil dikirim, supaya user otomatis dipindah balik ke tab
          // Home — pengganti Navigator.pop yang tidak bisa dipakai di sini
          // karena LeaveRequestScreen cuma tab di IndexedStack, bukan
          // halaman yang di-push lewat Navigator.
          onSubmitted: () => setState(() => _currentIndex = 0),
        ),
        const LeaderboardStreakScreen(),
        const ProfileScreen(),
      ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.event_busy_rounded), label: 'Leave'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Leaderboard'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}