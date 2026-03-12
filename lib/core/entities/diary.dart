import 'package:my_diary/core/security/password_hasher.dart';

class Diary {
  const Diary({
    required this.id,
    required this.name,
    required this.content,
    this.password,
    this.isPublic = false,
  });

  final String id;
  final String name;
  final String content;
  final String? password;
  final bool isPublic;

  bool get isProtected => !isPublic && (password?.isNotEmpty ?? false);

  bool matchesPassword(String providedPassword) {
    if (!isProtected) {
      return true;
    }

    final storedPassword = password;
    if (storedPassword == null || storedPassword.isEmpty) {
      return false;
    }

    final hashedProvidedPassword = PasswordHasher.hash(providedPassword);
    if (PasswordHasher.isSha256Hash(storedPassword)) {
      return storedPassword == hashedProvidedPassword;
    }

    return storedPassword == providedPassword.trim();
  }

  Diary copyWith({
    String? id,
    String? name,
    String? content,
    String? password,
    bool? isPublic,
  }) {
    return Diary(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      password: password ?? this.password,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
