import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _emailController = TextEditingController();
  bool _isResettingPassword = false;
  bool _isLoggingOut = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await pickedFile.readAsBytes();
      print('DEBUG: Image bytes read. Size: ${bytes.length}');
      
      // Add timeout of 30 seconds
      print('DEBUG: Calling uploadProfileImage...');
      await ref.read(authControllerProvider).uploadProfileImage(bytes).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('DEBUG: Upload timed out.');
          throw Exception('Upload timed out. Please check your internet connection.');
        },
      );
      print('DEBUG: Upload completed successfully.');

      if (mounted) {
        final tr = ref.read(translationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.profilePhotoUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final user = ref.read(currentUserProvider);
    if (user?.email == null) return;

    setState(() => _isResettingPassword = true);

    try {
      await ref.read(authControllerProvider).sendPasswordResetEmail(user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoggingOut = true);
      try {
        await ref.read(authControllerProvider).signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoggingOut = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final tr = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: userProfileAsync.when(
                    data: (userProfile) => Column(
                      children: [
                        // Avatar avec option de changement
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _isUploadingImage
                                  ? const CircleAvatar(
                                      radius: 50,
                                      child: CircularProgressIndicator(color: Colors.white),
                                    )
                                  : userProfile?.photoUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: userProfile!.photoUrl!,
                                          imageBuilder: (context, imageProvider) => CircleAvatar(
                                            radius: 50,
                                            backgroundImage: imageProvider,
                                          ),
                                          placeholder: (context, url) => const CircleAvatar(
                                            radius: 50,
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) => CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                            child: Text(
                                              userProfile.firstName.isNotEmpty
                                                  ? userProfile.firstName[0].toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          child: Text(
                                            userProfile?.firstName.isNotEmpty == true
                                                ? userProfile!.firstName[0].toUpperCase()
                                                : user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Nom complet
                        Text(
                          userProfile?.fullName.isNotEmpty == true
                              ? userProfile!.fullName
                              : user?.email ?? 'Utilisateur',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                tr.activeMember,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, __) => Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user?.email ?? 'Utilisateur',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: userProfileAsync.when(
                      data: (userProfile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tr.accountInfo,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.person,
                            label: tr.firstName,
                            value: userProfile?.firstName ?? tr.notSpecified,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: tr.lastName,
                            value: userProfile?.lastName ?? tr.notSpecified,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: tr.email,
                            value: user?.email ?? tr.notAvailable,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.fingerprint,
                            label: tr.userId,
                            value: user?.uid.substring(0, 12) ?? tr.notAvailable,
                            trailing: '...',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.verified_user_outlined,
                            label: tr.emailVerified,
                            value: user?.emailVerified == true ? tr.yes : tr.no,
                            valueColor: user?.emailVerified == true ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.access_time,
                            label: tr.lastSignIn,
                            value: user?.metadata.lastSignInTime != null
                                ? _formatDate(user!.metadata.lastSignInTime!)
                                : tr.notAvailable,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: tr.accountCreated,
                            value: user?.metadata.creationTime != null
                                ? _formatDate(user!.metadata.creationTime!)
                                : tr.notAvailable,
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(tr.errorOccurred),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tr.security,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lock_reset, color: Colors.orange),
                          ),
                          title: Text(tr.resetPassword),
                          subtitle: Text(tr.resetPasswordDesc),
                          trailing: _isResettingPassword
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isResettingPassword ? null : _resetPassword,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tr.aboutApp,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.apps,
                          label: tr.version,
                          value: '1.0.0',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.code,
                          label: tr.platform,
                          value: 'Flutter Web',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.auto_awesome,
                          label: tr.aiPowered,
                          value: 'Groq (Llama 3.3)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout),
                    label: Text(_isLoggingOut ? tr.loading : tr.signOut),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailing;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}

