import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EtkinlikDetayScreen extends StatelessWidget {
  final String classId;
  final String etkinlikId;
  final String etkinlikAdi;
  final String aciklama;
  final bool aktifMi;
  final bool isTeacher; // Rol bilgisini alıyoruz

  const EtkinlikDetayScreen({
    super.key,
    required this.classId,
    required this.etkinlikId,
    required this.etkinlikAdi,
    required this.aciklama,
    required this.aktifMi,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(etkinlikAdi), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Açıklama:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              aciklama.isEmpty ? "Açıklama girilmemiş." : aciklama,
              style: const TextStyle(fontSize: 15),
            ),
            const Divider(height: 30),
            const Text(
              "Öğrenci Katılım Durumları:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('etkinlikler')
                    .doc(etkinlikId)
                    .snapshots(),
                builder: (context, etkinlikSnap) {
                  if (etkinlikSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var etkinlikData =
                      etkinlikSnap.data?.data() as Map<String, dynamic>? ?? {};
                  Map<String, dynamic> katilanlarMap =
                      etkinlikData['katilanOgrenciler'] ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('classId', isEqualTo: classId)
                        .snapshots(),
                    builder: (context, studentSnap) {
                      if (studentSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!studentSnap.hasData ||
                          studentSnap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("Bu sınıfta öğrenci bulunamadı."),
                        );
                      }

                      var students = studentSnap.data!.docs;

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var studentDoc = students[index];
                          var studentData =
                              studentDoc.data() as Map<String, dynamic>;
                          String studentId = studentDoc.id;
                          String adSoyad =
                              "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

                          bool yapildiMi = katilanlarMap[studentId] == true;

                          Color renk = Colors.black87;
                          String durumMetni = "";

                          if (yapildiMi) {
                            renk = Colors.green.shade700;
                            durumMetni = "Tamamladı ✅";
                          } else if (aktifMi) {
                            renk = Colors.black87;
                            durumMetni = "Henüz Yapmadı";
                          } else {
                            renk = Colors.red.shade700;
                            durumMetni = "Yapmadı ❌";
                          }

                          return ListTile(
                            title: Text(
                              adSoyad,
                              style: TextStyle(
                                color: renk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              durumMetni,
                              style: TextStyle(color: renk, fontSize: 12),
                            ),
                            leading: Checkbox(
                              value: yapildiMi,
                              activeColor: Colors.indigo,
                              // Sınıf öğretmeniyse onChanged aktif olur, diğer kullanıcılarda null verilerek pasif (tıklanamaz) yapılır
                              onChanged: isTeacher
                                  ? (yeniDeger) async {
                                      katilanlarMap[studentId] =
                                          yeniDeger ?? false;
                                      await FirebaseFirestore.instance
                                          .collection('classes')
                                          .doc(classId)
                                          .collection('etkinlikler')
                                          .doc(etkinlikId)
                                          .update({
                                            'katilanOgrenciler': katilanlarMap,
                                          });
                                    }
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
