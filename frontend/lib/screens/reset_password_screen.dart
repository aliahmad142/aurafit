import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_background.dart';
import '../widgets/unique_animated_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final FocusNode _tokenNode = FocusNode();
  final FocusNode _passNode = FocusNode();
  bool _hidePass = true;

  @override
  void initState() {
    super.initState();
    _tokenNode.addListener(() => setState(() {}));
    _passNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _tokenNode.dispose();
    _passNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.resetPassword(
      email: widget.email,
      token: _tokenCtrl.text.trim(),
      newPassword: _passCtrl.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated! Please log in.")),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(children: [
                    const UniqueAnimatedLogo(
                      icon: Icons.lock_reset_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 32),
                    const FadeInSlide(
                      delay: Duration(milliseconds: 200),
                      child: Text("Set New Password",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 12),
                    const FadeInSlide(
                      delay: Duration(milliseconds: 300),
                      child: Text(
                          "Enter the reset token from your terminal and your new secure password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                    ),
                    const SizedBox(height: 48),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 400),
                      child: _card(),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _field(_tokenCtrl, "Reset Token", Icons.vpn_key_outlined,
                node: _tokenNode,
                validator: (v) => v == null || v.isEmpty ? "Enter the token" : null),
            const SizedBox(height: 16),
            _field(_passCtrl, "New Password", Icons.lock_outline_rounded,
                node: _passNode,
                obscure: _hidePass,
                suffix: IconButton(
                  icon: Icon(_hidePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
                validator: (v) => v != null && v.length >= 6 ? null : "Min 6 characters"),
            const SizedBox(height: 24),
            _errorBanner(),
            _submitBtn(),
          ]),
        ),
      );

  Widget _errorBanner() => Consumer<AuthProvider>(builder: (_, auth, __) {
        if (auth.errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(auth.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
            ]),
          ),
        );
      });

  Widget _submitBtn() => Consumer<AuthProvider>(builder: (_, auth, __) {
        return CustomButton(
          text: "Update Password",
          isLoading: auth.isLoading,
          onPressed: _submit,
        );
      });

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {FocusNode? node, bool obscure = false, Widget? suffix, String? Function(String?)? validator}) {
    final isFocused = node?.hasFocus ?? false;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        focusNode: node,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: isFocused ? AppColors.secondary : AppColors.textSecondary, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: isFocused ? AppColors.secondary.withOpacity(0.05) : AppColors.background.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
        ),
      ),
    );
  }
}
