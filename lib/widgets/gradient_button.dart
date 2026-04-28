import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientButton extends StatelessWidget {

  final String title;
  final VoidCallback onTap;

  const GradientButton({
    super.key,
    required this.title,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(
        height: 55,

        decoration: BoxDecoration(

          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary
            ],
          ),

          borderRadius: BorderRadius.circular(30),

          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.4),
              blurRadius: 15,
              offset: const Offset(0,6),
            )
          ],
        ),

        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}