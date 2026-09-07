// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciIsTakipScreen extends StatelessWidget {
  final String studentId;
  final String classId;

  const OgrenciIsTakipScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ödev ve Etkinlik Takibim"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // Sınıfa ait işleri tarih sırasına göre dinliyoruz (En yeni en üstte)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('sinif_isleri')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz öğretmeniniz tarafından eklenmiş bir iş/etkinlik yok.",
              ),
            );
          }

          var isler = snapshot.data!.docs;

          return ListView.builder(
            itemCount: isler.length,
            itemBuilder: (context, index) {
              var isDoc = isler[index];
              var isData = isDoc.data() as Map<String, dynamic>;
              String isAdi = isData['isAdi'] ?? '';
              String veriTuru = isData['veriTuru'] ?? 'artı_eksi';
              String isId = isDoc.id;

              // Veriliş tarihini okunabilir formata çevirme
              var tarihField = isData['tarih'];
              String verilisTarihiStr = "Belirtilmemiş";
              if (tarihField is Timestamp) {
                DateTime dt = tarihField.toDate();
                verilisTarihiStr = "${dt.day}.${dt.month}.${dt.year}";
              } else if (tarihField is String && tarihField.isNotEmpty) {
                verilisTarihiStr = tarihField;
              }

              // Her iş için öğrencinin o işe ait verisini (deger) alt sorgu ile çekiyoruz
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId)
                    .collection('is_verileri')
                    .doc(isId)
                    .get(),
                builder: (context, veriSnap) {
                  String deger = '-';
                  if (veriSnap.hasData && veriSnap.data!.exists) {
                    var vData = veriSnap.data!.data() as Map<String, dynamic>;
                    deger = vData['deger'] ?? '-';
                  }

                  // Duruma göre renk ve simge belirleme
                  Color durumRengi = Colors.grey;
                  if (veriTuru == 'artı_eksi') {
                    durumRengi = (deger == '+') ? Colors.green : Colors.red;
                  } else {
                    durumRengi = (deger != '-' && deger.isNotEmpty)
                        ? Colors.indigo
                        : Colors.grey;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: durumRengi.withValues(alpha: 0.2),
                        child: Icon(
                          veriTuru == 'artı_eksi'
                              ? (deger == '+' ? Icons.check : Icons.close)
                              : Icons.assignment_turned_in,
                          color: durumRengi,
                        ),
                      ),
                      title: Text(
                        isAdi,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Görev kartının altında hem türü hem de veriliş tarihini gösteriyoruz
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Tür: ${veriTuru.toUpperCase()} • Tarih: $verilisTarihiStr",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: durumRengi.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: durumRengi),
                        ),
                        child: Text(
                          deger,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: durumRengi,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
