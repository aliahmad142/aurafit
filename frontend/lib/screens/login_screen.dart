import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_background.dart';
import '../widgets/unique_animated_logo.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;
  late AnimationController _animCtrl;
  late AnimationController _pulseCtrl;
  
  final FocusNode _emailNode = FocusNode();
  final FocusNode _passNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _emailNode.addListener(() => setState(() {}));
    _passNode.addListener(() => setState(() {}));
    
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
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
                  child: Text("Welcome Back",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5)),
                ),
                const SizedBox(height: 8),
                const FadeInSlide(
                  delay: Duration(milliseconds: 300),
                  child: Text("Sign in to continue your style journey",
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
                  child: _signupLink(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => const UniqueAnimatedLogo(
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
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
            _field(_emailCtrl, "Email address", Icons.email_outlined,
                node: _emailNode,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? "Enter a valid email" : null),
            const SizedBox(height: 16),
            _field(_passCtrl, "Password", Icons.lock_outline_rounded,
                node: _passNode,
                obscure: _hidePass,
                suffix: IconButton(
                  icon: Icon(_hidePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
                validator: (v) => v != null && v.length >= 6 ? null : "Min 6 characters"),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _errorBanner(),
            _loginBtn(),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.2))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.2))),
            ]),
            const SizedBox(height: 20),
            _googleBtn(),
          ]),
        ),
      );

  Widget _googleBtn() => Consumer<AuthProvider>(builder: (_, auth, __) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final ok = await auth.signInWithGoogle();
                if (ok && mounted) {
                  await auth.refreshAllData(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    "https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg",
                    height: 24,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.g_mobiledata_rounded, size: 30, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });

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

  Widget _loginBtn() => Consumer<AuthProvider>(builder: (_, auth, __) {
        return Hero(
          tag: 'auth_button',
          child: CustomButton(
            text: "Sign In",
            isLoading: auth.isLoading,
            onPressed: _login,
          ),
        );
      });

  Widget _signupLink() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Don't have an account? ",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        GestureDetector(
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).clearError();
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SignupScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 300),
            ));
          },
          child: const Text("Sign Up",
              style: TextStyle(
                  color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ]);

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false,
      TextInputType? keyboardType,
      Widget? suffix,
      FocusNode? node,
      String? Function(String?)? validator}) {
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
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: isFocused ? AppColors.primary : AppColors.textSecondary, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: isFocused ? AppColors.primary.withOpacity(0.05) : AppColors.background.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      ),
    );
  }
}
