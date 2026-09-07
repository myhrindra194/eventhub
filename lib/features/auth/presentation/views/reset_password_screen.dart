import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? passwordError;
    String? confirmPasswordError;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      passwordError = 'Please enter a new password.';
    } else if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters.';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your password.';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match.';
    }

    setState(() {
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    return passwordError == null && confirmPasswordError == null;
  }

  void _handleResetPassword() {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    // TODO: brancher la logique d'enregistrement du nouveau mot de passe
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Retourne à la page de Login après la mise à jour
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
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

              // Key Icon Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 40,
                    color: AppColors.accentIndigo,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titles
              Text(
                'Create New Password',
                textAlign: TextAlign.center,
                style: AppTypography.display(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from previously used passwords.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(isDark),
              ),
              const SizedBox(height: 32),

              // New Password Input
              AuthTextField(
                label: 'New Password',
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
              const SizedBox(height: 20),

              // Confirm Password Input
              AuthTextField(
                label: 'Confirm New Password',
                hint: '••••••••',
                controller: _confirmPasswordController,
                isDark: isDark,
                obscureText: _obscureConfirmPassword,
                errorText: _confirmPasswordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textSecondary,
                  ),
                  onPressed: () {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Reset Password Button
              AppButton(
                text: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _handleResetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}