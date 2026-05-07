import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final String status;

  const LoadingOverlay({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.3)),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    strokeWidth: 4,
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              status,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Our AI is stitching your style together...",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
