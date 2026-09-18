import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'confirm_photo_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  static const primaryColor = Color(0xFF0039A8);

  final MobileScannerController _controller = MobileScannerController();
  final _authService = AuthService();
  final _attendanceService = AttendanceService();

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    try {
      final studentId = _authService.currentUser?.id;
      if (studentId == null) throw Exception(Strings.t('invalid_session'));

      final session = await _attendanceService.validateScannedQr(rawValue, studentId);

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfirmPhotoScreen(session: session)),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true); // kembali ke home, sukses
      } else {
        await _controller.start();
        setState(() => _isProcessing = false);
      }
    } on QrValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(Strings.t('generic_error_retry'));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Strings.t('scan_failed_title')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.start();
              setState(() => _isProcessing = false);
            },
            child: Text(Strings.t('try_again')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(Strings.t('scan_qr_title'), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay gelap
          Container(color: Colors.black.withOpacity(0.35)),

          // Viewfinder frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  Strings.t('point_camera_qr'),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isProcessing ? Strings.t('validating') : Strings.t('searching_code'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleButton(
                  icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                  label: Strings.t('torch'),
                  onTap: () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
                const SizedBox(width: 40),
                _circleButton(icon: Icons.image_outlined, label: Strings.t('gallery'), onTap: () {}),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

extension on List<Barcode> {
  Barcode? get firstOrNull => isEmpty ? null : first;
}