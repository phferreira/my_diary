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

    return password == providedPassword;
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
