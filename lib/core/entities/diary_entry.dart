class DiaryEntry {
  const DiaryEntry({
    required this.diaryId,
    required this.date,
    required this.content,
  });

  final String diaryId;
  final DateTime date;
  final String content;
}
