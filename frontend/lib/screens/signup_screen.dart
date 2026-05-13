import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_background.dart';
import '../widgets/unique_animated_logo.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _hidePass = true;
  bool _hideConfirm = true;
  late AnimationController _animCtrl;
  late AnimationController _pulseCtrl;

  final FocusNode _nameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _passNode = FocusNode();
  final FocusNode _confirmNode = FocusNode();
  final FocusNode _referralNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _nameNode.addListener(() => setState(() {}));
    _emailNode.addListener(() => setState(() {}));
    _passNode.addListener(() => setState(() {}));
    _confirmNode.addListener(() => setState(() {}));
    _referralNode.addListener(() => setState(() {}));
    
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _referralCtrl.dispose();
    _nameNode.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    _confirmNode.dispose();
    _referralNode.dispose();
    super.dispose();
  }

  double _passwordStrength() {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.20;
    return s.clamp(0.0, 1.0);
  }

  Color _strengthColor() {
    final s = _passwordStrength();
    if (s <= 0.25) return Colors.red;
    if (s <= 0.5) return Colors.orange;
    if (s <= 0.75) return Colors.amber;
    return AppColors.secondary;
  }

  String _strengthLabel() {
    final s = _passwordStrength();
    if (s <= 0) return "";
    if (s <= 0.25) return "Weak";
    if (s <= 0.5) return "Fair";
    if (s <= 0.75) return "Good";
    return "Strong";
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final referral = _referralCtrl.text.trim();
    final ok = await auth.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      referralCode: referral.isNotEmpty ? referral : null,
    );
    if (ok && mounted) {
      await auth.refreshAllData(context);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: _logo(),
                ),
                const SizedBox(height: 24),
                const FadeInSlide(
                  delay: Duration(milliseconds: 200),
                  child: Text("Create Account",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5)),
                ),
                const SizedBox(height: 8),
                const FadeInSlide(
                  delay: Duration(milliseconds: 300),
                  child: Text("Join the AI fashion revolution",
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 48),
                FadeInSlide(
                  delay: const Duration(milliseconds: 400),
                  child: _card(),
                ),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: const Duration(milliseconds: 500),
                  child: _loginLink(),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => const UniqueAnimatedLogo(
        icon: Icons.person_add_rounded,
        color: AppColors.secondary,
      );

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
            FadeInSlide(
              delay: const Duration(milliseconds: 500),
              child: _field(_nameCtrl, "Full name", Icons.person_outline,
                  node: _nameNode,
                  validator: (v) => v != null && v.trim().length >= 2
                      ? null
                      : "Name must be at least 2 characters"),
            ),
            const SizedBox(height: 16),
            FadeInSlide(
              delay: const Duration(milliseconds: 600),
              child: _field(_emailCtrl, "Email address", Icons.email_outlined,
                  node: _emailNode,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? "Enter a valid email" : null),
            ),
            const SizedBox(height: 16),
            FadeInSlide(
              delay: const Duration(milliseconds: 700),
              child: _field(_passCtrl, "Password", Icons.lock_outline_rounded,
                  node: _passNode,
                  obscure: _hidePass,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    icon: Icon(_hidePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                  ),
                  validator: (v) => v != null && v.length >= 6 ? null : "Min 6 characters"),
            ),
            if (_passCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength(),
                      minHeight: 4,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation(_strengthColor()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_strengthLabel(),
                    style: TextStyle(
                        color: _strengthColor(), fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ],
            const SizedBox(height: 16),
            FadeInSlide(
              delay: const Duration(milliseconds: 800),
              child: _field(_confirmCtrl, "Confirm password", Icons.lock_rounded,
                  node: _confirmNode,
                  obscure: _hideConfirm,
                  suffix: IconButton(
                    icon: Icon(_hideConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                  ),
                  validator: (v) => v == _passCtrl.text ? null : "Passwords don't match"),
            ),
            const SizedBox(height: 16),
            FadeInSlide(
              delay: const Duration(milliseconds: 850),
              child: _field(_referralCtrl, "Referral Code (optional)", Icons.card_giftcard_rounded,
                  node: _referralNode),
            ),
            const SizedBox(height: 24),
            _errorBanner(),
            FadeInSlide(
              delay: const Duration(milliseconds: 900),
              child: _signupBtn(),
            ),
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

  Widget _signupBtn() => Consumer<AuthProvider>(builder: (_, auth, __) {
        return Hero(
          tag: 'auth_button',
          child: CustomButton(
            text: "Create Account",
            isLoading: auth.isLoading,
            gradient: AppColors.secondaryGradient,
            onPressed: _signup,
          ),
        );
      });

  Widget _loginLink() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Already have an account? ",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        GestureDetector(
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).clearError();
            Navigator.of(context).pop();
          },
          child: const Text("Sign In",
              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ]);

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false,
      TextInputType? keyboardType,
      Widget? suffix,
      FocusNode? node,
      String? Function(String?)? validator,
      void Function(String)? onChanged}) {
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
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
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
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      ),
    );
  }
}
