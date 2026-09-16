import 'package:flutter/foundation.dart';

/// [Listenable] minimal utilisé comme `refreshListenable` de GoRouter.
///
/// Le router est créé une seule fois puis maintenu en vie ; dès qu’une valeur
/// dont dépend le guard change (session, drapeau d’onboarding), on notifie au
/// lieu de reconstruire le router — le reconstruire réinitialiserait les
/// piles de navigation.
class RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
