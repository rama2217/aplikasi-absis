import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';

class ConfirmPhotoScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const ConfirmPhotoScreen({super.key, required this.session});

  @override
  State<ConfirmPhotoScreen> createState() => _ConfirmPhotoScreenState();
}

class _ConfirmPhotoScreenState extends State<ConfirmPhotoScreen> {
  static const primaryColor = Color(0xFF0039A8);
  static const successColor = Color(0xFF3DDC97);
  static const bgColor = Color(0xFFF9F9FF);

  final _authService = AuthService();
  final _attendanceService = AttendanceService();

  CameraController? _cameraController;
  XFile? _capturedPhoto;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final photo = await _cameraController!.takePicture();
    setState(() => _capturedPhoto = photo);
  }

  Future<void> _submit() async {
    if (_capturedPhoto == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final studentId = _authService.currentUser!.id;
      final bytes = await File(_capturedPhoto!.path).readAsBytes();

      final photoUrl = await _attendanceService.uploadProofPhoto(
        studentId,
        widget.session['id'],
        bytes,
      );

      await _attendanceService.submitAttendance(
        studentId: studentId,
        session: widget.session,
        photoUrl: photoUrl,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = Strings.t('submit_attendance_failed');
        _isSubmitting = false;
      });
    }
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(Strings.t('attendance_proof_title')),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.3), width: 3),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: _capturedPhoto != null
                    ? Image.file(File(_capturedPhoto!.path), fit: BoxFit.cover)
                    : (_cameraController != null && _cameraController!.value.isInitialized
                        ? CameraPreview(_cameraController!)
                        : const Center(child: CircularProgressIndicator())),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: successColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Strings.t('scan_success_selfie'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _capturedPhoto == null ? _takePhoto : null,
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
                      label: Text(_capturedPhoto == null ? Strings.t('take_photo') : Strings.t('photo_taken'),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_capturedPhoto != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _capturedPhoto = null),
                      child: Text(Strings.t('retake_photo'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Strings.t('face_verification_notice'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            if (_capturedPhoto != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(Strings.t('submit_attendance'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}