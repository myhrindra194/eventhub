import 'package:flutter/material.dart';
import '../../features/splash/presentation/views/splash_screen.dart';
import '../../features/onboarding/presentation/views/welcome_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/events/presentation/views/search_screen.dart';
import '../../features/events/presentation/views/event_detail_screen.dart';
import '../../features/events/domain/entities/event.dart';
import '../../features/home/presentation/views/main_wrapper_screen.dart';
import '../../features/reservations/presentation/views/confirmation_reservation_screen.dart';
import '../../features/reservations/presentation/views/mes_billets_screen.dart'; // Corrected file name.
import '../../features/organizer/presentation/views/create_event_screen.dart';
import '../../features/organizer/presentation/views/event_detail_screen.dart'
    as organizer_views;
import '../../features/organizer/presentation/views/event_participants_screen.dart';
import '../../features/organizer/presentation/views/event_published_screen.dart';
import '../../features/organizer/presentation/views/organizer_alerts_screen.dart';
import '../../features/organizer/presentation/views/organizer_events_screen.dart';
import '../../features/organizer/presentation/views/organizer_settings_screen.dart';
import '../../features/organizer/presentation/views/organizer_stats_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String search = '/search';
  static const String tickets = '/tickets';
  static const String eventDetail = '/event-detail';
  static const String reservationConfirmation = '/reservation-confirmation';
  static const String organizer = '/organizer';
  static const String organizerEvents = '/organizer/events';
  static const String organizerAlerts = '/organizer/alerts';
  static const String organizerStats = '/organizer/stats';
  static const String organizerSettings = '/organizer/settings';
  static const String organizerCreateEvent = '/organizer/events/create';
  static const String organizerEventDetail = '/organizer/events/detail';
  static const String organizerEventParticipants =
      '/organizer/events/participants';
  static const String organizerEventPublished = '/organizer/events/published';

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
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.participant,
            forbiddenRedirectRoute: organizer,
            child: MainWrapperScreen(),
          ),
        );

      case search:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.participant,
            forbiddenRedirectRoute: organizer,
            child: SearchScreen(),
          ),
        );

      case eventDetail:
        final eventId = settings.arguments;
        if (eventId is! String) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.participant,
            forbiddenRedirectRoute: organizer,
            child: EventDetailScreen(eventId: eventId),
          ),
        );

      case reservationConfirmation:
        final event = settings.arguments;
        if (event is! Event) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.participant,
            forbiddenRedirectRoute: organizer,
            child: ConfirmationReservationScreen(event: event),
          ),
        );

      case tickets:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.participant,
            forbiddenRedirectRoute: organizer,
            child: MesBilletsScreen(),
          ),
        );

      case organizer:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            redirectRoute: welcome,
            requiredRole: UserRole.organizer,
            child: OrganizerEventsScreen(),
          ),
        );

      case organizerAlerts:
        return _organizerRoute(const OrganizerAlertsScreen());

      case organizerStats:
        return _organizerRoute(const OrganizerStatsScreen());

      case organizerSettings:
        return _organizerRoute(const OrganizerSettingsScreen());

      case organizerCreateEvent:
        return _organizerRoute(const CreateEventScreen());

      case organizerEventDetail:
        final arguments = settings.arguments;
        if (arguments is Map<String, String> &&
            arguments['eventId'] != null &&
            arguments['eventTitle'] != null) {
          return _organizerRoute(
            organizer_views.EventDetailScreen(
              eventId: arguments['eventId']!,
              eventTitle: arguments['eventTitle']!,
            ),
          );
        }
        return _notFoundRoute();

      case organizerEventParticipants:
        final arguments = settings.arguments;
        if (arguments is Map<String, String> && arguments['eventId'] != null) {
          return _organizerRoute(
            EventParticipantsScreen(eventId: arguments['eventId']!),
          );
        }
        return _notFoundRoute();

      case organizerEventPublished:
        final arguments = settings.arguments;
        if (arguments is Map<String, String> &&
            arguments['eventTitle'] != null &&
            arguments['publicUrl'] != null) {
          return _organizerRoute(
            EventPublishedScreen(
              eventTitle: arguments['eventTitle']!,
              publicUrl: arguments['publicUrl']!,
            ),
          );
        }
        return _notFoundRoute();

      default:
        return _notFoundRoute();
    }
  }

  static Route<dynamic> _organizerRoute(Widget child) {
    return MaterialPageRoute(
      builder: (_) => AuthGuard(
        redirectRoute: welcome,
        requiredRole: UserRole.organizer,
        forbiddenRedirectRoute: home,
        child: child,
      ),
    );
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
