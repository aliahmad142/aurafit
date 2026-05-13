import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../screens/pricing_screen.dart';
import '../screens/referral_screen.dart';
import '../widgets/fade_in_slide.dart';

/// Premium bottom sheet shown when the user has 0 credits and tries to generate.
class OutOfCreditsSheet extends StatelessWidget {
  const OutOfCreditsSheet({super.key});

  static void show(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OutOfCreditsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1429),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
          left: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
          right: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 28),

            // Animated icon
            FadeInSlide(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(0.15),
                      Colors.orangeAccent.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: const Text(
                "You're Out of Credits!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            FadeInSlide(
              delay: const Duration(milliseconds: 200),
              child: Text(
                "Upgrade your plan or invite friends to keep\ntrying on amazing outfits.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Upgrade Plan Button
            FadeInSlide(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PricingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.diamond_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Upgrade Plan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Refer & Earn Button
            FadeInSlide(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReferralScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text(
                        "Refer & Earn 5 Credits",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
