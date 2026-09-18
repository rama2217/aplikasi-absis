import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../languages/app_language.dart';
import '../languages/strings.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialAddress;
  final String? initialPhoneNumber;
  final String? initialAvatarUrl;

  const EditProfileScreen({
    super.key,
    this.initialAddress,
    this.initialPhoneNumber,
    this.initialAvatarUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const primaryColor = Color(0xFF0039A8);
  static const bgColor = Color(0xFFF9F9FF);
  static const onSurface = Color(0xFF151C27);
  static const onSurfaceVariant = Color(0xFF434654);

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _client = Supabase.instance.client;

  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  String? _avatarUrl;
  bool _isUploadingPhoto = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _phoneController = TextEditingController(text: widget.initialPhoneNumber ?? '');
    _avatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final studentId = _authService.currentUser!.id;
      final fileBytes = await picked.readAsBytes();
      final fileExt = picked.name.split('.').last;
      final filePath = '$studentId/avatar.$fileExt';

      await _client.storage.from('avatars').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final signedUrl =
          await _client.storage.from('avatars').createSignedUrl(filePath, 60 * 60 * 24 * 365);

      await _client.from('students').update({'avatar_url': signedUrl}).eq('id', studentId);

      if (mounted) {
        setState(() {
          _avatarUrl = signedUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('photo_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('photo_upload_failed'))),
        );
      }
    }
  }

  Future<void> _confirmAndRemovePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Strings.t('remove_photo_confirm_title')),
        content: Text(Strings.t('remove_photo_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Strings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Strings.t('remove'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final studentId = _authService.currentUser!.id;

      // Hapus URL di database dulu supaya UI langsung update.
      await _client.from('students').update({'avatar_url': null}).eq('id', studentId);

      // Coba hapus file fisik di storage (best-effort; abaikan jika tidak ada).
      try {
        final files = await _client.storage.from('avatars').list(path: studentId);
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$studentId/${f.name}').toList();
          await _client.storage.from('avatars').remove(paths);
        }
      } catch (_) {
        // Tidak fatal — data di kolom avatar_url sudah bersih.
      }

      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('photo_removed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('photo_remove_failed'))),
        );
      }
    }
  }

  // Pola bottom sheet + key string ini disamakan persis dengan yang sudah
  // ada (dipakai fitur foto Profil Siswa yang lama): Ambil Foto / Pilih
  // dari Galeri / Hapus Foto (kalau ada) / Batal.
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: primaryColor),
              title: Text(Strings.t('take_photo_option')),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: primaryColor),
              title: Text(Strings.t('choose_from_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    Text(Strings.t('remove_photo_option'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAndRemovePhoto();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: Text(Strings.t('cancel')),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _authService.updateStudentProfile(
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('profile_updated'))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = Strings.t('profile_update_failed');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            _buildTopBar(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Center(child: _buildAvatarPicker()),
                    const SizedBox(height: 24),

                    Text(
                      Strings.t('edit_profile_notice'),
                      style: const TextStyle(color: onSurfaceVariant, fontSize: 13),
                    ),
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
                          Text(Strings.t('address').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: onSurfaceVariant,
                                  letterSpacing: 0.6)),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            style: const TextStyle(color: onSurface),
                            decoration: _fieldDecoration(Strings.t('address_hint')),
                          ),
                          const SizedBox(height: 20),

                          Text(Strings.t('phone').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: onSurfaceVariant,
                                  letterSpacing: 0.6)),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: onSurface),
                            decoration: _fieldDecoration(Strings.t('phone_example_hint')),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final digitsOnly = RegExp(r'^[0-9]+$');
                              if (!digitsOnly.hasMatch(value.trim())) {
                                return Strings.t('phone_digits_only');
                              }
                              if (value.trim().length < 9) {
                                return Strings.t('phone_too_short');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(Strings.t('save_changes'),
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: bgColor,
          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
          child: _isUploadingPhoto
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                )
              : (_avatarUrl == null
                  ? const Icon(Icons.person, size: 48, color: Colors.grey)
                  : null),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _showPhotoOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Top bar konsisten dengan gaya kartu putih + shadow tipis yang dipakai
  // di layar lain (mis. Ajukan Izin), bukan default Material AppBar.
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: onSurface),
          ),
          Expanded(
            child: Text(
              Strings.t('edit_profile_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
            ),
          ),
          const SizedBox(width: 48), // seimbangkan lebar tombol back di kiri
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: bgColor,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}