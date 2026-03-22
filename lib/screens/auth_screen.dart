import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;
  bool loading = false;
  bool googleLoading = false;
  bool isSignUp = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }

    showAppSnackBar(context, message, isError: isError);
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              AppIconBadge(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _sendVerificationEmail(User user) async {
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
    if (refreshedUser.emailVerified) {
      return false;
    }

    await refreshedUser.sendEmailVerification();
    return true;
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack(
        'Enter your email first so we know where to send the reset link.',
        isError: true,
      );
      return;
    }

    try {
      setState(() => loading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _showStatusDialog(
        title: 'Reset email sent',
        message:
            'If an account exists for $email, Firebase has sent a password reset link. Check Inbox, Spam, and Promotions.',
        icon: Icons.lock_reset_rounded,
        color: AppColors.secondary,
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Failed to send reset email.', isError: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password.');
      return;
    }

    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final usesPasswordAuth =
          refreshedUser?.providerData.any(
            (provider) => provider.providerId == 'password',
          ) ??
          true;

      if (usesPasswordAuth && !(refreshedUser?.emailVerified ?? false)) {
        var resentLink = false;
        try {
          resentLink = await _sendVerificationEmail(cred.user!);
        } on FirebaseAuthException {
          // Even if resend fails, keep the user out until they verify.
        }

        await FirebaseAuth.instance.signOut();
        await _showStatusDialog(
          title: 'Email not verified',
          message: resentLink
              ? 'Please verify $email before signing in. A fresh verification link has been sent.'
              : 'Please verify $email before signing in. If you already signed up recently, use the latest verification email in your inbox.',
          icon: Icons.mark_email_unread_rounded,
          color: AppColors.warning,
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials. Check your email and password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please wait and try again.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      _showSnack(message);
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password.');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }

    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final verificationSent = await _sendVerificationEmail(cred.user!);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'email': email,
            'name': email.split('@').first,
            'ridesCompleted': 0,
            'createdAt': Timestamp.now(),
          });

      await FirebaseAuth.instance.signOut();
      await _showStatusDialog(
        title: 'Account created',
        message: verificationSent
            ? 'A verification link was sent to $email. Verify your email before logging in.'
            : 'Your account was created, but the verification link could not be sent right now. Try logging in again to resend it.',
        icon: Icons.verified_outlined,
        color: verificationSent ? AppColors.secondary : AppColors.warning,
      );

      setState(() {
        isSignUp = false;
      });
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        default:
          message = e.message ?? 'Sign up failed. Please try again.';
      }
      _showSnack(message);
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _ensureGoogleProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? user.email?.split('@').first ?? 'Student',
      'photoUrl': user.photoURL,
      'ridesCompleted': 0,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> signInWithGoogle() async {
    setState(() => googleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            '809697685014-99n9i4i8fcehds7h1uosb59dtchjhcdg.apps.googleusercontent.com',
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() => googleLoading = false);
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (cred.user != null) {
        await _ensureGoogleProfile(cred.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Google sign-in failed.');
    } catch (_) {
      _showSnack('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => googleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      _buildCompactIntro(),
                      const SizedBox(height: 24),
                      _buildAuthCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactIntro() {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text('UniPool', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        const Text(
          'Campus rides, one place.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPill(
            label: 'Welcome back',
            icon: Icons.key_rounded,
            foregroundColor: AppColors.primary,
            backgroundColor: Color(0xFF182543),
          ),
          const SizedBox(height: 18),
          Text(
            isSignUp ? 'Create your account' : 'Sign in to continue',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isSignUp
                ? 'Create an account to start using UniPool.'
                : 'Access your rides and messages.',
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildTabButton('Sign in', !isSignUp),
                _buildTabButton('Create account', isSignUp),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: emailController,
            label: 'College email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          if (!isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _resetPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: isSignUp ? 'Create account' : 'Sign in',
              icon: Icons.arrow_forward_rounded,
              isLoading: loading,
              onPressed: isSignUp ? signUp : login,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: googleLoading ? null : signInWithGoogle,
              icon: googleLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.account_circle_outlined),
              label: Text(
                googleLoading ? 'Connecting...' : 'Continue with Google',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  isSignUp ? 'Already have an account?' : 'New to UniPool?',
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(isSignUp ? 'Sign in' : 'Create account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isSignUp = label == 'Create account'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: active ? AppColors.accentGradient : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      onSubmitted: isPassword ? (_) => isSignUp ? signUp() : login() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.muted,
                ),
              )
            : null,
      ),
    );
  }
}
