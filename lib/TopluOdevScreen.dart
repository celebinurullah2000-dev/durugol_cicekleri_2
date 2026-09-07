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
  // Filtreleme türü: 'tumu', 'yapanlar', 'yapmayanlar'
  String _secilenFiltre = 'tumu';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Toplu Ödev Takibi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Öğrencileri Filtrele",
            onSelected: (deger) {
              setState(() {
                _secilenFiltre = deger;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'tumu', child: Text("Tüm Öğrenciler")),
              const PopupMenuItem(
                value: 'yapanlar',
                child: Text("Ödevini Yapanlar"),
              ),
              const PopupMenuItem(
                value: 'yapmayanlar',
                child: Text("Ödevini Yapmayanlar"),
              ),
            ],
          ),
        ],
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

          var ogrenciler = List.from(studentSnapshot.data!.docs);

          // Türkçe alfabetik sıralama
          ogrenciler.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String adA =
                "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
            String adB =
                "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
            return _turkceKarsilastir(adA, adB);
          });

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
                  bool odevVar = false;

                  if (odevSnapshot.hasData &&
                      odevSnapshot.data!.docs.isNotEmpty) {
                    odevVar = true;
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

                  // Filtreleme Mantığı
                  bool tamamladiMi =
                      odevVar &&
                      toplamKitap > 0 &&
                      yapilanSayisi == toplamKitap;
                  if (_secilenFiltre == 'yapanlar' && !tamamladiMi) {
                    return const SizedBox.shrink();
                  }
                  if (_secilenFiltre == 'yapmayanlar' && tamamladiMi) {
                    return const SizedBox.shrink();
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
                              initialTabIndex: 1,
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

  // Türkçe Alfabetik Sıralama Fonksiyonu
  int _turkceKarsilastir(String a, String b) {
    const String turkceAlfabe = 'aabcçdefgğhıijklmnoöprsştuüvyz';
    String aKucuk = a
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');
    String bKucuk = b
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');
    int minLength = aKucuk.length < bKucuk.length
        ? aKucuk.length
        : bKucuk.length;
    for (int i = 0; i < minLength; i++) {
      int indexA = turkceAlfabe.indexOf(aKucuk[i]);
      int indexB = turkceAlfabe.indexOf(bKucuk[i]);
      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }
    return aKucuk.length.compareTo(bKucuk.length);
  }
}
