class Validators {
  static String? required(String? value, [String field = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return 'Valeur requise';
    final num = double.tryParse(value.replaceAll(',', '.'));
    if (num == null) return 'Nombre invalide';
    if (num <= 0) return 'La valeur doit être positive';
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.length < min) return 'Minimum $min caractères';
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final v in validators) {
      final result = v();
      if (result != null) return result;
    }
    return null;
  }
}
