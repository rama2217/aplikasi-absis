import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveRequestService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Upload lampiran (surat dokter/pendukung) ke Supabase Storage.
  /// Mengembalikan path (dibutuhkan untuk rollback) sekaligus signed URL.
  Future<({String path, String url})> uploadAttachment(
      String studentId, String fileName, Uint8List bytes) async {
    final path = '$studentId/${DateTime.now().millisecondsSinceEpoch}-$fileName';

    // Deteksi Content-Type dari ekstensi file — tanpa ini, uploadBinary()
    // mengirim default application/octet-stream, yang ditolak (400) oleh
    // bucket bukti-presensi karena Allowed MIME types-nya dibatasi.
    final ext = fileName.toLowerCase().split('.').last;
    final contentType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };

    await _client.storage.from('bukti-presensi').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    final url = await _client.storage.from('bukti-presensi').createSignedUrl(path, 60 * 60 * 24 * 365);
    return (path: path, url: url);
  }

  /// Submit pengajuan izin/sakit.
  ///
  /// Kalau [attachmentPath] diisi dan insert ke leave_requests gagal
  /// (misal 409 karena tanggal sudah pernah diajukan), file yang sudah
  /// kadung diupload ke Storage akan dihapus lagi supaya tidak jadi
  /// file yatim — lalu error aslinya tetap dilempar ke pemanggil.
  Future<void> submitLeaveRequest({
    required String studentId,
    required String type, // 'sakit' atau 'izin'
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentUrl,
    String? attachmentPath,
  }) async {
    // Karena schema kita: 1 row = 1 tanggal (unique student_id + leave_date),
    // kalau rentang tanggal lebih dari 1 hari, insert 1 row per tanggal
    final days = endDate.difference(startDate).inDays + 1;

    final rows = List.generate(days, (i) {
      final date = startDate.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return {
        'student_id': studentId,
        'leave_date': dateStr,
        'type': type,
        'reason': reason,
        'attachment_url': attachmentUrl,
        'status': 'pending',
      };
    });

    try {
      await _client.from('leave_requests').insert(rows);
    } catch (e) {
      if (attachmentPath != null) {
        try {
          await _client.storage.from('bukti-presensi').remove([attachmentPath]);
        } catch (_) {
          // Rollback gagal (misal koneksi putus) — dibiarkan jadi file
          // yatim daripada menutupi error asli dari insert di atas.
        }
      }
      rethrow;
    }
  }

  /// Ambil riwayat pengajuan izin siswa
  Future<List<Map<String, dynamic>>> getMyLeaveRequests(String studentId) async {
    final response = await _client
        .from('leave_requests')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}