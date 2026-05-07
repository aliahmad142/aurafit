import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_background.dart';
import '../widgets/unique_animated_logo.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final FocusNode _emailNode = FocusNode();
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.forgotPassword(_emailCtrl.text.trim());
    if (ok) {
      setState(() => _isSuccess = true);
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
                      icon: Icons.key_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 32),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: Text(_isSuccess ? "Check Your Inbox" : "Forgot Password",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                          _isSuccess
                              ? "We've sent a 6-character reset token to your email. Please enter it on the next screen."
                              : "Enter your email address and we'll send you a link to reset your password.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                    ),
                    const SizedBox(height: 48),
                    if (!_isSuccess) ...[
                      FadeInSlide(
                        delay: const Duration(milliseconds: 400),
                        child: _card(),
                      ),
                    ] else ...[
                      FadeInSlide(
                        delay: const Duration(milliseconds: 400),
                        child: CustomButton(
                          text: "Proceed to Reset",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResetPasswordScreen(email: _emailCtrl.text.trim()),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
            _field(_emailCtrl, "Email address", Icons.email_outlined,
                node: _emailNode,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? "Enter a valid email" : null),
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
          text: "Send Reset Link",
          isLoading: auth.isLoading,
          onPressed: _submit,
        );
      });

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {FocusNode? node, TextInputType? keyboardType, String? Function(String?)? validator}) {
    final isFocused = node?.hasFocus ?? false;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        focusNode: node,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: isFocused ? AppColors.primary : AppColors.textSecondary, size: 20),
          filled: true,
          fillColor: isFocused ? AppColors.primary.withOpacity(0.05) : AppColors.background.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}
