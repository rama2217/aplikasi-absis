import 'app_language.dart';

/// Kumpulan teks terjemahan. Tambahkan key baru di sini saat melokalkan
/// layar lain — pola yang sama bisa dipakai ulang di seluruh aplikasi.
class Strings {
  static const Map<String, Map<AppLang, String>> _values = {
    'profile_title': {AppLang.id: 'AbSis', AppLang.en: 'AbSis'},
    'class_prefix': {AppLang.id: 'Kelas', AppLang.en: 'Class'},
    'class_not_set': {
      AppLang.id: 'Kelas belum diatur',
      AppLang.en: 'Class not set',
    },
    'photo_updated': {
      AppLang.id: 'Foto profil berhasil diperbarui',
      AppLang.en: 'Profile photo updated successfully',
    },
    'photo_upload_failed': {
      AppLang.id: 'Gagal mengunggah foto, coba lagi',
      AppLang.en: 'Failed to upload photo, please try again',
    },
    'photo_removed': {
      AppLang.id: 'Foto profil berhasil dihapus',
      AppLang.en: 'Profile photo removed successfully',
    },
    'photo_remove_failed': {
      AppLang.id: 'Gagal menghapus foto, coba lagi',
      AppLang.en: 'Failed to remove photo, please try again',
    },
    'take_photo_option': {AppLang.id: 'Ambil Foto', AppLang.en: 'Take Photo'},
    'choose_from_gallery': {
      AppLang.id: 'Pilih dari Galeri',
      AppLang.en: 'Choose from Gallery',
    },
    'remove_photo_option': {
      AppLang.id: 'Hapus Foto Profil',
      AppLang.en: 'Remove Profile Photo',
    },
    'cancel': {AppLang.id: 'Batal', AppLang.en: 'Cancel'},
    'remove_photo_confirm_title': {
      AppLang.id: 'Hapus Foto Profil?',
      AppLang.en: 'Remove Profile Photo?',
    },
    'remove_photo_confirm_body': {
      AppLang.id: 'Foto profil Anda akan dihapus secara permanen.',
      AppLang.en: 'Your profile photo will be permanently removed.',
    },
    'remove': {AppLang.id: 'Hapus', AppLang.en: 'Remove'},
    'section_personal_data': {
      AppLang.id: 'Informasi Siswa',
      AppLang.en: 'Student Information',
    },
    'section_school_data': {
      AppLang.id: 'DATA SEKOLAH',
      AppLang.en: 'SCHOOL DATA',
    },
    'address': {AppLang.id: 'Alamat', AppLang.en: 'Address'},
    'email': {AppLang.id: 'Email', AppLang.en: 'Email'},
    'phone': {AppLang.id: 'No. HP', AppLang.en: 'Phone Number'},
    'homeroom_teacher': {
      AppLang.id: 'Wali Kelas',
      AppLang.en: 'Homeroom Teacher',
    },
    'class_label': {AppLang.id: 'Kelas', AppLang.en: 'Class'},
    'change_password': {
      AppLang.id: 'Ganti Password',
      AppLang.en: 'Change Password',
    },
    'language': {AppLang.id: 'Bahasa', AppLang.en: 'Language'},
    'language_indonesian': {AppLang.id: 'Indonesia', AppLang.en: 'Indonesian'},
    'language_english': {AppLang.id: 'Inggris', AppLang.en: 'English'},
    'logout': {AppLang.id: 'Keluar', AppLang.en: 'Log Out'},
    'nisn': {AppLang.id: 'NISN', AppLang.en: 'Student ID (NISN)'},

    // ---- Home screen ----
    'welcome': {AppLang.id: 'Selamat Datang,', AppLang.en: 'Welcome,'},
    'greeting_morning': {
      AppLang.id: 'Selamat Pagi,',
      AppLang.en: 'Good Morning,',
    },
    'greeting_afternoon': {
      AppLang.id: 'Selamat Siang,',
      AppLang.en: 'Good Afternoon,',
    },
    'greeting_evening': {
      AppLang.id: 'Selamat Sore,',
      AppLang.en: 'Good Evening,',
    },
    'greeting_night': {AppLang.id: 'Selamat Malam,', AppLang.en: 'Good Night,'},
    'attendance_summary_title': {
      AppLang.id: 'Ringkasan Kehadiran',
      AppLang.en: 'Attendance Summary',
    },
    'this_month_label': {AppLang.id: 'Bulan ini', AppLang.en: 'This month'},
    'record_attendance_today': {
      AppLang.id: 'Catat kehadiran hari ini',
      AppLang.en: 'Record your attendance today',
    },
    'quote_of_the_day': {
      AppLang.id: 'Quote Hari Ini',
      AppLang.en: 'Quote of the Day',
    },
    'default_student': {AppLang.id: 'Siswa', AppLang.en: 'Student'},
    'today_attendance_status': {
      AppLang.id: 'Status Kehadiran Hari Ini',
      AppLang.en: "Today's Attendance Status",
    },
    'status_present': {AppLang.id: 'HADIR', AppLang.en: 'PRESENT'},
    'status_late': {AppLang.id: 'TELAT', AppLang.en: 'LATE'},
    'status_not_yet': {AppLang.id: 'BELUM ABSEN', AppLang.en: 'NOT CHECKED IN'},
    'check_in_time': {AppLang.id: 'Waktu Masuk', AppLang.en: 'Check-in Time'},
    'check_out_time': {
      AppLang.id: 'Waktu Keluar',
      AppLang.en: 'Check-out Time',
    },
    'not_gone_home': {
      AppLang.id: 'Belum Pulang',
      AppLang.en: 'Not Checked Out',
    },
    'scan_attendance_button': {
      AppLang.id: 'Ambil Presensi (Scan)',
      AppLang.en: 'Check In (Scan)',
    },
    'recap_this_month': {
      AppLang.id: 'Rekap Bulan Ini',
      AppLang.en: 'This Month\'s Recap',
    },
    'view_all': {AppLang.id: 'Lihat Semua', AppLang.en: 'View All'},
    'sick': {AppLang.id: 'Sakit', AppLang.en: 'Sick'},
    'permission': {AppLang.id: 'Izin', AppLang.en: 'Excused'},
    'days_unit': {AppLang.id: 'Hari', AppLang.en: 'Days'},
    'total_attendance': {
      AppLang.id: 'Total Kehadiran',
      AppLang.en: 'Total Attendance',
    },
    'nav_home': {AppLang.id: 'Beranda', AppLang.en: 'Home'},
    'nav_attendance': {AppLang.id: 'Presensi', AppLang.en: 'Attendance'},
    'nav_schedule': {AppLang.id: 'Jadwal', AppLang.en: 'Schedule'},
    'nav_profile': {AppLang.id: 'Profil', AppLang.en: 'Profile'},

    // ---- Leaderboard screen ----
    'leaderboard_title': {AppLang.id: 'Leaderboard', AppLang.en: 'Leaderboard'},
    'scope_class': {AppLang.id: 'Kelas', AppLang.en: 'Class'},
    'scope_major': {AppLang.id: 'Jurusan', AppLang.en: 'Major'},
    'scope_school': {AppLang.id: 'Sekolah', AppLang.en: 'School'},
    'scope_batch': {AppLang.id: 'Angkatan', AppLang.en: 'Batch'},
    'select_class_hint': {
      AppLang.id: 'Pilih Kelas',
      AppLang.en: 'Select Class',
    },
    'select_major_hint': {
      AppLang.id: 'Pilih Jurusan',
      AppLang.en: 'Select Major',
    },
    'select_grade_hint': {
      AppLang.id: 'Pilih Angkatan',
      AppLang.en: 'Select Batch',
    },
    'all_students': {AppLang.id: 'Semua Siswa', AppLang.en: 'All Students'},
    'rank_label': {AppLang.id: 'PERINGKAT', AppLang.en: 'RANK'},
    'points_unit': {AppLang.id: 'poin', AppLang.en: 'pts'},
    'you_tag': {AppLang.id: '(Kamu)', AppLang.en: '(You)'},
    'no_points_data_title': {
      AppLang.id: 'Belum Ada Data',
      AppLang.en: 'No Data Yet',
    },
    'no_points_data_body': {
      AppLang.id: 'Belum ada siswa dengan poin untuk filter ini',
      AppLang.en: 'No students with points for this filter yet',
    },

    // ---- Login screen ----
    'login_id_password_required': {
      AppLang.id: 'ID Siswa dan kata sandi wajib diisi',
      AppLang.en: 'Student ID and password are required',
    },
    'login_invalid_credentials': {
      AppLang.id: 'ID Siswa atau kata sandi salah',
      AppLang.en: 'Incorrect Student ID or password',
    },
    'generic_error_retry': {
      AppLang.id: 'Terjadi kesalahan, coba lagi',
      AppLang.en: 'Something went wrong, please try again',
    },
    'login_title': {AppLang.id: 'AbSis Masuk', AppLang.en: 'AbSis Login'},
    'login_subtitle': {
      AppLang.id: 'Masukkan ID siswa dan kata sandi Anda',
      AppLang.en: 'Enter your student ID and password',
    },
    'student_id_label': {AppLang.id: 'NISN', AppLang.en: 'Student ID'},
    'password_label': {AppLang.id: 'Password', AppLang.en: 'Password'},
    'student_id_hint': {AppLang.id: 'ID Siswa', AppLang.en: 'Student ID'},
    'password_hint': {AppLang.id: 'Kata Sandi', AppLang.en: 'Password'},
    'login_button': {AppLang.id: 'Masuk', AppLang.en: 'Log In'},
    'forgot_password': {
      AppLang.id: 'Lupa Kata Sandi?',
      AppLang.en: 'Forgot Password?',
    },
    'login_footer': {
      AppLang.id: '© 2026 AbSis Education Management System',
      AppLang.en: '© 2026 AbSis Education Management System',
    },

    // ---- Schedule screen ----
    'schedule_title': {
      AppLang.id: 'Jadwal Pelajaran',
      AppLang.en: 'Class Schedule',
    },
    'schedule_coming_soon': {
      AppLang.id: 'Belum ada jadwal untuk hari ini',
      AppLang.en: 'No schedule for this day yet',
    },
    'schedule_load_error': {
      AppLang.id: 'Gagal memuat jadwal, coba lagi',
      AppLang.en: 'Failed to load schedule, please try again',
    },
    'retry': {AppLang.id: 'Coba Lagi', AppLang.en: 'Try Again'},
    'no_class_assigned': {
      AppLang.id: 'Kelas Anda belum diatur, hubungi wali kelas',
      AppLang.en:
          'Your class has not been set, please contact your homeroom teacher',
    },
    'break_time': {AppLang.id: 'ISTIRAHAT', AppLang.en: 'BREAK'},
    'day_monday': {AppLang.id: 'Senin', AppLang.en: 'Mon'},
    'day_tuesday': {AppLang.id: 'Selasa', AppLang.en: 'Tue'},
    'day_wednesday': {AppLang.id: 'Rabu', AppLang.en: 'Wed'},
    'day_thursday': {AppLang.id: 'Kamis', AppLang.en: 'Thu'},
    'day_friday': {AppLang.id: 'Jumat', AppLang.en: 'Fri'},
    'day_saturday': {AppLang.id: 'Sabtu', AppLang.en: 'Sat'},

    // ---- Attendance history screen ----
    'attendance_history_title': {
      AppLang.id: 'Riwayat Presensi',
      AppLang.en: 'Attendance History',
    },
    'leave_history_title': {
      AppLang.id: 'Riwayat Izin',
      AppLang.en: 'Leave History',
    },
    'tab_attendance_history': {
      AppLang.id: 'Presensi',
      AppLang.en: 'Attendance',
    },
    'tab_leave_history': {AppLang.id: 'Izin', AppLang.en: 'Leave'},
    'leave_status_pending': {AppLang.id: 'Menunggu', AppLang.en: 'Pending'},
    'leave_status_approved': {AppLang.id: 'Disetujui', AppLang.en: 'Approved'},
    'leave_status_rejected': {AppLang.id: 'Ditolak', AppLang.en: 'Rejected'},
    'no_leave_history': {
      AppLang.id: 'Belum ada riwayat pengajuan izin',
      AppLang.en: 'No leave request history yet',
    },
    'notifications_title': {
      AppLang.id: 'Notifikasi',
      AppLang.en: 'Notifications',
    },
    'notifications_empty_today': {
      AppLang.id: 'Tidak ada jadwal notifikasi untuk hari ini',
      AppLang.en: 'No notifications scheduled for today',
    },
    'notification_status_past': {AppLang.id: 'Sudah Lewat', AppLang.en: 'Past'},
    'notification_status_next': {AppLang.id: 'Berikutnya', AppLang.en: 'Next'},
    'notification_status_upcoming': {
      AppLang.id: 'Akan Datang',
      AppLang.en: 'Upcoming',
    },
    'notification_session_open': {
      AppLang.id: 'Sesi presensi dibuka',
      AppLang.en: 'Attendance window is open',
    },
    'notification_session_closing': {
      AppLang.id: 'Sesi presensi akan ditutup',
      AppLang.en: 'Attendance window closing soon',
    },
    'notifications_derived_note': {
      AppLang.id:
          'Daftar ini dibuat dari sesi presensi hari ini, bukan riwayat asli notifikasi HP.',
      AppLang.en:
          'This list is generated from today\'s attendance sessions, not your phone\'s actual notification log.',
    },
    'no_history_this_month': {
      AppLang.id: 'Belum ada riwayat presensi bulan ini',
      AppLang.en: 'No attendance history for this month yet',
    },
    'status_alpa': {AppLang.id: 'ALPA', AppLang.en: 'ABSENT'},
    'regular_attendance': {
      AppLang.id: 'Absensi Reguler',
      AppLang.en: 'Regular Attendance',
    },

    // ---- Edit profile screen ----
    'edit_profile_title': {
      AppLang.id: 'Edit Profil',
      AppLang.en: 'Edit Profile',
    },
    'edit_profile_notice': {
      AppLang.id:
          'Data ini bisa diubah kapan saja. Nama, NISN, kelas, dan wali kelas dikelola oleh admin sekolah.',
      AppLang.en:
          'This data can be changed anytime. Name, student ID, class, and homeroom teacher are managed by the school admin.',
    },
    'address_hint': {
      AppLang.id: 'Masukkan alamat tempat tinggal',
      AppLang.en: 'Enter your home address',
    },
    'phone_example_hint': {
      AppLang.id: 'Contoh: 081234567890',
      AppLang.en: 'e.g. 081234567890',
    },
    'phone_digits_only': {
      AppLang.id: 'No. HP hanya boleh berisi angka',
      AppLang.en: 'Phone number must contain digits only',
    },
    'phone_too_short': {
      AppLang.id: 'No. HP terlalu pendek',
      AppLang.en: 'Phone number is too short',
    },
    'profile_updated': {
      AppLang.id: 'Profil berhasil diperbarui',
      AppLang.en: 'Profile updated successfully',
    },
    'profile_update_failed': {
      AppLang.id: 'Gagal menyimpan perubahan, coba lagi',
      AppLang.en: 'Failed to save changes, please try again',
    },
    'save_changes': {
      AppLang.id: 'Simpan Perubahan',
      AppLang.en: 'Save Changes',
    },

    // ---- Change password screen ----
    'old_password': {
      AppLang.id: 'Password Lama',
      AppLang.en: 'Current Password',
    },
    'new_password': {AppLang.id: 'Password Baru', AppLang.en: 'New Password'},
    'confirm_new_password': {
      AppLang.id: 'Konfirmasi Password Baru',
      AppLang.en: 'Confirm New Password',
    },
    'old_password_required': {
      AppLang.id: 'Password lama wajib diisi',
      AppLang.en: 'Current password is required',
    },
    'new_password_required': {
      AppLang.id: 'Password baru wajib diisi',
      AppLang.en: 'New password is required',
    },
    'password_min_length': {
      AppLang.id: 'Password minimal 6 karakter',
      AppLang.en: 'Password must be at least 6 characters',
    },
    'password_mismatch': {
      AppLang.id: 'Konfirmasi password tidak cocok',
      AppLang.en: 'Password confirmation does not match',
    },
    'password_changed': {
      AppLang.id: 'Password berhasil diubah',
      AppLang.en: 'Password changed successfully',
    },
    'save_new_password': {
      AppLang.id: 'Simpan Password Baru',
      AppLang.en: 'Save New Password',
    },
    'field_hint_prefix': {AppLang.id: 'Masukkan', AppLang.en: 'Enter'},

    // ---- Confirm photo screen ----
    'attendance_proof_title': {
      AppLang.id: 'Bukti Kehadiran',
      AppLang.en: 'Attendance Proof',
    },
    'scan_success_selfie': {
      AppLang.id: 'Scan Berhasil! Ambil Selfie Untuk Verifikasi.',
      AppLang.en: 'Scan Successful! Take a Selfie to Verify.',
    },
    'take_photo': {AppLang.id: 'Ambil Foto', AppLang.en: 'Take Photo'},
    'photo_taken': {AppLang.id: 'Foto Diambil', AppLang.en: 'Photo Taken'},
    'retake_photo': {AppLang.id: 'Ambil Ulang', AppLang.en: 'Retake'},
    'face_verification_notice': {
      AppLang.id:
          'Pastikan wajah terlihat jelas dan berada di dalam lingkaran untuk memudahkan sistem melakukan verifikasi presensi hari ini.',
      AppLang.en:
          'Make sure your face is clearly visible and inside the circle so the system can verify today\'s attendance.',
    },
    'submit_attendance_failed': {
      AppLang.id: 'Gagal mengirim presensi, coba lagi',
      AppLang.en: 'Failed to submit attendance, please try again',
    },
    'submit_attendance': {
      AppLang.id: 'Kirim Presensi',
      AppLang.en: 'Submit Attendance',
    },

    // ---- Scan QR screen ----
    'scan_qr_title': {AppLang.id: 'Pindai QR Code', AppLang.en: 'Scan QR Code'},
    'invalid_session': {
      AppLang.id: 'Sesi login tidak valid',
      AppLang.en: 'Invalid login session',
    },
    'scan_failed_title': {AppLang.id: 'Gagal', AppLang.en: 'Failed'},
    'try_again': {AppLang.id: 'Coba Lagi', AppLang.en: 'Try Again'},
    'point_camera_qr': {
      AppLang.id: 'Arahkan kamera ke QR Code di sekolah',
      AppLang.en: 'Point the camera at the QR Code at school',
    },
    'validating': {AppLang.id: 'MEMVALIDASI...', AppLang.en: 'VALIDATING...'},
    'searching_code': {
      AppLang.id: 'MENCARI KODE...',
      AppLang.en: 'SEARCHING FOR CODE...',
    },
    'torch': {AppLang.id: 'Senter', AppLang.en: 'Torch'},
    'gallery': {AppLang.id: 'Galeri', AppLang.en: 'Gallery'},

    // ---- Leave request screen ----
    'leave_request_title': {
      AppLang.id: 'Ajukan Izin',
      AppLang.en: 'Request Leave',
    },
    'submission_type': {
      AppLang.id: 'TIPE PENGAJUAN',
      AppLang.en: 'REQUEST TYPE',
    },
    'choose_date': {AppLang.id: 'Pilih Tanggal', AppLang.en: 'Choose Date'},
    'start_date': {AppLang.id: 'Tanggal Mulai', AppLang.en: 'Start Date'},
    'end_date': {AppLang.id: 'Tanggal Selesai', AppLang.en: 'End Date'},
    'reason_notes': {
      AppLang.id: 'Alasan / Catatan',
      AppLang.en: 'Reason / Notes',
    },
    'reason_hint': {
      AppLang.id: 'Tuliskan alasan pengajuan Anda secara detail di sini...',
      AppLang.en: 'Write the detailed reason for your request here...',
    },
    'attachment_label_sakit': {
      AppLang.id: 'Lampiran (Surat Dokter / Pendukung)',
      AppLang.en: 'Attachment (Doctor\'s Note / Supporting Document)',
    },
    'attachment_label_izin': {
      AppLang.id: 'Lampiran (Dokumen Pendukung)',
      AppLang.en: 'Attachment (Supporting Document, Optional)',
    },
    'date_range_required': {
      AppLang.id: 'Tanggal mulai dan selesai wajib diisi',
      AppLang.en: 'Start and end dates are required',
    },
    'reason_required': {
      AppLang.id: 'Alasan wajib diisi',
      AppLang.en: 'Reason is required',
    },
    'leave_request_submitted': {
      AppLang.id: 'Pengajuan berhasil dikirim, menunggu persetujuan wali kelas',
      AppLang.en:
          'Request submitted successfully, awaiting homeroom teacher approval',
    },
    'leave_request_failed': {
      AppLang.id: 'Gagal mengirim pengajuan, coba lagi',
      AppLang.en: 'Failed to submit request, please try again',
    },
    'submit_request': {
      AppLang.id: 'Kirim Pengajuan',
      AppLang.en: 'Submit Request',
    },
    'click_to_upload': {
      AppLang.id: 'Klik untuk Upload File',
      AppLang.en: 'Click to Upload File',
    },
    'file_type_hint': {
      AppLang.id: 'JPG, PNG atau PDF (Maks. 5MB)',
      AppLang.en: 'JPG, PNG or PDF (Max. 5MB)',
    },
    'date_placeholder': {AppLang.id: 'dd/mm/yyyy', AppLang.en: 'mm/dd/yyyy'},

    // ---- Help screen ----
    'help': {AppLang.id: 'Bantuan', AppLang.en: 'Help'},
    'help_title': {AppLang.id: 'Bantuan', AppLang.en: 'Help'},
    'help_faq_section': {
      AppLang.id: 'Pertanyaan Umum',
      AppLang.en: 'Frequently Asked Questions',
    },
    'help_contact_section': {
      AppLang.id: 'Hubungi Kami',
      AppLang.en: 'Contact Us',
    },
    'help_contact_notice': {
      AppLang.id:
          'Kalau pertanyaanmu belum terjawab di atas, hubungi admin sekolah lewat kontak berikut.',
      AppLang.en:
          'If your question isn\'t answered above, contact the school admin below.',
    },
    'help_contact_admin_label': {
      AppLang.id: 'WhatsApp / Telepon',
      AppLang.en: 'WhatsApp / Phone',
    },
    'help_contact_email_label': {
      AppLang.id: 'Email Tata Usaha',
      AppLang.en: 'Administration Email',
    },
    'faq_qr_question': {
      AppLang.id: 'QR gagal dipindai, harus bagaimana?',
      AppLang.en: 'My QR scan failed, what should I do?',
    },
    'faq_qr_answer': {
      AppLang.id:
          'Pastikan kamera mengarah lurus ke layar QR dan coba lagi dalam beberapa detik — kode QR berganti otomatis tiap 10-15 detik. Kalau masih gagal setelah beberapa kali coba, hubungi wali kelas atau admin.',
      AppLang.en:
          'Make sure your camera points straight at the QR screen and try again within a few seconds — the code refreshes every 10-15 seconds. If it still fails after several tries, contact your homeroom teacher or admin.',
    },
    'faq_password_question': {
      AppLang.id: 'Saya lupa password, bagaimana cara reset?',
      AppLang.en: 'I forgot my password, how do I reset it?',
    },
    'faq_password_answer': {
      AppLang.id:
          'Siswa tidak bisa reset password sendiri. Hubungi admin sekolah untuk direset ulang lewat dashboard admin.',
      AppLang.en:
          'Students can\'t reset their own password. Contact the school admin to have it reset via the admin dashboard.',
    },
    'faq_alpa_question': {
      AppLang.id: 'Status presensi saya "Alpa" padahal saya hadir, kenapa?',
      AppLang.en: 'My status shows "Absent" even though I attended, why?',
    },
    'faq_alpa_answer': {
      AppLang.id:
          'Kemungkinan scan kamu terjadi setelah jendela presensi ditutup, atau ada kendala teknis saat itu. Hubungi wali kelas untuk pengecekan dan koreksi data secara manual.',
      AppLang.en:
          'This can happen if you scanned after the attendance window closed, or due to a technical issue. Contact your homeroom teacher to have the record checked and corrected.',
    },

    // ---- About screen ----
    'about_app': {AppLang.id: 'Tentang Aplikasi', AppLang.en: 'About App'},
    'about_app_title': {
      AppLang.id: 'Tentang Aplikasi',
      AppLang.en: 'About App',
    },
    'about_tagline': {
      AppLang.id: 'Sistem Absensi Digital Anti-Titip Absen',
      AppLang.en: 'Anti-Proxy Digital Attendance System',
    },
    'about_version': {AppLang.id: 'Versi', AppLang.en: 'Version'},
    'about_description_title': {
      AppLang.id: 'Tentang AbSis',
      AppLang.en: 'About AbSis',
    },
    'about_description_body': {
      AppLang.id:
          'AbSis adalah sistem absensi digital yang menggantikan absen manual dengan pemindaian QR dan foto bukti kehadiran, untuk mencegah praktik titip absen antar siswa.',
      AppLang.en:
          'AbSis is a digital attendance system that replaces manual attendance with QR scanning and photo proof, to prevent students from clocking in for each other.',
    },
    'about_developer_title': {
      AppLang.id: 'Dikembangkan Oleh',
      AppLang.en: 'Developed By',
    },
    'about_developer_body': {
      AppLang.id:
          'Dikembangkan sebagai proyek Project Based Learning (PjBL) kelas 11 RPL.',
      AppLang.en:
          'Developed as a Project Based Learning (PjBL) assignment for 11th-grade Software Engineering (RPL).',
    },
  };

  static String t(String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[AppLanguage.instance.lang] ?? entry[AppLang.id] ?? key;
  }
}
