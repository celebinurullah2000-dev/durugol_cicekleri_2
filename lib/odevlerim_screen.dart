// ignore_for_file: avoid_print

import 'package:durugol_cicekleri/istatistik_servisi.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OdevlerimScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const OdevlerimScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<OdevlerimScreen> createState() => _OdevlerimScreenState();
}

class _OdevlerimScreenState extends State<OdevlerimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kitapOdevleriniOkunduIsaretle();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          IstatistikServisi.islemKaydet(
            studentId: widget.studentId,
            islemTuru: 'odevlerim_sekmesi',
          );
          _kitapOdevleriniOkunduIsaretle();
        } else if (_tabController.index == 1) {
          IstatistikServisi.islemKaydet(
            studentId: widget.studentId,
            islemTuru: 'gorevlerim_sekmesi',
          );
          _sinifIsleriniOkunduIsaretle();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _kitapOdevleriniOkunduIsaretle() async {
    try {
      var odevlerSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('odevler')
          .get();

      for (var doc in odevlerSnapshot.docs) {
        var data = doc.data();
        if (data['okundu'] != true) {
          await doc.reference.update({'okundu': true});
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Kitap ödevleri okundu işaretleme hatası: $e");
    }
  }

  Future<void> _sinifIsleriniOkunduIsaretle() async {
    try {
      var sinifIsleriSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('sinif_isleri')
          .get();

      for (var doc in sinifIsleriSnapshot.docs) {
        String isId = doc.id;
        var veriRef = FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .collection('is_verileri')
            .doc(isId);

        var veriSnap = await veriRef.get();
        if (!veriSnap.exists) {
          await veriRef.set({
            'deger': '-',
            'okundu': true,
          }, SetOptions(merge: true));
        } else {
          var data = veriSnap.data() as Map<String, dynamic>;
          if (data['okundu'] != true) {
            await veriRef.update({'okundu': true});
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Sınıf işleri okundu işaretleme hatası: $e");
    }
  }

  Future<void> _odevKitabiDurumGuncelle(
    BuildContext context,
    String odevId,
    List mevcutKitaplar,
    int index,
  ) async {
    Map<String, dynamic> secilenKitap = Map.from(mevcutKitaplar[index]);
    String mevcutDurum = secilenKitap['durum'] ?? 'bekliyor';

    if (mevcutDurum == 'ogretmen_reddi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bu ödev kitabı öğretmeniniz tarafından kilitlendiği için değiştirilemez!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    secilenKitap['durum'] = (mevcutDurum == 'yapildi') ? 'bekliyor' : 'yapildi';
    mevcutKitaplar[index] = secilenKitap;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .collection('odevler')
        .doc(odevId)
        .update({'kitaplar': mevcutKitaplar});

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ödevlerim ve Etkinliklerim"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .doc(widget.studentId)
                    .collection('odevler')
                    .snapshots(),
                builder: (context, snapshot) {
                  int okunmamisOdevSayisi = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      if (data['okundu'] != true) {
                        okunmamisOdevSayisi++;
                      }
                    }
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book, size: 20),
                      const SizedBox(width: 8),
                      const Text("Ödevlerim"),
                      if (okunmamisOdevSayisi > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$okunmamisOdevSayisi",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('sinif_isleri')
                    .snapshots(),
                builder: (context, sinifIsleriSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .doc(widget.studentId)
                        .collection('is_verileri')
                        .snapshots(),
                    builder: (context, ogrenciVeriSnap) {
                      int okunmamisSayisi = 0;

                      if (sinifIsleriSnap.hasData && ogrenciVeriSnap.hasData) {
                        var tumIsler = sinifIsleriSnap.data!.docs;
                        var ogrenciVerileri = {
                          for (var d in ogrenciVeriSnap.data!.docs)
                            d.id: d.data(),
                        };

                        for (var isDoc in tumIsler) {
                          String isId = isDoc.id;
                          var veri =
                              ogrenciVerileri[isId] as Map<String, dynamic>?;

                          if (veri == null || veri['okundu'] != true) {
                            okunmamisSayisi++;
                          }
                        }
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment, size: 20),
                          const SizedBox(width: 8),
                          const Text("Görevlerim"),
                          if (okunmamisSayisi > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$okunmamisSayisi",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKitapOdevleriView(), _buildSinifIsleriView()],
      ),
    );
  }

  Widget _buildKitapOdevleriView() {
    return StreamBuilder<QuerySnapshot>(
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
            child: Text(
              "Henüz verilmiş bir kitap ödeviniz yok.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final odevler = snapshot.data!.docs;

        return ListView.builder(
          itemCount: odevler.length,
          itemBuilder: (context, index) {
            var odevDoc = odevler[index];
            var odevData = odevDoc.data() as Map<String, dynamic>;

            String tarihStr = odevData['tarihStr'] ?? 'Tarih Belirtilmemiş';
            List kitaplar = odevData['kitaplar'] ?? [];

            bool tumuYapildi =
                kitaplar.isNotEmpty &&
                kitaplar.every((k) => k['durum'] == 'yapildi');
            bool herhangiRed = kitaplar.any(
              (k) => k['durum'] == 'ogretmen_reddi',
            );

            Color kartRengi = Colors.black87;
            if (tumuYapildi) kartRengi = Colors.green;
            if (herhangiRed) kartRengi = Colors.red;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  tarihStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kartRengi,
                  ),
                ),
                subtitle: Text(
                  herhangiRed
                      ? "Durum: Kilitli ödevleriniz var"
                      : (tumuYapildi
                            ? "Durum: Tüm ödevler tamamlandı"
                            : "Durum: Bekleyen ödevleriniz var"),
                  style: TextStyle(color: kartRengi, fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bu Tarihteki Ödev Kitapları ve Yönergeler:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...kitaplar.asMap().entries.map((entry) {
                          int kIndex = entry.key;
                          var k = entry.value;

                          String kAd = k['kitapAdi'] ?? '';
                          String kSayfa = k['sayfaAraligi'] ?? '';
                          String kAciklama = k['aciklama'] ?? '';
                          String kDurum = k['durum'] ?? 'bekliyor';

                          Color itemRengi = Colors.black87;
                          IconData itemIcon = Icons.radio_button_unchecked;
                          String durumAciklama =
                              "Yapılmadı (İşaretlemek için dokun)";

                          if (kDurum == 'yapildi') {
                            itemRengi = Colors.green;
                            itemIcon = Icons.check_circle;
                            durumAciklama = "Yapıldı (Tebrikler!)";
                          } else if (kDurum == 'ogretmen_reddi') {
                            itemRengi = Colors.red;
                            itemIcon = Icons.lock;
                            durumAciklama =
                                "Öğretmeniniz tarafından kilitlendi!";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: itemRengi.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: itemRengi.withValues(alpha: 0.3),
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
                                        "$kAd (Sayfa: $kSayfa)",
                                        style: TextStyle(
                                          color: itemRengi,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (kAciklama.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            "Yönerge: $kAciklama",
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        durumAciklama,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: itemRengi,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    itemIcon,
                                    color: itemRengi,
                                    size: 28,
                                  ),
                                  onPressed: () => _odevKitabiDurumGuncelle(
                                    context,
                                    odevDoc.id,
                                    kitaplar,
                                    kIndex,
                                  ),
                                  tooltip: kDurum == 'ogretmen_reddi'
                                      ? "Bu ödev kilitlidir"
                                      : "Bu Ödev Kitabını İşaretle",
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
        );
      },
    );
  }

  Widget _buildSinifIsleriView() {
    if (widget.classId.isEmpty) {
      return const Center(
        child: Text(
          "Sınıf bilgisi bulunamadı.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
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
              "Henüz öğretmeniniz tarafından eklenmiş bir sınıf işi/etkinlik yok.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
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

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('is_verileri')
                  .doc(isId)
                  .get(),
              builder: (context, veriSnap) {
                String deger = '-';
                if (veriSnap.hasData && veriSnap.data!.exists) {
                  var vData = veriSnap.data!.data() as Map<String, dynamic>;
                  deger = vData['deger'] ?? '-';
                }

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: durumRengi.withValues(alpha: 0.15),
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
    );
  }
}
