import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../screens/pricing_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/favorites_screen.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Stack(
        children: [
          // Glassmorphic Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1020).withOpacity(0.8),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildCreditCard(context),
                const SizedBox(height: 32),
                _buildMenuItems(context),
                const Spacer(),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFF), Color(0xFF5CA4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFF).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? "U",
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? "Guest User",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? "Sign in to sync",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isFree = user?.planType == 'FREE';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree 
            ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
            : [const Color(0xFF7C5CFF).withOpacity(0.2), const Color(0xFF5CA4FF).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFree ? "FREE PLAN" : "DAILY PASS ACTIVE",
                style: TextStyle(
                  color: isFree ? Colors.white70 : const Color(0xFF7C5CFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.flash_on, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${user?.credits ?? 0}",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  "Credits Left",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (user?.credits ?? 0) / (isFree ? 5 : 10),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(isFree ? Colors.white30 : const Color(0xFF7C5CFF)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleType(12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text("Upgrade Now", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _menuTile(Icons.history_rounded, "Try-On History", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          }),
          _menuTile(Icons.favorite_rounded, "My Favorites", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          }),
          _menuTile(Icons.settings_rounded, "App Settings", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _menuTile(Icons.help_outline_rounded, "Help & Support", () => _showHelpDialog(context)),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151A2E),
        title: const Text("Help & Support", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Need help with your try-ons? Contact us at support@aurafit.com or visit our FAQ section.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _settingsToggle(String title, bool value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: Switch(value: value, onChanged: (v) {}, activeColor: const Color(0xFF7C5CFF)),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      shape: RoundedRectangleType(12),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Version 1.0.0",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Helper for rounded rectangle types
class RoundedRectangleType extends RoundedRectangleBorder {
  RoundedRectangleType(double radius) : super(borderRadius: BorderRadius.circular(radius));
}
