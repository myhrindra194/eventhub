import 'package:flutter/material.dart';
import '../../features/splash/presentation/views/splash_screen.dart';
import '../../features/onboarding/presentation/views/welcome_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/auth/presentation/views/forgot_password_screen.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/events/presentation/views/search_screen.dart';
import '../../features/events/presentation/views/event_detail_screen.dart';
import '../../features/events/domain/entities/event.dart';
import '../../features/home/presentation/views/main_wrapper_screen.dart';
import '../../features/reservations/presentation/views/confirmation_reservation_screen.dart';
import '../../features/reservations/presentation/views/mes_billets_screen.dart'; // Corrected file name.

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String tickets = '/tickets';
  static const String eventDetail = '/event-detail';
  static const String reservationConfirmation = '/reservation-confirmation';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case home:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            child: MainWrapperScreen(),
          ),
        );

      case search:
        return MaterialPageRoute(
          builder: (_) =>
              const AuthGuard(redirectRoute: welcome, child: SearchScreen()),
        );

      case eventDetail:
        final eventId = settings.arguments;
        if (eventId is! String) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            redirectRoute: welcome,
            child: EventDetailScreen(eventId: eventId),
          ),
        );

      case reservationConfirmation:
        final event = settings.arguments;
        if (event is! Event) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            redirectRoute: welcome,
            child: ConfirmationReservationScreen(event: event),
          ),
        );

      case tickets:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            child: MesBilletsScreen(),
          ),
        );

      default:
        return _notFoundRoute();
    }
  }

  static Route<dynamic> _notFoundRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        backgroundColor: Color(0xFF0D0E12),
        body: Center(
          child: Text('Page not found', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
