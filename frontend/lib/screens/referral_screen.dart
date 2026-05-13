import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_in_slide.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

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
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              final code = user?.referralCode ?? '------';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Header icon
                    FadeInSlide(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C5CFF).withOpacity(0.2),
                              const Color(0xFF5CA4FF).withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF7C5CFF).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFF7C5CFF),
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    const FadeInSlide(
                      delay: Duration(milliseconds: 100),
                      child: Text(
                        "Refer & Earn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 150),
                      child: Text(
                        "Invite friends and you both earn 5 free credits!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Referral Code Card
                    FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C5CFF).withOpacity(0.12),
                              const Color(0xFF5CA4FF).withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF7C5CFF).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "YOUR REFERRAL CODE",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Code display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      code,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: code));
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Code copied to clipboard!'),
                                          backgroundColor:
                                              const Color(0xFF7C5CFF),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C5CFF)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        color: Color(0xFF7C5CFF),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Share button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(
                                    '🔥 Try AuraFit - Virtual Try-On!\n\n'
                                    'Use my referral code: $code\n'
                                    'We both get 5 free credits!\n\n'
                                    'Download now and look amazing! ✨',
                                  );
                                },
                                icon: const Icon(Icons.share_rounded,
                                    size: 20),
                                label: const Text(
                                  "Share with Friends",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C5CFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // How it works
                    FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          Text(
                            "HOW IT WORKS",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStep(
                            "1",
                            "Share Your Code",
                            "Send your unique code to friends via any app.",
                            Icons.send_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildStep(
                            "2",
                            "Friend Signs Up",
                            "They enter your code when creating an account.",
                            Icons.person_add_alt_1_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildStep(
                            "3",
                            "Both Earn Credits",
                            "You and your friend each get 5 free credits!",
                            Icons.celebration_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
      String number, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF7C5CFF), size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
