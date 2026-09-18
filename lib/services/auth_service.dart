import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _emailDomain = 'absis.internal';

  /// Login siswa menggunakan NISN + password
  Future<AuthResponse> loginWithNisn(String nisn, String password) async {
    final email = '$nisn@$_emailDomain';
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Ganti password siswa yang sedang login.
  /// Supabase mengharuskan sesi masih aktif (user sudah login) untuk update password.
  /// Untuk memverifikasi password lama, kita coba sign-in ulang dulu dengan email + password lama.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan, silakan login ulang');
    }

    final email = user.email;
    if (email == null) {
      throw Exception('Email akun tidak ditemukan');
    }

    // Verifikasi password lama dengan mencoba sign-in ulang
    try {
      await _client.auth.signInWithPassword(email: email, password: oldPassword);
    } on AuthException {
      throw Exception('Password lama tidak sesuai');
    }

    // Update ke password baru
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  /// Ambil data profil siswa dari tabel `students`, sekaligus join ke `classes`
  /// biar nama kelas & jurusan ikut kebawa (dipakai di Beranda: "XI RPL A").
  Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('students')
        .select('*, classes(name, major)')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Update alamat & no. HP siswa yang sedang login
  Future<void> updateStudentProfile({
    String? address,
    String? phoneNumber,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('Sesi tidak ditemukan, silakan login ulang');
    }

    await _client.from('students').update({
      'address': address,
      'phone_number': phoneNumber,
    }).eq('id', userId);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}