import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/animated_background.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'pricing_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'referral_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  void _showUpdateNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B2E),
        title: const Text("Update Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new name",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  await _authService.updateProfile(name);
                  if (context.mounted) {
                    Provider.of<AuthProvider>(context, listen: false).refreshUser();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B2E),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Current Password", hintStyle: TextStyle(color: Colors.white38)),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "New Password", hintStyle: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (currentCtrl.text.isNotEmpty && newCtrl.text.isNotEmpty) {
                try {
                  await _authService.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF7C5CFF)),
            SizedBox(width: 12),
            Text("Help Center", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Frequently Asked Questions", style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 16),
            _HelpItem(question: "How does virtual try-on work?", answer: "Upload a photo of yourself and a garment image. Our AI will generate a realistic preview of you wearing the outfit."),
            SizedBox(height: 12),
            _HelpItem(question: "Are my images stored?", answer: "Your images are encrypted and stored locally on your device. They are never sent to external servers for storage."),
            SizedBox(height: 12),
            _HelpItem(question: "How do I get more credits?", answer: "You can purchase a Daily Pass from the Pricing screen to get additional try-on credits."),
            SizedBox(height: 20),
            Divider(color: Colors.white10),
            SizedBox(height: 12),
            Text("Need more help?", style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 4),
            Text("Contact us at chromatoon007@gmail.com", style: TextStyle(color: Color(0xFF7C5CFF), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Color(0xFF7C5CFF)),
            SizedBox(width: 12),
            Text("Privacy Policy", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Last updated: May 2026", style: TextStyle(color: Colors.white38, fontSize: 12)),
              SizedBox(height: 16),
              _PolicySection(
                title: "1. What We Collect",
                body: "When you sign up, we collect your name and email address. Your password is securely stored and never visible to anyone.",
              ),
              _PolicySection(
                title: "2. How We Use Your Photos",
                body: "Your photos are only used to generate the try-on result. We send them to a secure AI service for processing, and they are immediately discarded after. We do not store your photos on our servers.",
              ),
              _PolicySection(
                title: "3. Where Your Data is Stored",
                body: "Your try-on history and favorites are saved only on your phone, not on any cloud or server. All saved images are encrypted so they stay private.",
              ),
              _PolicySection(
                title: "4. Who Can See Your Data",
                body: "We do not sell, share, or give your personal information to anyone. The only exception is the AI service that processes your try-on photos, and they do not keep your images.",
              ),
              _PolicySection(
                title: "5. Deleting Your Data",
                body: "You can delete your account and all your data at any time from Settings. You can also clear your local history and favorites separately.",
              ),
              _PolicySection(
                title: "6. Contact Us",
                body: "If you have any questions, reach out to us at chromatoon007@gmail.com.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all your local try-on history and favorites. Your account will not be affected.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HistoryProvider>(context, listen: false).clearAll();
              Provider.of<FavoritesProvider>(context, listen: false).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local data cleared'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(child: SizedBox.expand()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildSectionTitle("ACCOUNT"),
                _buildSettingsCard([
                  _settingsTile(
                    icon: Icons.person_outline_rounded,
                    title: "Profile Information",
                    subtitle: user?.name ?? "User",
                    onTap: () => _showUpdateNameDialog(context, user?.name ?? ""),
                  ),
                  _settingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: "Security",
                    subtitle: "Change Password",
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _settingsTile(
                    icon: Icons.email_outlined,
                    title: "Email",
                    subtitle: user?.email ?? "Not provided",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text("Verified", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _settingsTile(
                    icon: Icons.workspace_premium_rounded,
                    title: "Subscription",
                    subtitle: user?.planType == 'FREE' ? "Free Tier" : "Daily Pass",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())),
                  ),
                  _settingsTile(
                    icon: Icons.card_giftcard_rounded,
                    title: "Refer & Earn",
                    subtitle: "Invite friends, earn 5 credits",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle("PREFERENCES"),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return _buildSettingsCard([
                      _settingsSwitch(
                        icon: Icons.notifications_none_rounded,
                        title: "Push Notifications",
                        value: settings.pushNotifications,
                        onChanged: (v) => settings.setPushNotifications(v),
                      ),
                      _settingsSwitch(
                        icon: Icons.high_quality_rounded,
                        title: "HD Rendering",
                        value: settings.hdRendering,
                        onChanged: (v) => settings.setHdRendering(v),
                      ),
                      _settingsSwitch(
                        icon: Icons.save_alt_rounded,
                        title: "Auto-save to Gallery",
                        value: settings.autoSaveToGallery,
                        onChanged: (v) => settings.setAutoSaveToGallery(v),
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle("DATA"),
                _buildSettingsCard([
                  _settingsTile(
                    icon: Icons.favorite_rounded,
                    title: "My Favorites",
                    subtitle: "View saved styles",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  ),
                  _settingsTile(
                    icon: Icons.history_rounded,
                    title: "Try-On History",
                    subtitle: "View past results",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                  _settingsTile(
                    icon: Icons.delete_sweep_rounded,
                    title: "Clear All Data",
                    subtitle: "Remove history & favorites",
                    titleColor: Colors.redAccent,
                    onTap: () => _showClearDataDialog(context),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle("SUPPORT & LEGAL"),
                _buildSettingsCard([
                  _settingsTile(
                    icon: Icons.help_outline_rounded,
                    title: "Help Center",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => _showHelpCenterDialog(context),
                  ),
                  _settingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                  _settingsTile(
                    icon: Icons.info_outline_rounded,
                    title: "App Version",
                    subtitle: "1.0.0 (Build 24)",
                  ),
                ]),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Sign Out"),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF161B2E),
                              title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent)),
                              content: const Text("Are you sure? This will delete all your history and favorites. This action cannot be undone.", style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      // Clear all local data first
                                      Provider.of<HistoryProvider>(context, listen: false).clearAll();
                                      Provider.of<FavoritesProvider>(context, listen: false).clearAll();
                                      await _authService.deleteAccount();
                                      if (context.mounted) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          "Delete Account",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C5CFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF7C5CFF), size: 20),
      ),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _settingsSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C5CFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF7C5CFF), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7C5CFF),
        activeTrackColor: const Color(0xFF7C5CFF).withOpacity(0.3),
      ),
    );
  }
}

// ─── Helper Widgets for Dialogs ──────────────────────────────────────

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(answer, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4)),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
