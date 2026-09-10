// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciProfilService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> ogrenciTumVerileriniGetir({
    required String studentId,
    required String classId,
  }) async {
    try {
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();
      Map<String, dynamic> studentData = studentDoc.exists
          ? (studentDoc.data() as Map<String, dynamic>)
          : {};

      var odevlerFuture = _firestore
          .collection('students')
          .doc(studentId)
          .collection('odevler')
          .get();
      var kitaplarFuture = _firestore
          .collection('students')
          .doc(studentId)
          .collection('okunan_kitaplar')
          .get();
      var istatistiklerFuture = _firestore
          .collection('students')
          .doc(studentId)
          .collection('istatistikler')
          .get();
      var isVerileriFuture = _firestore
          .collection('students')
          .doc(studentId)
          .collection('is_verileri')
          .get();

      var davranislarFuture = _firestore
          .collection('classes')
          .doc(classId)
          .collection('davranislar')
          .where('studentId', isEqualTo: studentId)
          .get();

      var etkinliklerFuture = _firestore
          .collection('classes')
          .doc(classId)
          .collection('etkinlikler')
          .where('katilanlar', arrayContains: studentId)
          .get();

      var dutyRecordsFuture = _firestore
          .collection('classes')
          .doc(classId)
          .collection('duty_records')
          .where('studentId', isEqualTo: studentId)
          .get();

      List<QuerySnapshot> results = await Future.wait([
        odevlerFuture,
        kitaplarFuture,
        istatistiklerFuture,
        isVerileriFuture,
        davranislarFuture,
        etkinliklerFuture,
        dutyRecordsFuture,
      ]);

      QuerySnapshot odevlerSnap = results[0];
      QuerySnapshot kitaplarSnap = results[1];
      QuerySnapshot istatistiklerSnap = results[2];
      QuerySnapshot isVerileriSnap = results[3];
      QuerySnapshot davranislarSnap = results[4];
      QuerySnapshot etkinliklerSnap = results[5];
      QuerySnapshot dutySnap = results[6];

      int toplamKitapSayisi = kitaplarSnap.docs.length;
      int toplamSayfaSayisi = 0;
      for (var doc in kitaplarSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        toplamSayfaSayisi +=
            int.tryParse(data['sayfaSayisi']?.toString() ?? '0') ?? 0;
      }

      int yapilanOdev = 0;
      int yapilmayanOdev = 0;
      int kilitliOdev = 0;
      for (var doc in odevlerSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String durum = data['durum'] ?? '';
        if (durum == 'yapildi') {
          yapilanOdev++;
        } else if (durum == 'yapilmadi') {
          yapilmayanOdev++;
        } else if (durum == 'kilitli') {
          kilitliOdev++;
        }
      }

      int nobetSayisi = dutySnap.docs.length;
      int gorevlilikSayisi = 0;
      int renkliKartSayisi = davranislarSnap.docs.length;
      int etkinlikSayisi = etkinliklerSnap.docs.length;

      return {
        'studentInfo': studentData,
        'toplamKitapSayisi': toplamKitapSayisi,
        'toplamSayfaSayisi': toplamSayfaSayisi,
        'yapilanOdev': yapilanOdev,
        'yapilmayanOdev': yapilmayanOdev,
        'kilitliOdev': kilitliOdev,
        'nobetSayisi': nobetSayisi,
        'gorevlilikSayisi': gorevlilikSayisi,
        'renkliKartSayisi': renkliKartSayisi,
        'etkinlikSayisi': etkinlikSayisi,
        'istatistiklerDocs': istatistiklerSnap.docs
            .map((e) => e.data())
            .toList(),
        'isVerileriDocs': isVerileriSnap.docs.map((e) => e.data()).toList(),
      };
    } catch (e) {
      print("Öğrenci profili veri çekme hatası: $e");
      return {};
    }
  }
}
