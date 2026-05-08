import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_background.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
                  ),
                  _settingsTile(
                    icon: Icons.workspace_premium_rounded,
                    title: "Subscription",
                    subtitle: user?.planType == 'FREE' ? "Free Tier" : "Daily Pass",
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle("PREFERENCES"),
                _buildSettingsCard([
                  _settingsSwitch(
                    icon: Icons.notifications_none_rounded,
                    title: "Push Notifications",
                    value: true,
                  ),
                  _settingsSwitch(
                    icon: Icons.high_quality_rounded,
                    title: "HD Rendering",
                    value: false,
                  ),
                  _settingsSwitch(
                    icon: Icons.save_alt_rounded,
                    title: "Auto-save to Gallery",
                    value: true,
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle("SUPPORT & LEGAL"),
                _buildSettingsCard([
                  _settingsTile(
                    icon: Icons.help_outline_rounded,
                    title: "Help Center",
                  ),
                  _settingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
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
        onChanged: (v) {},
        activeColor: const Color(0xFF7C5CFF),
        activeTrackColor: const Color(0xFF7C5CFF).withOpacity(0.3),
      ),
    );
  }
}
