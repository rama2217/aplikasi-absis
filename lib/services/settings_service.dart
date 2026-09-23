import 'package:supabase_flutter/supabase_flutter.dart';

/// Ambil konten halaman Tentang Aplikasi & Bantuan dari tabel `settings`
/// (key-value), yang diisi admin lewat halaman Pengaturan di Laravel.
class SettingsService {
  static const keyAboutDescription = 'about_description';
  static const keyAboutVersion = 'about_version';
  static const keyHelpAdminName = 'help_admin_name';
  static const keyHelpAdminContact = 'help_admin_contact';

  static const _mobileKeys = [
    keyAboutDescription,
    keyAboutVersion,
    keyHelpAdminName,
    keyHelpAdminContact,
  ];

  /// Return map `key -> value` untuk key yang ADA dan TIDAK kosong.
  /// Kalau request gagal, atau RLS memblokir (hasilnya list kosong tanpa
  /// error), return map kosong supaya layar pakai teks fallback.
  static Future<Map<String, String>> fetchMobileSettings() async {
    try {
      final rows = await Supabase.instance.client
          .from('settings')
          .select('key, value')
          .inFilter('key', _mobileKeys);

      final result = <String, String>{};
      for (final row in rows) {
        final value = row['value']?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          result[row['key'] as String] = value;
        }
      }

      if (result.isEmpty) {
        // ignore: avoid_print
        print('FETCH SETTINGS: 0 baris kembali (cek RLS policy SELECT di settings)');
      }
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('FETCH SETTINGS ERROR: $e');
      return {};
    }
  }
}
