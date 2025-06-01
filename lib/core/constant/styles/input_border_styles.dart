import 'package:flutter/material.dart';

abstract class InputBorders {
  /// Generates a customizable OutlineInputBorder
  static OutlineInputBorder custom({
    required Color color,
    double width = 1.0,
    double borderRadius = 4.0,
  }) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: width),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}
