// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiVisionService {
  final GenerativeModel _model;

  GeminiVisionService({required String apiKey})
    : _model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);

  // Görseli analiz edip metin/JSON çıktısı alma
  Future<String?> analyzeFormImage({
    required Uint8List imageBytes,
    required String promptText,
  }) async {
    try {
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      return response.text;
    } catch (e) {
      print('Gemini Vision Okuma Hatası: $e');
      return null;
    }
  }
}
