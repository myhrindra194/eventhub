import 'package:flutter/material.dart';
import '../../features/splash/presentation/views/splash_screen.dart';
import '../../features/onboarding/presentation/views/welcome_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/events/presentation/views/search_screen.dart';
import '../../features/home/presentation/views/main_wrapper_screen.dart';
import '../../features/reservations/presentation/views/mes_billets_screen.dart'; // Corrected file name.
import '../../features/organizer/presentation/views/create_event_screen.dart';
import '../../features/organizer/presentation/views/event_detail_screen.dart';
import '../../features/organizer/presentation/views/event_participants_screen.dart';
import '../../features/organizer/presentation/views/organizer_alerts_screen.dart';
import '../../features/organizer/presentation/views/organizer_events_screen.dart';
import '../../features/organizer/presentation/views/organizer_main_screen.dart';
import '../../features/organizer/presentation/views/organizer_settings_screen.dart';
import '../../features/organizer/presentation/views/organizer_stats_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String homeScreen = '/home_screen';
  static const String search = '/search';
  static const String tickets = '/tickets';
  static const String organizer = '/organizer';
  static const String organizerEvents = '/organizer/events';
  static const String organizerAlerts = '/organizer/alerts';
  static const String organizerStats = '/organizer/stats';
  static const String organizerSettings = '/organizer/settings';
  static const String organizerCreateEvent = '/organizer/events/create';
  static const String organizerEventDetail = '/organizer/events/detail';
  static const String organizerEventParticipants =
      '/organizer/events/participants';

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

      case home:
        return MaterialPageRoute(builder: (_) => const MainWrapperScreen());

      case homeScreen:
        return MaterialPageRoute(builder: (_) => const MainWrapperScreen());

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case tickets:
        return MaterialPageRoute(
          builder: (_) =>
              const MesBilletsScreen(), // Uses the class defined in mes_billets_screen.dart.
        );

      case organizer:
        return MaterialPageRoute(builder: (_) => const OrganizerMainScreen());

      case organizerEvents:
        return MaterialPageRoute(builder: (_) => const OrganizerEventsScreen());

      case organizerAlerts:
        return MaterialPageRoute(builder: (_) => const OrganizerAlertsScreen());

      case organizerStats:
        return MaterialPageRoute(builder: (_) => const OrganizerStatsScreen());

      case organizerSettings:
        return MaterialPageRoute(
          builder: (_) => const OrganizerSettingsScreen(),
        );

      case organizerCreateEvent:
        return MaterialPageRoute(builder: (_) => const CreateEventScreen());

      case organizerEventDetail:
        final arguments = settings.arguments;
        if (arguments is Map<String, String> &&
            arguments['eventId'] != null &&
            arguments['eventTitle'] != null) {
          return MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              eventId: arguments['eventId']!,
              eventTitle: arguments['eventTitle']!,
            ),
          );
        }
        return _notFoundRoute();

      case organizerEventParticipants:
        final arguments = settings.arguments;
        if (arguments is Map<String, String> && arguments['eventId'] != null) {
          return MaterialPageRoute(
            builder: (_) => EventParticipantsScreen(
              eventId: arguments['eventId']!,
            ),
          );
        }
        return _notFoundRoute();

      default:
        return _notFoundRoute();
    }
  }

  static Route<dynamic> _notFoundRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        backgroundColor: Color(0xFF0D0E12),
        body: Center(
          child: Text(
            'Page not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
