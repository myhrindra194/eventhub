import 'package:flutter/material.dart';
import '../../features/splash/presentation/views/splash_screen.dart';
import '../../features/onboarding/presentation/views/welcome_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/home/presentation/views/main_wrapper_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String homeScreen = '/home_screen';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case welcome:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const MainWrapperScreen(),
        );

      case homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            backgroundColor: Color(0xFF0D0E12),
            body: Center(
              child: Text(
                'Page non trouvée',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
    }
  }
}