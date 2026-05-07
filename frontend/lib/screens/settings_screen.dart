import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_in_slide.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

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
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
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
      onTap: () {},
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
