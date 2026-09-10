import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import 'auth_text_field.dart';

class CreateAccountStep extends StatelessWidget {
  final bool isDark;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? firstNameError;
  final String? lastNameError;
  final String? emailError;
  final String? passwordError;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  const CreateAccountStep({
    super.key,
    required this.isDark,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    this.firstNameError,
    this.lastNameError,
    this.emailError,
    this.passwordError,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onContinue,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: size.height * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Account', style: AppTypography.display(isDark)),
          const SizedBox(height: 6),
          Text(
            'Join the community today',
            style: AppTypography.bodyLarge(isDark),
          ),
          const SizedBox(height: 32),

          // First / Last name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthTextField(
                  label: 'First Name',
                  hint: 'First Name',
                  controller: firstNameController,
                  isDark: isDark,
                  errorText: firstNameError,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AuthTextField(
                  label: 'Last Name',
                  hint: 'Last Name',
                  controller: lastNameController,
                  isDark: isDark,
                  errorText: lastNameError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AuthTextField(
            label: 'Email Address',
            hint: 'name@example.com',
            controller: emailController,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            errorText: emailError,
          ),
          const SizedBox(height: 20),

          AuthTextField(
            label: 'Password',
            hint: 'Min. 8 characters',
            controller: passwordController,
            isDark: isDark,
            obscureText: obscurePassword,
            errorText: passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: 32),

          AppButton(text: 'Continue', onPressed: onContinue),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.body(isDark),
              ),
              GestureDetector(
                onTap: onSignIn,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.accentIndigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
