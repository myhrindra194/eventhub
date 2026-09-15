/// Form validators returning a French error message or `null` when valid.
/// Composable: `Validators.compose([Validators.required, Validators.email])`.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static const passwordMinLength = 6;

  static String? required(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) return '$label est obligatoire.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "L'email est obligatoire.";
    }
    if (!_emailRegex.hasMatch(value.trim())) return 'Email invalide.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    if (value.length < passwordMinLength) {
      return 'Au moins $passwordMinLength caractères.';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String label = 'Ce champ',
  }) {
    if (value == null || value.trim().length < min) {
      return '$label doit contenir au moins $min caractères.';
    }
    return null;
  }

  static String? positiveInt(String? value, {String label = 'La valeur'}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label doit être un nombre entier.';
    if (parsed <= 0) return '$label doit être supérieure à 0.';
    return null;
  }

  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
