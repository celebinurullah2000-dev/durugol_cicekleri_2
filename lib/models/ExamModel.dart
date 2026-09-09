class ExamModel {
  final String id;
  final String title;
  final DateTime date;
  final Map<String, int>
  lessonQuestionCounts; // Örn: {"Türkçe": 20, "Matematik": 20}
  final List<String> disabledLessons; // İptal edilen dersler

  ExamModel({
    required this.id,
    required this.title,
    required this.date,
    required this.lessonQuestionCounts,
    required this.disabledLessons,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'lessonQuestionCounts': lessonQuestionCounts,
    'disabledLessons': disabledLessons,
  };

  factory ExamModel.fromJson(Map<String, dynamic> json) => ExamModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    date: DateTime.parse(json['date']),
    lessonQuestionCounts: Map<String, int>.from(
      json['lessonQuestionCounts'] ?? {},
    ),
    disabledLessons: List<String>.from(json['disabledLessons'] ?? []),
  );
}
