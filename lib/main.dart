import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:unipool/screens/auth_screen.dart';
import 'package:unipool/screens/home_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const UnipoolApp());
}

class UnipoolApp extends StatelessWidget {
  const UnipoolApp({super.key});

  bool _canAccessHome(User user) {
    final usesPasswordAuth = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return !usesPasswordAuth || user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniPool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: AppGradientBackground(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconBadge(
                        icon: Icons.local_taxi_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      SizedBox(height: 16),
                      CircularProgressIndicator(color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }

          final user = snapshot.data;
          if (user != null && _canAccessHome(user)) {
            return const HomeScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
