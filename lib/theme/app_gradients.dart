import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primary,
      Color(0xFFA066FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}