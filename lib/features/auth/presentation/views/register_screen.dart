import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/create_account_step.dart';
import '../widgets/role_selection_step.dart';
import '../widgets/confirmation_step.dart';
import 'login_screen.dart';
import '../../domain/entities/user_role.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;

  UserRole _selectedRole = UserRole.participant;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) => setState(() => _currentStep = step);

  bool _validateAccountForm() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _firstNameError = firstName.isEmpty ? 'First name is required.' : null;
      _lastNameError = lastName.isEmpty ? 'Last name is required.' : null;
      _emailError = email.isEmpty
          ? 'Email address is required.'
          : (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                ? 'Enter a valid email address.'
                : null);
      _passwordError = password.isEmpty
          ? 'Password is required.'
          : (password.length < 8
                ? 'Password must contain at least 8 characters.'
                : null);
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  void _handleCreateAccount() {
    if (!_validateAccountForm()) {
      _goToStep(0);
      return;
    }

    setState(() => _isLoading = true);
    // TODO: connect the real account creation flow.

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildStep(isDark),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return CreateAccountStep(
          key: const ValueKey('step_account'),
          isDark: isDark,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          passwordController: _passwordController,
          firstNameError: _firstNameError,
          lastNameError: _lastNameError,
          emailError: _emailError,
          passwordError: _passwordError,
          obscurePassword: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onContinue: () {
            if (_validateAccountForm()) {
              _goToStep(1);
            }
          },
          onSignIn: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        );
      case 1:
        return RoleSelectionStep(
          key: const ValueKey('step_role'),
          isDark: isDark,
          selectedRole: _selectedRole,
          isLoading: _isLoading,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
          onCreateAccount: _handleCreateAccount,
          onGoBack: () => _goToStep(0),
        );
      default:
        return ConfirmationStep(
          key: const ValueKey('step_done'),
          isDark: isDark,
        );
    }
  }
}
