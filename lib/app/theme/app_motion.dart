import 'package:flutter/animation.dart';

/// Tokens de mouvement.
///
/// Un seul vocabulaire de durées et de courbes pour tout le produit, afin
/// qu’un chip, une transition de page et une bottom sheet donnent le
/// sentiment d’appartenir à la même mécanique. Les valeurs suivent le jeu
/// d’easing « expressive » de Material 3.
///
/// Règle générale :
///  * [instant] / [xshort] — retour d’état (appui, survol, ripple)
///  * [short]              — entrée/sortie d’un petit élément (chip, badge)
///  * [medium]             — transitions de page, cartes qui se déplient
///  * [long] / [xlong]     — mouvement plein écran ou célébratoire
abstract final class AppMotion {
  static const instant = Duration(milliseconds: 80);
  static const xshort = Duration(milliseconds: 120);
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 340);
  static const long = Duration(milliseconds: 480);
  static const xlong = Duration(milliseconds: 720);

  /// Courbe par défaut, « arrive avec autorité, se pose en douceur ».
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Entrée à l’écran — aucune vitesse initiale, décélère jusqu’à sa place.
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Sortie de l’écran — prend de la vitesse et s’en va.
  static const accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Symétrique, pour les valeurs qui font l’aller-retour (toggles, sliders).
  static const standard = Cubic(0.4, 0, 0.2, 1);

  /// Un soupçon d’overshoot, réservé aux seuls éléments festifs ou ludiques.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
}
