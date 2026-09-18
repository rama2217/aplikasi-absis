import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Menangani foto profil siswa (bucket Storage `avatars` + kolom
/// `students.avatar_url`). Dipisah dari AuthService karena ini murni
/// urusan file/media, bukan otentikasi.
class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _bucket = 'avatars';
  static const _allowedExtensions = ['jpg', 'jpeg', 'png'];

  String _contentTypeFor(String ext) => switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/octet-stream',
      };

  /// Upload/ganti foto profil siswa.
  ///
  /// Path selalu `{studentId}/avatar.{ext}` dengan upsert: true — jadi
  /// upload baru dengan ekstensi yang sama otomatis menimpa yang lama,
  /// tanpa perlu tracking path file sebelumnya secara terpisah.
  Future<String> uploadProfilePhoto({
    required String studentId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = fileName.toLowerCase().split('.').last;
    final path = '$studentId/avatar.$ext';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(ext), upsert: true),
        );

    final url = await _client.storage.from(_bucket).createSignedUrl(path, 60 * 60 * 24 * 365);

    try {
      await _client.from('students').update({'avatar_url': url}).eq('id', studentId);
    } catch (e) {
      // Rollback: kalau gagal disimpan ke DB, hapus lagi file yang baru diupload
      // supaya tidak jadi file yatim (pola yang sama dengan LeaveRequestService).
      try {
        await _client.storage.from(_bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }

    // Kalau foto sebelumnya pakai ekstensi lain (mis. dulu .png, sekarang
    // upload .jpg), upsert di atas tidak menimpanya — bersihkan best-effort.
    for (final otherExt in _allowedExtensions.where((e) => e != ext)) {
      try {
        await _client.storage.from(_bucket).remove(['$studentId/avatar.$otherExt']);
      } catch (_) {
        // Aman diabaikan — kemungkinan besar memang tidak ada file itu
      }
    }

    return url;
  }

  /// Hapus foto profil siswa: hapus file dari Storage (semua kemungkinan
  /// ekstensi, best-effort) & kosongkan avatar_url di tabel students.
  Future<void> removeProfilePhoto(String studentId) async {
    for (final ext in _allowedExtensions) {
      try {
        await _client.storage.from(_bucket).remove(['$studentId/avatar.$ext']);
      } catch (_) {}
    }
    await _client.from('students').update({'avatar_url': null}).eq('id', studentId);
  }
}
