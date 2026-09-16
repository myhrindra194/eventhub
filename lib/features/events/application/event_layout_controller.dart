import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'event_layout_controller.g.dart';

/// Les deux manières de parcourir une collection d'événements.
///
///  * [rows] — des rangées horizontales sur l'accueil, une colonne de grandes
///    cartes sur « Tous les événements ». C'est la lecture « vitrine » : peu
///    d'éléments à la fois, chacun avec sa photo en grand.
///  * [grid] — une grille responsive. C'est la lecture « inventaire » : on
///    balaie beaucoup d'événements d'un coup d'œil, au prix d'une photo plus
///    petite.
///
/// Un seul réglage pour les deux écrans, volontairement : quelqu'un qui
/// préfère la grille la préfère partout, et deux préférences distinctes
/// feraient changer l'écran sous ses yeux en passant de l'accueil au
/// catalogue.
enum EventLayout { rows, grid }

/// Disposition choisie par l'utilisateur, persistée d'un lancement à l'autre.
///
/// Même patron que `ThemeModeController` : une valeur par défaut rendue
/// immédiatement, puis la valeur stockée appliquée dès que la lecture disque
/// aboutit. `keepAlive`, parce que l'accueil et le catalogue la lisent tour à
/// tour : un provider auto-disposé relirait le disque à chaque navigation et
/// ferait clignoter la disposition par défaut entre deux écrans.
@Riverpod(keepAlive: true)
class EventLayoutController extends _$EventLayoutController {
  /// Clé versionnée : si l'énumération change un jour de sens, on incrémente
  /// le suffixe plutôt que de réinterpréter une ancienne valeur.
  static const storageKey = 'event_layout_v1';

  /// Vrai dès que l'utilisateur a choisi pendant cette session. Sans ce
  /// drapeau, une lecture disque lente pourrait arriver *après* un appui sur
  /// le sélecteur et écraser le choix qu'il vient de faire par l'ancien.
  bool _chosen = false;

  @override
  EventLayout build() {
    // Les rangées par défaut : c'est la lecture éditoriale de l'accueil, et
    // celle que proposent Airbnb et Eventbrite au premier lancement. La
    // grille est un choix d'utilisateur averti, pas un point de départ.
    Future.microtask(_restore);
    return EventLayout.rows;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(storageKey);
    final restored = EventLayout.values.asNameMap()[stored];
    if (_chosen || restored == null || restored == state) return;
    state = restored;
  }

  Future<void> set(EventLayout layout) async {
    _chosen = true;
    if (layout == state) return;
    state = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, layout.name);
  }
}
