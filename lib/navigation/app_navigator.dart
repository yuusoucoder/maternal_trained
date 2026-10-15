import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The three primary tabs.
enum ShellTab { home, patients, profile }

/// AIOVY motion system.
///
/// * [slide] – hierarchical push (list → detail, result → explanation):
///   the new page slides in from the right, the previous one shifts left
///   slightly; back reverses it and supports the edge swipe-back gesture.
/// * [fade] – a context change rather than a drill-down (splash → sign-in,
///   sign-in → app, assessment → processing). Optional small upward [rise]
///   for "revealing" a result.
class AppMotion {
  AppMotion._();

  static const Duration push = Duration(milliseconds: 300);
  static const Duration fade = Duration(milliseconds: 260);
  static const Duration tab = Duration(milliseconds: 160);
}

/// iOS-style horizontal push at AIOVY's shorter duration. Respects
/// [PopScope] – the swipe-back gesture is disabled while a screen blocks
/// popping (e.g. unsaved assessment values).
class AiovySlideRoute<T> extends CupertinoPageRoute<T> {
  AiovySlideRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => AppMotion.push;
}

/// Subtle cross-fade (optionally rising 12 px) with no zoom.
class AiovyFadeRoute<T> extends PageRouteBuilder<T> {
  AiovyFadeRoute({required Widget page, bool rise = false, super.settings})
      : super(
          transitionDuration: AppMotion.fade,
          reverseTransitionDuration: AppMotion.fade,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            Widget out = FadeTransition(opacity: curved, child: child);
            if (rise) {
              out = AnimatedBuilder(
                animation: curved,
                builder: (_, c) => Transform.translate(offset: Offset(0, 12 * (1 - curved.value)), child: c),
                child: out,
              );
            }
            return out;
          },
        );
}

/// Central navigation helpers so screens don't duplicate route logic.
class AppNavigator {
  AppNavigator._();

  /// Used for snackbars that must survive a route change
  /// (e.g. "Assessment saved" after popping back to Home).
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Currently selected bottom-navigation tab.
  static final ValueNotifier<ShellTab> currentTab = ValueNotifier<ShellTab>(ShellTab.home);

  /// Default (hierarchical) route.
  static Route<T> route<T>(Widget page) => AiovySlideRoute<T>(builder: (_) => page);

  static Route<T> fadeRoute<T>(Widget page, {bool rise = false}) => AiovyFadeRoute<T>(page: page, rise: rise);

  static Future<T?> push<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(route<T>(page));

  static Future<T?> pushFade<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(fadeRoute<T>(page));

  /// Replaces the current screen with a fade (non-hierarchical change).
  static Future<T?> replace<T>(BuildContext context, Widget page, {bool rise = false}) =>
      Navigator.of(context).pushReplacement<T, Object?>(fadeRoute<T>(page, rise: rise));

  /// Clears the whole stack (used for login → shell and sign-out).
  static Future<T?> resetTo<T>(BuildContext context, Widget page) =>
      Navigator.of(context).pushAndRemoveUntil<T>(fadeRoute<T>(page), (_) => false);

  /// Pops back to the main shell (first route after login).
  static void popToShell(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

  /// Switches tab and returns to the shell from anywhere.
  static void openTab(BuildContext context, ShellTab tab) {
    currentTab.value = tab;
    popToShell(context);
  }

  static void showSnack(String message, {IconData icon = Icons.check_circle_rounded}) {
    final m = messengerKey.currentState;
    if (m == null) return;
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ));
  }
}
