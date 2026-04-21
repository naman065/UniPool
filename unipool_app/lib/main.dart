import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/providers/user_repository_scope.dart';
import 'package:unipool/repositories/ride_repository.dart';
import 'package:unipool/repositories/user_repository.dart';
import 'package:unipool/screens/auth_screen.dart';
import 'package:unipool/screens/home_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(UnipoolApp());
}

class UnipoolApp extends StatelessWidget {
  UnipoolApp({super.key});

  final RideRepository _rideRepository = RideRepository();
  final UserRepository _userRepository = UserRepository();

  bool _canAccessHome(User user) {
    final usesPasswordAuth = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return !usesPasswordAuth || user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return UserRepositoryScope(
      repository: _userRepository,
      child: RideRepositoryScope(
        repository: _rideRepository,
        child: MaterialApp(
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
        ),
      ),
    );
  }
}
