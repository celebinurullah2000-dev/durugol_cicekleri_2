// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DuyurularScreen extends StatelessWidget {
  final String userRole;
  final String currentUserName;
  final String currentUserId;

  const DuyurularScreen({
    super.key,
    required this.userRole,
    required this.currentUserName,
    required this.currentUserId,
  });

  void _duyuruDialogGoster(
    BuildContext context, {
    String? docId,
    String? mevcutBaslik,
    String? mevcutIcerik,
    String? mevcutBaslangicTarihi,
    String? mevcutBitisTarihi,
    String? mevcutBaslangicSaati,
    String? mevcutBitisSaati,
    bool mevcutEtkilesim = false,
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
    ValueNotifier<String?> baslangicSaatiNotifier = ValueNotifier<String?>(
      mevcutBaslangicSaati,
    );
    ValueNotifier<String?> bitisSaatiNotifier = ValueNotifier<String?>(
      mevcutBitisSaati,
    );
    ValueNotifier<bool> etkilesimNotifier = ValueNotifier<bool>(
      mevcutEtkilesim,
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

              ValueListenableBuilder<bool>(
                valueListenable: etkilesimNotifier,
                builder: (context, etkilesimVal, child) {
                  return SwitchListTile(
                    title: const Text(
                      "Katılım İsteği (Etkileşim)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      "Öğrencilere 'Katılacağım' veya 'Katılmayacağım' seçeneği sunulur.",
                      style: TextStyle(fontSize: 11),
                    ),
                    value: etkilesimVal,
                    onChanged: (val) {
                      etkilesimNotifier.value = val;
                    },
                    activeThumbColor: Colors.indigo,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),

              const Divider(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Başlangıç Bilgileri (Zorunlu değil)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String?>(
                valueListenable: baslangicTarihiNotifier,
                builder: (context, baslangicVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          baslangicVal == null || baslangicVal.isEmpty
                              ? "Tarih seçilmedi"
                              : "Tarih: $baslangicVal",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text(
                          "Tarih Seç",
                          style: TextStyle(fontSize: 12),
                        ),
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
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () => baslangicTarihiNotifier.value = null,
                        ),
                    ],
                  );
                },
              ),
              ValueListenableBuilder<String?>(
                valueListenable: baslangicSaatiNotifier,
                builder: (context, saatVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          saatVal == null || saatVal.isEmpty
                              ? "Saat seçilmedi"
                              : "Saat: $saatVal",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 14),
                        label: const Text(
                          "Saat Seç",
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            baslangicSaatiNotifier.value =
                                "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                          }
                        },
                      ),
                      if (saatVal != null && saatVal.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () => baslangicSaatiNotifier.value = null,
                        ),
                    ],
                  );
                },
              ),

              const Divider(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bitiş Bilgileri (Zorunlu değil)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String?>(
                valueListenable: bitisTarihiNotifier,
                builder: (context, bitisVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          bitisVal == null || bitisVal.isEmpty
                              ? "Tarih seçilmedi"
                              : "Tarih: $bitisVal",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text(
                          "Tarih Seç",
                          style: TextStyle(fontSize: 12),
                        ),
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
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () => bitisTarihiNotifier.value = null,
                        ),
                    ],
                  );
                },
              ),
              ValueListenableBuilder<String?>(
                valueListenable: bitisSaatiNotifier,
                builder: (context, saatVal, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          saatVal == null || saatVal.isEmpty
                              ? "Saat seçilmedi"
                              : "Saat: $saatVal",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 14),
                        label: const Text(
                          "Saat Seç",
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            bitisSaatiNotifier.value =
                                "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                          }
                        },
                      ),
                      if (saatVal != null && saatVal.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () => bitisSaatiNotifier.value = null,
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
                'startTime': baslangicSaatiNotifier.value,
                'endDate': bitisTarihiNotifier.value,
                'endTime': bitisSaatiNotifier.value,
                'isInteractive': etkilesimNotifier.value,
                'isManuallyEnded': false,
              };

              if (docId == null) {
                veriMap['timestamp'] = FieldValue.serverTimestamp();
                veriMap['likes'] = [];
                veriMap['views'] = [];
                veriMap['readBy'] = [];
                veriMap['responses'] = {};
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

  Future<void> _duyuruyuOkunduVeGoruntulendiIsaretle(
    String docId,
    Map<String, dynamic> data,
  ) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('announcements')
        .doc(docId);

    List views = List.from(data['views'] ?? []);
    List readBy = List.from(data['readBy'] ?? []);

    bool guncelleGerekli = false;

    if (!views.contains(currentUserId)) {
      views.add(currentUserId);
      guncelleGerekli = true;
    }

    if (!readBy.contains(currentUserId)) {
      readBy.add(currentUserId);
      guncelleGerekli = true;
    }

    if (guncelleGerekli) {
      await docRef.update({'views': views, 'readBy': readBy});
    }
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
    int okunmamisSayisi = 0;
    for (var doc in duyuruListesi) {
      var data = doc.data() as Map<String, dynamic>;
      List readBy = data['readBy'] ?? [];
      if (!readBy.contains(currentUserId)) {
        okunmamisSayisi++;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: renk.withValues(alpha: 0.1),
              child: Icon(ikon, color: renk),
            ),
            if (okunmamisSayisi > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
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
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                baslik,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: renk,
                ),
              ),
            ),
            if (okunmamisSayisi > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  "$okunmamisSayisi okunmamış",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
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
              String? startTime = data['startTime'];
              String? endDate = data['endDate'];
              String? endTime = data['endTime'];
              bool isInteractive = data['isInteractive'] ?? false;
              bool isManuallyEnded = data['isManuallyEnded'] ?? false;

              List likes = data['likes'] ?? [];
              List views = data['views'] ?? [];
              List readBy = data['readBy'] ?? [];
              Map<String, dynamic> responses = Map<String, dynamic>.from(
                data['responses'] ?? {},
              );

              bool isLikedByMe = likes.contains(currentUserId);
              bool isReadByMe = readBy.contains(currentUserId);

              int katilacakSayisi = 0;
              int katilmayacakSayisi = 0;
              responses.forEach((key, value) {
                if (value == 'katilacak') katilacakSayisi++;
                if (value == 'katilmayacak') katilmayacakSayisi++;
              });

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

              String baslangicMetni = "";
              if (startDate != null && startDate.isNotEmpty) {
                baslangicMetni = "Başlangıç: $startDate";
                if (startTime != null && startTime.isNotEmpty) {
                  baslangicMetni += " $startTime";
                }
              }

              String bitisMetni = "";
              if (endDate != null && endDate.isNotEmpty) {
                bitisMetni = "Bitiş: $endDate";
                if (endTime != null && endTime.isNotEmpty) {
                  bitisMetni += " $endTime";
                }
              }

              // HER DUYURU İÇİN KENDİ İÇİNDE AÇILIR KAPANIR (ExpansionTile) YAPI
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isReadByMe
                      ? Colors.grey.shade50
                      : Colors.blue.shade50.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReadByMe
                        ? renk.withValues(alpha: 0.2)
                        : Colors.blue.shade300,
                    width: isReadByMe ? 1 : 1.5,
                  ),
                ),
                child: ExpansionTile(
                  onExpansionChanged: (isOpen) {
                    if (isOpen) {
                      _duyuruyuOkunduVeGoruntulendiIsaretle(docId, data);
                    }
                  },
                  leading: durumRengi != null
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: durumRengi,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const Icon(
                          Icons.notifications_active,
                          size: 18,
                          color: Colors.grey,
                        ),
                  // DÜZELTME BURADA YAPILDI: Row ve Expanded kaldırıldı, doğrudan Text verildi.
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isReadByMe
                          ? FontWeight.bold
                          : FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (islemYetkisi) ...[
                        if (userRole == 'admin' &&
                            kategoriKey == 'okul_idaresi' &&
                            !isManuallyEnded)
                          IconButton(
                            icon: const Icon(
                              Icons.stop_circle,
                              size: 18,
                              color: Colors.orange,
                            ),
                            tooltip: "Duyuruyu Sonlandır",
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
                              mevcutBaslangicSaati: startTime,
                              mevcutBitisTarihi: endDate,
                              mevcutBitisSaati: endTime,
                              mevcutEtkilesim: isInteractive,
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
                      const Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(content, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),

                          if (isInteractive) ...[
                            const Divider(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.indigo.shade100,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Katılım Durumu:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isLikedByMe
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              List yeniLikes = List.from(likes);
                                              if (isLikedByMe) {
                                                yeniLikes.remove(currentUserId);
                                              } else {
                                                yeniLikes.add(currentUserId);
                                              }
                                              await FirebaseFirestore.instance
                                                  .collection('announcements')
                                                  .doc(docId)
                                                  .update({'likes': yeniLikes});
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${likes.length}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // SAĞ TARAF: Taşmayı önlemek için Expanded ve Flexible eklendi
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Icon(
                                              Icons.visibility,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Gör: ${views.length}", // Metni biraz kısaltabiliriz veya aynı bırakabilirsiniz
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                "Yayınlayan: $author",
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Katılacaklar: $katilacakSayisi kişi",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        "Katılmayacaklar: $katilmayacakSayisi kişi",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (baslangicMetni.isNotEmpty ||
                              bitisMetni.isNotEmpty) ...[
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (baslangicMetni.isNotEmpty)
                                  Text(
                                    baslangicMetni,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (bitisMetni.isNotEmpty)
                                  Text(
                                    bitisMetni,
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
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLikedByMe
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      List yeniLikes = List.from(likes);
                                      if (isLikedByMe) {
                                        yeniLikes.remove(currentUserId);
                                      } else {
                                        yeniLikes.add(currentUserId);
                                      }
                                      await FirebaseFirestore.instance
                                          .collection('announcements')
                                          .doc(docId)
                                          .update({'likes': yeniLikes});
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${likes.length}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.visibility,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Görüntüleme: ${views.length}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Yayınlayan: $author",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
