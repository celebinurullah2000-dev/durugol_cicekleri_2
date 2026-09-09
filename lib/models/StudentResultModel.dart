class StudentResultModel {
  final String studentName;
  final String bookletType; // "A" veya "B"
  final Map<String, Map<int, String>>
  studentAnswers; // Ders -> Soru No -> Verilen Cevap
  final int correctCount;
  final int wrongCount;
  final double netScore;

  StudentResultModel({
    required this.studentName,
    required this.bookletType,
    required this.studentAnswers,
    required this.correctCount,
    required this.wrongCount,
    required this.netScore,
  });

  Map<String, dynamic> toJson() => {
    'studentName': studentName,
    'bookletType': bookletType,
    'studentAnswers': studentAnswers.map(
      (key, value) =>
          MapEntry(key, value.map((k, v) => MapEntry(k.toString(), v))),
    ),
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'netScore': netScore,
  };
}
