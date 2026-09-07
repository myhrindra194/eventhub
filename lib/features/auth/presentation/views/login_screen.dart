import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_text_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  static final _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailError;
    String? passwordError;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      emailError = 'Please enter your email address.';
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'Please enter a valid email address.';
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      passwordError = 'Please enter your password.';
    } else if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters.';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  void _handleSignIn() {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    // TODO: brancher la logique d'authentification réelle
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    });
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.05),

              // Logo
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/images/logoev.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titres
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: AppTypography.display(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to EventHub',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(isDark),
              ),
              const SizedBox(height: 40),

              AuthTextField(
                label: 'Email Address',
                hint: 'name@example.com',
                controller: _emailController,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 20),

              AuthTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                isDark: isDark,
                obscureText: _obscurePassword,
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 4),

              // Forgot password button 
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.accentIndigo,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In button
              AppButton(
                text: 'Sign In',
                isLoading: _isLoading,
                onPressed: _handleSignIn,
              ),
              const SizedBox(height: 24),

              // Divider "OR"
              Row(
                children: [
                  Expanded(
                    child: Divider(color: textSecondary.withValues(alpha: 0.3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: AppTypography.caption(isDark)),
                  ),
                  Expanded(
                    child: Divider(color: textSecondary.withValues(alpha: 0.3)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Google button
              AppButton(
                text: 'Continue with Google',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  // TODO: brancher l'authentification Google
                },
                icon: Icons.g_mobiledata_rounded,
              ),
              const SizedBox(height: 32),

              // Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.body(isDark),
                  ),
                  GestureDetector(
                    onTap: _goToRegister,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.accentIndigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}