import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {

  /// 🔥 PREMIUM GOLD GRADIENT
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primary,
      Color(0xFFE0C48F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}