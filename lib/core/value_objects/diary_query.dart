class DiaryQuery {
  DiaryQuery(this.value);

  final String value;

  static final RegExp _allowedPattern = RegExp(r'^[a-zA-Z0-9 ]*$');

  static String? validate(String? input) {
    final sanitized = (input ?? '').trim();

    if (sanitized.isEmpty) {
      return 'Informe o diário que deseja encontrar';
    }

    if (sanitized.length > 40) {
      return 'Use no máximo 40 caracteres';
    }

    if (!_allowedPattern.hasMatch(sanitized)) {
      return 'Use apenas letras, números e espaço';
    }

    return null;
  }
}
