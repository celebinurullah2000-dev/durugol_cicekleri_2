// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DuyurularScreen extends StatelessWidget {
  final String
  userRole; // 'admin', 'guidance_teacher', 'classroom_teacher', 'student' vb.
  final String currentUserName; // Yayınlayan kişinin gerçek adı veya unvanı

  const DuyurularScreen({
    super.key,
    required this.userRole,
    required this.currentUserName,
  });

  void _duyuruDialogGoster(
    BuildContext context, {
    String? docId,
    String? mevcutBaslik,
    String? mevcutIcerik,
    String? mevcutBaslangicTarihi,
    String? mevcutBitisTarihi,
    required String kategori,
  }) {
    final TextEditingController baslikController = TextEditingController(
      text: mevcutBaslik ?? '',
    );
    final TextEditingController icerikController = TextEditingController(
      text: mevcutIcerik ?? '',
    );

    ValueNotifier<String?> baslangicTarihiNotifier = ValueNotifier<String?>(
      mevcutBaslangicTarihi,
    );
    ValueNotifier<String?> bitisTarihiNotifier = ValueNotifier<String?>(
      mevcutBitisTarihi,
    );

    bool yetkiliMi = false;
    if (userRole == 'admin' &&
        (kategori == 'okul_idaresi' || kategori == 'diger')) {
      yetkiliMi = true;
    } else if (userRole == 'guidance_teacher' && kategori == 'rehberlik') {
      yetkiliMi = true;
    }

    if (!yetkiliMi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu kategoride duyuru ekleme yetkiniz yok!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(docId == null ? "Yeni Duyuru Ekle" : "Duyuruyu Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baslikController,
                decoration: const InputDecoration(
                  labelText: "Duyuru Başlığı",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: icerikController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Duyuru İçeriği",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Başlangıç Tarihi Seçimi
              ValueListenableBuilder<String?>(
                valueListenable: baslangicTarihiNotifier,
                builder: (context, baslangicVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          baslangicVal == null || baslangicVal.isEmpty
                              ? "Başlangıç Tarihi Seçilmedi"
                              : "Başlangıç: $baslangicVal",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("Seç"),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            baslangicTarihiNotifier.value =
                                "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
                          }
                        },
                      ),
                      if (baslangicVal != null && baslangicVal.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => baslangicTarihiNotifier.value = null,
                        ),
                    ],
                  );
                },
              ),
              // Bitiş Tarihi Seçimi
              ValueListenableBuilder<String?>(
                valueListenable: bitisTarihiNotifier,
                builder: (context, bitisVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          bitisVal == null || bitisVal.isEmpty
                              ? "Bitiş Tarihi Seçilmedi"
                              : "Bitiş: $bitisVal",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("Seç"),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            bitisTarihiNotifier.value =
                                "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
                          }
                        },
                      ),
                      if (bitisVal != null && bitisVal.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => bitisTarihiNotifier.value = null,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String baslik = baslikController.text.trim();
              String icerik = icerikController.text.trim();

              if (baslik.isEmpty || icerik.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Lütfen başlık ve içerik alanlarını doldurun.",
                    ),
                  ),
                );
                return;
              }

              String yayinlayanIsim = currentUserName.trim().isNotEmpty
                  ? currentUserName
                  : (userRole == 'admin'
                        ? "Okul İdaresi"
                        : "Rehberlik Servisi");

              Map<String, dynamic> veriMap = {
                'title': baslik,
                'content': icerik,
                'category': kategori,
                'author': yayinlayanIsim,
                'startDate': baslangicTarihiNotifier.value,
                'endDate': bitisTarihiNotifier.value,
                'isManuallyEnded': false,
              };

              if (docId == null) {
                veriMap['timestamp'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance
                    .collection('announcements')
                    .add(veriMap);
              } else {
                await FirebaseFirestore.instance
                    .collection('announcements')
                    .doc(docId)
                    .update(veriMap);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Duyuru başarıyla kaydedildi!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _duyuruSil(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Duyuruyu Sil"),
        content: const Text("Bu duyuruyu silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(docId)
                  .delete();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Duyuru silindi.")));
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tarih metnini (GG.AA.YYYY) DateTime nesnesine çeviren yardımcı fonksiyon
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      List<String> parts = dateStr.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool adminEkleyebilir = (userRole == 'admin');
    bool rehberEkleyebilir = (userRole == 'guidance_teacher');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Duyurular Panosu"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.hasData ? snapshot.data!.docs : [];

          List okulIdaresiListesi = [];
          List rehberlikListesi = [];
          List digerDuyurularListesi = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String cat = data['category'] ?? 'diger';
            if (cat == 'okul_idaresi') {
              okulIdaresiListesi.add(doc);
            } else if (cat == 'rehberlik') {
              rehberlikListesi.add(doc);
            } else {
              digerDuyurularListesi.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildDuyuruKategoriKarti(
                context,
                baslik: "Okul İdaresi Duyuruları",
                ikon: Icons.admin_panel_settings,
                renk: Colors.purple,
                kategoriKey: 'okul_idaresi',
                duyuruListesi: okulIdaresiListesi,
                ekleyebilirMi: adminEkleyebilir,
              ),
              const SizedBox(height: 12),
              _buildDuyuruKategoriKarti(
                context,
                baslik: "Rehberlik Servisi Duyuruları",
                ikon: Icons.support_agent,
                renk: Colors.teal,
                kategoriKey: 'rehberlik',
                duyuruListesi: rehberlikListesi,
                ekleyebilirMi: rehberEkleyebilir,
              ),
              const SizedBox(height: 12),
              _buildDuyuruKategoriKarti(
                context,
                baslik: "Diğer Duyurular",
                ikon: Icons.announcement,
                renk: Colors.orange,
                kategoriKey: 'diger',
                duyuruListesi: digerDuyurularListesi,
                ekleyebilirMi: adminEkleyebilir,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDuyuruKategoriKarti(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required String kategoriKey,
    required List duyuruListesi,
    required bool ekleyebilirMi,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: renk.withValues(alpha: 0.1),
          child: Icon(ikon, color: renk),
        ),
        title: Text(
          baslik,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: renk,
          ),
        ),
        subtitle: Text("${duyuruListesi.length} duyuru aktif"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ekleyebilirMi)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: "Yeni Duyuru Ekle",
                onPressed: () {
                  _duyuruDialogGoster(context, kategori: kategoriKey);
                },
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (duyuruListesi.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Bu kategoride henüz duyuru bulunmuyor.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...duyuruListesi.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String title = data['title'] ?? '';
              String content = data['content'] ?? '';
              String author = data['author'] ?? 'Yönetim';
              String? startDate = data['startDate'];
              String? endDate = data['endDate'];
              bool isManuallyEnded = data['isManuallyEnded'] ?? false;

              Color? durumRengi;
              if (startDate != null || endDate != null) {
                if (isManuallyEnded) {
                  durumRengi = Colors.red;
                } else {
                  DateTime simdi = DateTime.now();
                  DateTime bugun = DateTime(simdi.year, simdi.month, simdi.day);

                  DateTime? bitisTarihi = _parseDate(endDate);

                  bool bittiMi = false;
                  if (bitisTarihi != null && bugun.isAfter(bitisTarihi)) {
                    bittiMi = true;
                  }

                  if (bittiMi) {
                    durumRengi = Colors.red;
                  } else {
                    durumRengi = Colors.green;
                  }
                }
              } else if (isManuallyEnded) {
                durumRengi = Colors.red;
              }

              bool islemYetkisi = ekleyebilirMi;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: renk.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (durumRengi != null) ...[
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: durumRengi,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (islemYetkisi)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (userRole == 'admin' &&
                                  kategoriKey == 'okul_idaresi' &&
                                  !isManuallyEnded)
                                IconButton(
                                  icon: const Icon(
                                    Icons.stop_circle,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  tooltip: "Etkinliği / Duyuruyu Sonlandır",
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('announcements')
                                        .doc(docId)
                                        .update({'isManuallyEnded': true});
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  _duyuruDialogGoster(
                                    context,
                                    docId: docId,
                                    mevcutBaslik: title,
                                    mevcutIcerik: content,
                                    mevcutBaslangicTarihi: startDate,
                                    mevcutBitisTarihi: endDate,
                                    kategori: kategoriKey,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _duyuruSil(context, docId),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(content, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    if ((startDate != null && startDate.isNotEmpty) ||
                        (endDate != null && endDate.isNotEmpty)) ...[
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (startDate != null && startDate.isNotEmpty)
                            Text(
                              "Başlangıç Tarihi: $startDate",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey,
                              ),
                            ),
                          if (endDate != null && endDate.isNotEmpty)
                            Text(
                              "Bitiş Tarihi: $endDate",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Yayınlayan: $author",
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
