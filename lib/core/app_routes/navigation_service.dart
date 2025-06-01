import 'package:flutter/material.dart';

abstract class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Handle pushNamed navigation with arguments
  static Future<void> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  // Handle pushReplacement navigation with arguments
  static Future<void> pushReplacementNamed(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  // Navigate and remove all previous routes with arguments
  static Future<void> pushAndRemoveUntil(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
        routeName, (route) => false,
        arguments: arguments);
  }

  // Pop the current route
  static void pop() {
    return navigatorKey.currentState!.pop();
  }
}
