import 'package:my_diary/core/security/password_hasher.dart';

class Diary {
  const Diary({
    required this.id,
    required this.name,
    required this.content,
    this.password,
    this.publicPassword,
    this.isPublic = false,
  });

  final String id;
  final String name;
  final String content;
  final String? password;
  final String? publicPassword;
  final bool isPublic;

  bool get hasPassword => password?.isNotEmpty ?? false;

  bool get hasPublicPassword => publicPassword?.isNotEmpty ?? false;

  bool get requiresPassword => hasPassword || hasPublicPassword;

  bool get isProtected => !isPublic && hasPassword;

  bool get isReadOnly => isPublic && hasPublicPassword;

  bool matchesPassword(String providedPassword) {
    if (!hasPassword) {
      return !requiresPassword;
    }

    return _matchesStoredPassword(
      providedPassword: providedPassword,
      storedPassword: password,
    );
  }

  bool matchesPublicPassword(String providedPassword) {
    if (!hasPublicPassword) {
      return false;
    }

    return _matchesStoredPassword(
      providedPassword: providedPassword,
      storedPassword: publicPassword,
    );
  }

  bool canOpenWithPassword(String providedPassword) {
    return matchesPublicPassword(providedPassword) ||
        matchesPassword(providedPassword);
  }

  Diary copyWith({
    String? id,
    String? name,
    String? content,
    Object? password = _noChange,
    Object? publicPassword = _noChange,
    bool? isPublic,
  }) {
    return Diary(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      password: password == _noChange ? this.password : password as String?,
      publicPassword: publicPassword == _noChange
          ? this.publicPassword
          : publicPassword as String?,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  static const Object _noChange = Object();

  bool _matchesStoredPassword({
    required String providedPassword,
    required String? storedPassword,
  }) {
    final normalizedProvidedPassword = providedPassword.trim();
    if (normalizedProvidedPassword.isEmpty || storedPassword == null) {
      return false;
    }

    final hashedProvidedPassword =
        PasswordHasher.hash(normalizedProvidedPassword);
    if (PasswordHasher.isSha256Hash(storedPassword)) {
      return storedPassword == hashedProvidedPassword;
    }

    return storedPassword == normalizedProvidedPassword;
  }
}
