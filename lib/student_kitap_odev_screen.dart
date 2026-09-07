// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils.dart';

class StudentOdevTakipScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  final String userRole;
  final int initialTabIndex; // 0: Sadece Kitaplar, 1: Sadece Ödev Takibi

  const StudentOdevTakipScreen({
    super.key,
    required this.studentData,
    required this.studentId,
    this.userRole = 'classroom_teacher',
    this.initialTabIndex = 1,
  });

  @override
  State<StudentOdevTakipScreen> createState() => _StudentOdevTakipScreenState();
}

class _StudentOdevTakipScreenState extends State<StudentOdevTakipScreen> {
  Future<void> _ogretmenOdevKitabiDurumGuncelle(
    BuildContext context,
    String odevId,
    List mevcutKitaplar,
    int index,
  ) async {
    Map<String, dynamic> secilenKitap = Map.from(mevcutKitaplar[index]);
    String eskiDurum = secilenKitap['durum'] ?? 'bekliyor';

    bool yapildiIseReddedildi = (eskiDurum == 'yapildi');

    secilenKitap['durum'] = (eskiDurum == 'ogretmen_reddi')
        ? 'bekliyor'
        : 'ogretmen_reddi';
    mevcutKitaplar[index] = secilenKitap;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .collection('odevler')
        .doc(odevId)
        .update({'kitaplar': mevcutKitaplar});

    // Eğer öğrenci 'yapildi' yapmışken öğretmen 'ogretmen_reddi' (yapılmadı) yaptıysa sarı kart gönder
    if (yapildiIseReddedildi && secilenKitap['durum'] == 'ogretmen_reddi') {
      String? classId = widget.studentData['classId'];
      if (classId != null && classId.isNotEmpty) {
        var davranisRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('davranislar')
            .doc(widget.studentId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          var snapshot = await transaction.get(davranisRef);
          int mevcutSari = 0;
          if (snapshot.exists && snapshot.data() != null) {
            mevcutSari = (snapshot.data()!['sariKart'] ?? 0) as int;
          }
          transaction.set(davranisRef, {
            'sariKart': mevcutSari + 1,
            'guncellemeTarihi': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
      }
    }
  }

  // Kesin sonuç veren Regex ve kelime tabanlı Türkçe tarih ayrıştırıcı
  DateTime? _parseTurkishDate(String str) {
    try {
      str = str.toLowerCase();

      final dayMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(str);
      final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(str);

      if (dayMatch == null || yearMatch == null) return null;

      int day = int.parse(dayMatch.group(1)!);
      int year = int.parse(yearMatch.group(1)!);

      int month = 1;
      if (str.contains('ocak')) {
        month = 1;
      } else if (str.contains('şubat') || str.contains('subat')) {
        month = 2;
      } else if (str.contains('mart')) {
        month = 3;
      } else if (str.contains('nisan')) {
        month = 4;
      } else if (str.contains('mayıs') || str.contains('mayis')) {
        month = 5;
      } else if (str.contains('haziran')) {
        month = 6;
      } else if (str.contains('temmuz')) {
        month = 7;
      } else if (str.contains('ağustos') || str.contains('agustos')) {
        month = 8;
      } else if (str.contains('eylül') || str.contains('eylul')) {
        month = 9;
      } else if (str.contains('ekim')) {
        month = 10;
      } else if (str.contains('kasım') || str.contains('kasim')) {
        month = 11;
      } else if (str.contains('aralık') || str.contains('aralik')) {
        month = 12;
      }

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.userRole.trim().toLowerCase() == 'admin';

    Widget kitaplarSekmesi = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('okunan_kitaplar')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var kitaplar = snapshot.data!.docs;
        int toplamKitap = kitaplar.length;
        int toplamSayfa = 0;
        for (var doc in kitaplar) {
          toplamSayfa += (doc['sayfaSayisi'] as num).toInt();
        }
        String mevcutUnvan = Oyunlastirma.getUnvan(toplamSayfa);
        String mevcutOdul = Oyunlastirma.getOdul(toplamSayfa);

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sınıf No: ${widget.studentData['schoolNumber'] ?? 'Belirtilmemiş'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _istatistikWidget("Kitap", "$toplamKitap"),
                        _istatistikWidget("Sayfa", "$toplamSayfa"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          "Ünvan: $mevcutUnvan",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Ödül: $mevcutOdul",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Okunan Kitaplar:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: kitaplar.length,
                itemBuilder: (context, index) {
                  var doc = kitaplar[index];
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.indigo),
                    title: Text(doc['kitapAdi']),
                    trailing: Text("${doc['sayfaSayisi']} Sayfa"),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    Widget odevTakipSekmesi = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('odevler')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Bu öğrenciye henüz ödev verilmemiş."),
          );
        }

        var odevler = List.from(snapshot.data!.docs);
        odevler.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          String tarihA = dataA['tarihStr'] ?? '';
          String tarihB = dataB['tarihStr'] ?? '';

          DateTime? dtA = _parseTurkishDate(tarihA);
          DateTime? dtB = _parseTurkishDate(tarihB);

          if (dtA == null && dtB == null) return 0;
          if (dtA == null) return 1;
          if (dtB == null) return -1;

          return dtB.compareTo(dtA);
        });

        int toplamOdevKitabi = 0;
        int yapilanOdevKitabi = 0;
        int reddedilenOdevKitabi = 0;
        int bekleyenOdevKitabi = 0;

        for (var doc in odevler) {
          var data = doc.data() as Map<String, dynamic>;
          List kitaplar = data['kitaplar'] ?? [];

          for (var k in kitaplar) {
            toplamOdevKitabi++;
            String kDurum = k['durum'] ?? 'bekliyor';
            if (kDurum == 'yapildi') {
              yapilanOdevKitabi++;
            } else if (kDurum == 'ogretmen_reddi') {
              reddedilenOdevKitabi++;
            } else {
              bekleyenOdevKitabi++;
            }
          }
        }

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _istatistikWidget("Toplam", "$toplamOdevKitabi"),
                    _istatistikWidget(
                      "Yapılan",
                      "$yapilanOdevKitabi",
                      renk: Colors.green,
                    ),
                    _istatistikWidget(
                      "Bekleyen",
                      "$bekleyenOdevKitabi",
                      renk: Colors.orange,
                    ),
                    _istatistikWidget(
                      "Reddedilen",
                      "$reddedilenOdevKitabi",
                      renk: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ödev Durumları (Öğretmen Kontrolü):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: odevler.length,
                itemBuilder: (context, index) {
                  var odevDoc = odevler[index];
                  var odevData = odevDoc.data() as Map<String, dynamic>;

                  String tarihStr = odevData['tarihStr'] ?? '';
                  List kitaplar = odevData['kitaplar'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey<String>(odevDoc.id),
                      title: Text(
                        tarihStr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Ödev Kitapları Detaylı Takibi",
                        style: TextStyle(fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...kitaplar.asMap().entries.map((entry) {
                                int kIndex = entry.key;
                                var k = entry.value;

                                String kAd = k['kitapAdi'] ?? '';
                                String kSayfa = k['sayfaAraligi'] ?? '';
                                String kAciklama = k['aciklama'] ?? '';
                                String kDurum = k['durum'] ?? 'bekliyor';

                                Color itemRengi = Colors.black87;
                                String durumAciklama = "Bekliyor";

                                if (kDurum == 'yapildi') {
                                  itemRengi = Colors.green;
                                  durumAciklama = "Öğrenci Yaptı (Yeşil)";
                                } else if (kDurum == 'ogretmen_reddi') {
                                  itemRengi = Colors.red;
                                  durumAciklama =
                                      "Yapılmadı olarak kilitlendi (Kırmızı)";
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: itemRengi.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: itemRengi.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "• $kAd (Sayfa: $kSayfa)",
                                              style: TextStyle(
                                                color: itemRengi,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (kAciklama.isNotEmpty)
                                              Text(
                                                "Yönerge: $kAciklama",
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Durum: $durumAciklama",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: itemRengi,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      isAdmin
                                          ? const SizedBox.shrink()
                                          : IconButton(
                                              icon: Icon(
                                                kDurum == 'ogretmen_reddi'
                                                    ? Icons.lock
                                                    : Icons.lock_open,
                                                color: itemRengi,
                                              ),
                                              tooltip:
                                                  "Bu Ödev Kitabını Kırmızı Yap / Kilitle",
                                              onPressed: () =>
                                                  _ogretmenOdevKitabiDurumGuncelle(
                                                    context,
                                                    odevDoc.id,
                                                    kitaplar,
                                                    kIndex,
                                                  ),
                                            ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    String baslikStr =
        "${widget.studentData['firstName'] ?? ''} ${widget.studentData['lastName'] ?? ''} - ${widget.initialTabIndex == 0 ? "Kitaplar & Özet" : "Ödev Takibi"}";

    return Scaffold(
      appBar: AppBar(
        title: Text(baslikStr),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: widget.initialTabIndex == 0 ? kitaplarSekmesi : odevTakipSekmesi,
    );
  }

  Widget _istatistikWidget(String baslik, String deger, {Color? renk}) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: renk ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
