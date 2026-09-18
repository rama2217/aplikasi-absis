import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/leave_request_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';
import 'notification_screen.dart';

class LeaveRequestScreen extends StatefulWidget {
  // Karena layar ini dipakai sebagai salah satu tab di IndexedStack
  // (main_navigation.dart), bukan di-push lewat Navigator, kita tidak bisa
  // pakai Navigator.pop untuk "kembali" setelah submit. Sebagai gantinya,
  // MainNavigation kasih callback ini supaya bisa pindah balik ke tab Home
  // setelah pengajuan berhasil dikirim.
  final VoidCallback? onSubmitted;

  const LeaveRequestScreen({super.key, this.onSubmitted});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  // Design tokens — disamakan dengan palet Login/Beranda/History
  static const primaryColor = Color(0xFF3B5FE0);
  static const bgColor = Color(0xFFF4F5F9);
  static const textDark = Color(0xFF1B2033);
  static const textGray = Colors.grey;
  static const surfaceHigh = Color(0xFFEFF1F7);
  static const dangerColor = Color(0xFFE4483A);

  final _authService = AuthService();
  final _leaveService = LeaveRequestService();
  final _reasonController = TextEditingController();

  // 'sakit' / 'izin'
  String _selectedType = 'sakit';
  DateTime? _startDate;
  DateTime? _endDate;
  PlatformFile? _attachment;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Label lampiran menyesuaikan jenis pengajuan — "Sakit" tetap minta surat
  // dokter, sementara "Izin" pakai istilah umum karena tidak selalu ada
  // surat dokter (misal izin acara keluarga).
  String get _attachmentLabel => _selectedType == 'sakit'
      ? Strings.t('attachment_label_sakit')
      : Strings.t('attachment_label_izin');

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachment = result.files.first);
    }
  }

  Future<void> _submit() async {
    // Tanggal selesai bersifat opsional (sesuai desain) — kalau kosong,
    // dianggap izin/sakit untuk 1 hari saja (endDate = startDate).
    if (_startDate == null) {
      setState(() => _errorMessage = Strings.t('date_range_required'));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = Strings.t('reason_required'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final studentId = _authService.currentUser!.id;
      String? attachmentUrl;
      String? attachmentPath;

      if (_attachment != null && _attachment!.bytes != null) {
        final uploaded = await _leaveService.uploadAttachment(
          studentId,
          _attachment!.name,
          _attachment!.bytes as Uint8List,
        );
        attachmentPath = uploaded.path;
        attachmentUrl = uploaded.url;
      }

      await _leaveService.submitLeaveRequest(
        studentId: studentId,
        type: _selectedType,
        startDate: _startDate!,
        endDate: _endDate ?? _startDate!,
        reason: _reasonController.text.trim(),
        attachmentUrl: attachmentUrl,
        attachmentPath: attachmentPath,
      );

      if (mounted) {
        // PENTING: layar ini adalah salah satu tab di IndexedStack
        // (main_navigation.dart), BUKAN halaman yang di-push lewat
        // Navigator. Jadi TIDAK BOLEH pakai Navigator.pop(context) di sini —
        // itu akan mem-pop route MainNavigation itu sendiri (karena tidak
        // ada Navigator lain yang lebih dekat), dan kalau MainNavigation
        // adalah satu-satunya route yang tersisa di stack (umum terjadi
        // kalau dari login pakai pushReplacement), hasilnya layar jadi
        // kosong/blank putih tanpa error yang jelas.
        //
        // Solusinya: reset form di tab ini + kasih tahu MainNavigation
        // lewat callback supaya pindah balik ke tab Home sendiri.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('leave_request_submitted'))),
        );

        setState(() {
          _reasonController.clear();
          _startDate = null;
          _endDate = null;
          _attachment = null;
          _isSubmitting = false;
        });

        widget.onSubmitted?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = Strings.t('leave_request_failed');
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
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _buildTypeToggle(),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Strings.t('choose_date').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                Strings.t('start_date'),
                                _startDate,
                                () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                '${Strings.t('end_date')}',
                                _endDate,
                                () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(Strings.t('reason_notes').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reasonController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: Strings.t('reason_hint'),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(_attachmentLabel.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: textGray, letterSpacing: 0.6)),
                        const SizedBox(height: 10),
                        _buildAttachmentPicker(),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: dangerColor), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(Strings.t('submit_request'),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ],
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
          Text(
            Strings.t('leave_request_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
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
                  decoration: const BoxDecoration(color: dangerColor, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _typeButton('sakit', Strings.t('sick'))),
          Expanded(child: _typeButton('izin', Strings.t('permission'))),
        ],
      ),
    );
  }

  Widget _typeButton(String value, String label) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textGray,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 11.5)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('d MMM yyyy', 'id_ID').format(value)
                        : Strings.t('date_placeholder'),
                    style: TextStyle(color: value != null ? textDark : Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 15, color: textGray),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPicker() {
    return GestureDetector(
      onTap: _pickAttachment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.4),
          color: bgColor,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.upload_file_rounded, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              _attachment?.name ?? Strings.t('click_to_upload'),
              style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13.5),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(Strings.t('file_type_hint'), style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}