import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_text_field.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  static final _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailError;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      emailError = 'Please enter your email address.';
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'Please enter a valid email address.';
    }

    setState(() {
      _emailError = emailError;
    });

    return emailError == null;
  }

  void _handleSendResetLink() {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    // TODO: brancher la logique d'envoi de mail de réinitialisation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.02),

              // Icon Key Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: AppColors.accentIndigo,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titles
              Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: AppTypography.display(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email address and we'll send you instructions to reset your password.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(isDark),
              ),
              const SizedBox(height: 40),

              // Email Input
              AuthTextField(
                label: 'Email Address',
                hint: 'name@example.com',
                controller: _emailController,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppButton(
                text: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _handleSendResetLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}