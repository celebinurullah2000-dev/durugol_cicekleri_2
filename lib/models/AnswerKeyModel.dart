class AnswerKeyModel {
  final String bookletType; // "A" veya "B"
  // Ders adı -> (Soru Numarası -> Doğru Cevap)
  // Örn: {"Türkçe": {1: "A", 2: "C", 3: "B"}}
  final Map<String, Map<int, String>> answers;

  AnswerKeyModel({required this.bookletType, required this.answers});

  Map<String, dynamic> toJson() => {
    'bookletType': bookletType,
    'answers': answers.map(
      (key, value) =>
          MapEntry(key, value.map((k, v) => MapEntry(k.toString(), v))),
    ),
  };

  factory AnswerKeyModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = rawAnswers.map((lesson, questions) {
      final qMap = (questions as Map<String, dynamic>).map(
        (qNo, answer) => MapEntry(int.parse(qNo), answer.toString()),
      );
      return MapEntry(lesson, qMap);
    });

    return AnswerKeyModel(
      bookletType: json['bookletType'] ?? 'A',
      answers: parsedAnswers,
    );
  }
}
