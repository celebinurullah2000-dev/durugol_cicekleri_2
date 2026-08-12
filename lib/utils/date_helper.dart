// lib/utils/date_helper.dart
import 'package:intl/intl.dart';

class DateHelper {
  static bool isNew(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt).inDays;
    return difference <= 7;
  }

  static String getFormattedDate() {
    // Türkçe ay isimleriyle gün-Ay-yıl formatı
    DateTime now = DateTime.now();
    List<String> months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    String day = now.day.toString();
    String month = months[now.month];
    String year = now.year.toString();

    return "$day-$month-$year"; // Örn: 12-Ağustos-2026
  }

  static String getFormattedTime() {
    DateTime now = DateTime.now();
    return DateFormat('HH:mm').format(now); // 24 saat esasına göre Örn: 17:21
  }
}
