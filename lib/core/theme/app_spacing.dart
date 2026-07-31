import 'package:flutter/widgets.dart';

/// 4pt spacing scale + shared radii used across the app for a consistent,
/// airy premium layout.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Page horizontal padding
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}
