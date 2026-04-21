import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  bool _isUploading = false;
  bool _isSaving = false;
  bool _isInitialLoad = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  String? _imageUrl;
  int _ridesCompleted = 0;
  double _avgRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser!;
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((userData) {
      if (!mounted) return;
      final data = userData.data();
      if (data == null) return;

      setState(() {
        if (_isInitialLoad) {
          _nameController.text = (data['name'] as String?) ?? '';
          _isInitialLoad = false;
        }
        _imageUrl = data['photoUrl'] as String?;
        _ridesCompleted = (data['ridesCompleted'] as num?)?.toInt() ?? 0;
        _avgRating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
        _totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;
      });
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(pickedFile.path));
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _imageUrl = url);
        showAppSnackBar(context, 'Profile photo updated.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not upload image: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        showAppSnackBar(context, 'Profile updated.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not save profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _nameController.text.trim().isEmpty
        ? user?.email?.split('@').first ?? 'Student'
        : _nameController.text.trim();

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Profile',
                subtitle: 'Update your name and photo.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
                bottom: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 3,
                              ),
                              image: _imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: _imageUrl == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 38,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSurfaceCard(
                        child: Row(
                          children: [
                            const AppIconBadge(
                              icon: Icons.star_rate_rounded,
                              color: AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overall rating',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _totalRatings > 0 ? _avgRating.toStringAsFixed(1) : 'No ratings',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontSize: _totalRatings > 0 ? 28 : 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_totalRatings > 0)
                              AppPill(
                                label: '$_totalRatings review${_totalRatings == 1 ? '' : 's'}',
                                foregroundColor: AppColors.warning,
                                backgroundColor: AppColors.warning.withOpacity(0.12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppSurfaceCard(
                        child: Row(
                          children: [
                            const AppIconBadge(
                              icon: Icons.verified_rounded,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rides completed',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_ridesCompleted',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const AppPill(
                              label: 'Trusted rider',
                              foregroundColor: AppColors.secondary,
                              backgroundColor: Color(0xFF153636),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(
                              title: 'Profile details',
                              subtitle:
                                  'These details are visible on your rides.',
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user?.email ?? '',
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          label: 'Save changes',
                          icon: Icons.save_rounded,
                          isLoading: _isSaving,
                          onPressed: _saveProfile,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBackButton extends StatelessWidget {
  const _TopBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
