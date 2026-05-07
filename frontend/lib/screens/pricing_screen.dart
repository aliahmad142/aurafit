import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_in_slide.dart';
import 'checkout_webview.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const FadeInSlide(
                  child: Text(
                    "Choose Your Plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    "Unlock more try-ons with our premium passes",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                  ),
                ),
                const SizedBox(height: 40),
                _buildPlanCard(
                  context,
                  title: "Free Tier",
                  price: "0.00",
                  description: "Perfect for testing",
                  features: ["5 Try-ons per month", "Standard Speed", "Community Support"],
                  isCurrent: true,
                  isPopular: false,
                ),
                const SizedBox(height: 24),
                _buildPlanCard(
                  context,
                  title: "Daily Pass",
                  price: "3.79",
                  description: "Best for shopping days",
                  features: ["10 Try-ons for 24 hours", "Priority Processing", "HD Quality Support"],
                  isCurrent: false,
                  isPopular: true,
                  onTap: () => _showPaymentOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required List<String> features,
    bool isCurrent = false,
    bool isPopular = false,
    VoidCallback? onTap,
  }) {
    return FadeInSlide(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPopular ? const Color(0xFF7C5CFF).withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isPopular ? const Color(0xFF7C5CFF).withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("POPULAR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("\$", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                Text(
                  isPopular ? "/day" : "/mo",
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Colors.white10),
            ),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF7C5CFF), size: 18),
                      const SizedBox(width: 12),
                      Text(f, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isCurrent ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? const Color(0xFF7C5CFF) : Colors.white10,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  isCurrent ? "Current Plan" : "Get Started",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Payment Method",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _paymentMethodTile(context, "PayFast Pakistan", "JazzCash, EasyPaisa, Cards", Icons.payment_rounded, true),
              const SizedBox(height: 12),
              _paymentMethodTile(context, "JazzCash Mobile Account", "Direct from your mobile", Icons.account_balance_wallet_rounded, false),
              const SizedBox(height: 12),
              _paymentMethodTile(context, "EasyPaisa Wallet", "Fast & Secure", Icons.wallet_rounded, false),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile(BuildContext context, String name, String subtitle, IconData icon, bool isPayFast) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PayFastCheckoutScreen(plan: "DAILY_PASS"),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF7C5CFF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
