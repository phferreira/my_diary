class Diary {
  const Diary({
    required this.id,
    required this.name,
    required this.content,
    this.isPublic = false,
    this.accessRequired = false,
  });

  final String id;
  final String name;
  final String content;
  final bool isPublic;
  final bool accessRequired;

  bool get requiresPassword => accessRequired;
  bool get isProtected => !isPublic && accessRequired;
  bool get isReadOnly => isPublic && accessRequired;

  Diary copyWith(
          {String? id,
          String? name,
          String? content,
          bool? isPublic,
          bool? accessRequired}) =>
      Diary(
        id: id ?? this.id,
        name: name ?? this.name,
        content: content ?? this.content,
        isPublic: isPublic ?? this.isPublic,
        accessRequired: accessRequired ?? this.accessRequired,
      );
}
