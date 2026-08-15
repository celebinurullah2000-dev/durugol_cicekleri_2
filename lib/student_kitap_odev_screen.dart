import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils.dart';

class StudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  final String userRole; // <-- 1. Rol parametresi eklendi

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.studentId,
    this.userRole = 'classroom_teacher', // Varsayılan değer
  });

  // Öğretmenin öğrenci ödev durumunu değiştirmesi için fonksiyon (Kırmızı kilitleme / Yeşil yapma)
  Future<void> _ogretmenOdevKitabiDurumGuncelle(
    BuildContext context,
    String odevId,
    List mevcutKitaplar,
    int index,
  ) async {
    Map<String, dynamic> secilenKitap = Map.from(mevcutKitaplar[index]);
    String mevcutDurum = secilenKitap['durum'] ?? 'bekliyor';

    // Kırmızı değilse kırmızı yap, kırmızıysa beklipora çevir
    secilenKitap['durum'] = (mevcutDurum == 'ogretmen_reddi')
        ? 'bekliyor'
        : 'ogretmen_reddi';
    mevcutKitaplar[index] = secilenKitap;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .collection('odevler')
        .doc(odevId)
        .update({'kitaplar': mevcutKitaplar});
  }

  @override
  Widget build(BuildContext context) {
    // Yönetici (admin) mi kontrolü
    bool isAdmin = userRole == 'admin';

    return DefaultTabController(
      length: 2, // 2 Sekme: 1. Okunan Kitaplar, 2. Ödevler & Takip
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "${studentData['firstName']} ${studentData['lastName']} - Detaylar",
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.book), text: "Kitaplar & Özet"),
              Tab(icon: Icon(Icons.assignment), text: "Ödev Takibi"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- 1. SEKME: KİTAPLAR VE MEVCUT ÖZET ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
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
                              "Sınıf No: ${studentData['schoolNumber'] ?? 'Belirtilmemiş'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Şifre: ${studentData['password'] ?? 'Tanımlanmamış'}",
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                            leading: const Icon(
                              Icons.book,
                              color: Colors.indigo,
                            ),
                            title: Text(doc['kitapAdi']),
                            trailing: Text("${doc['sayfaSayisi']} Sayfa"),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            // --- 2. SEKME: ÖDEVLER VE ÖĞRETMEN DENETİM EKRANI ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
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

                var odevler = snapshot.data!.docs;

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                "Ödev Kitapları Detaylı Takibi",
                                style: TextStyle(fontSize: 12),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...kitaplar.asMap().entries.map((entry) {
                                        int kIndex = entry.key;
                                        var k = entry.value;

                                        String kAd = k['kitapAdi'] ?? '';
                                        String kSayfa = k['sayfaAraligi'] ?? '';
                                        String kAciklama = k['aciklama'] ?? '';
                                        String kDurum =
                                            k['durum'] ?? 'bekliyor';

                                        Color itemRengi = Colors.black87;
                                        String durumAciklama = "Bekliyor";

                                        if (kDurum == 'yapildi') {
                                          itemRengi = Colors.green;
                                          durumAciklama =
                                              "Öğrenci Yaptı (Yeşil)";
                                        } else if (kDurum == 'ogretmen_reddi') {
                                          itemRengi = Colors.red;
                                          durumAciklama =
                                              "Yapılmadı olarak kilitlendi (Kırmızı)";
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: itemRengi.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: itemRengi.withValues(
                                                alpha: 0.2,
                                              ),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (kAciklama.isNotEmpty)
                                                      Text(
                                                        "Yönerge: $kAciklama",
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "Durum: $durumAciklama",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: itemRengi,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // --- 2. Kilit Butonu Rol Kontrolü ---
                                              // Eğer kullanıcı 'admin' ise buton gizlenir (SizedBox.shrink),
                                              // değilse sınıf/branş öğretmenine görünür ve çalışır.
                                              isAdmin
                                                  ? const SizedBox.shrink()
                                                  : IconButton(
                                                      icon: Icon(
                                                        kDurum ==
                                                                'ogretmen_reddi'
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
            ),
          ],
        ),
      ),
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
