import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bahasa yang didukung aplikasi.
enum AppLang { id, en }

/// Singleton global untuk menyimpan & mengubah bahasa aplikasi saat ini.
///
/// Cukup dengarkan lewat `AnimatedBuilder(animation: AppLanguage.instance, ...)`
/// atau `ListenableBuilder` di widget mana pun yang perlu rebuild saat bahasa
/// berubah. Pilihan bahasa disimpan secara permanen di penyimpanan lokal
/// perangkat (SharedPreferences) sehingga tetap tersimpan walau aplikasi
/// ditutup/di-restart. Panggil [AppLanguage.load] sekali di awal main()
/// sebelum runApp() untuk memuat preferensi yang tersimpan.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final AppLanguage instance = AppLanguage._();

  static const _prefsKey = 'app_language';

  AppLang _lang = AppLang.id;
  AppLang get lang => _lang;
  bool get isEnglish => _lang == AppLang.en;

  /// Muat bahasa yang tersimpan dari penyimpanan lokal. Panggil di main()
  /// sebelum runApp() supaya tampilan pertama sudah sesuai preferensi user.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'en') {
        _lang = AppLang.en;
      } else {
        _lang = AppLang.id;
      }
      notifyListeners();
    } catch (_) {
      // Jika SharedPreferences gagal (mis. platform belum didukung),
      // tetap gunakan default 'id' tanpa membuat app crash.
    }
  }

  Future<void> toggle() async {
    _lang = _lang == AppLang.id ? AppLang.en : AppLang.id;
    notifyListeners();
    await _save();
  }

  Future<void> set(AppLang lang) async {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _lang == AppLang.en ? 'en' : 'id');
    } catch (_) {
      // Best-effort: kalau gagal simpan, bahasa tetap berlaku untuk sesi ini.
    }
  }
}
