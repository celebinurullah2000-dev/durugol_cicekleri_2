// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_kitap_odev_screen.dart';

class TopluOdevScreen extends StatefulWidget {
  final String classId;
  final String userRole;
  const TopluOdevScreen({
    super.key,
    required this.classId,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<TopluOdevScreen> createState() => _TopluOdevScreenState();
}

class _TopluOdevScreenState extends State<TopluOdevScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Toplu Ödev Takibi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bu sınıfta kayıtlı öğrenci bulunamadı."),
            );
          }

          var ogrenciler = studentSnapshot.data!.docs;

          return ListView.builder(
            itemCount: ogrenciler.length,
            itemBuilder: (context, index) {
              var ogrenciDoc = ogrenciler[index];
              var ogrenciData = ogrenciDoc.data() as Map<String, dynamic>;
              String ogrenciAdi =
                  "${ogrenciData['firstName'] ?? ''} ${ogrenciData['lastName'] ?? ''}"
                      .trim();
              if (ogrenciAdi.isEmpty) ogrenciAdi = 'İsimsiz Öğrenci';
              String ogrenciId = ogrenciDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: ogrenciDoc.reference.collection('odevler').snapshots(),
                builder: (context, odevSnapshot) {
                  String durumOzeti = "Ödev yükleniyor...";
                  Color durumRengi = Colors.grey;
                  int yapilanSayisi = 0;
                  int toplamKitap = 0;
                  bool kilitliVar = false;

                  if (odevSnapshot.hasData &&
                      odevSnapshot.data!.docs.isNotEmpty) {
                    for (var odevDoc in odevSnapshot.data!.docs) {
                      var odevData = odevDoc.data() as Map<String, dynamic>;
                      List kitaplar = odevData['kitaplar'] ?? [];

                      for (var k in kitaplar) {
                        toplamKitap++;
                        if (k['durum'] == 'yapildi') {
                          yapilanSayisi++;
                        } else if (k['durum'] == 'ogretmen_reddi') {
                          kilitliVar = true;
                        }
                      }
                    }

                    if (toplamKitap == 0) {
                      durumOzeti = "Verilen ödev yok";
                      durumRengi = Colors.grey;
                    } else if (kilitliVar) {
                      durumOzeti =
                          "Kilitli/Reddedilen ödev var ($yapilanSayisi/$toplamKitap)";
                      durumRengi = Colors.red;
                    } else if (yapilanSayisi == toplamKitap) {
                      durumOzeti =
                          "Tümü Tamamlandı ($yapilanSayisi/$toplamKitap)";
                      durumRengi = Colors.green;
                    } else {
                      durumOzeti =
                          "Devam ediyor ($yapilanSayisi/$toplamKitap yapıldı)";
                      durumRengi = Colors.orange;
                    }
                  } else {
                    durumOzeti = "Ödev verilmemiş";
                    durumRengi = Colors.grey;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: durumRengi.withValues(alpha: 0.2),
                        child: Icon(Icons.person, color: durumRengi),
                      ),
                      title: Text(
                        ogrenciAdi,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        durumOzeti,
                        style: TextStyle(
                          color: durumRengi,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentOdevTakipScreen(
                              studentData: ogrenciData,
                              studentId: ogrenciId,
                              userRole: widget.userRole,
                              initialTabIndex: 1, // Sadece Ödev Takibi
                            ),
                          ),
                        );
                      },
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
