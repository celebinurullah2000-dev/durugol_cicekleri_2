// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FaydaliLinklerScreen extends StatelessWidget {
  final String userRole;
  final String currentUserName;
  final String currentUserId;

  const FaydaliLinklerScreen({
    super.key,
    required this.userRole,
    required this.currentUserName,
    required this.currentUserId,
  });

  // Sabit kategoriler
  final List<String> _sabitKategoriler = const [
    "Ders Videoları ve Konu Anlatımları",
    "Rehberlik ve Davranış Eğitimi",
    "Dijital Kütüphane ve Ders Kitapları",
    "Faydalı Web Siteleri ve Eğitim Portalları",
    "Sosyal Sorumluluk ve Projeler",
    "Eğitici ve İlginç Bilgiler",
    "Etkinlik ve Hobi Köşesi",
    "Sınav ve Test Merkezi",
    "Duyurular ve Okul İçi Etkinlikler",
    "Veliler İçin Rehberlik",
  ];

  // Rolleri okunabilir ana başlık isimlerine çevirme
  String _getRolBasligi(String rol) {
    switch (rol) {
      case 'admin':
        return "Okul İdaresi Paylaşımları";
      case 'guidance_teacher':
        return "Rehberlik Servisi Paylaşımları";
      case 'english_teacher':
        return "İngilizce Öğretmeni Paylaşımları";
      case 'religious_teacher':
        return "Din Kültürü Öğretmeni Paylaşımları";
      case 'classroom_teacher':
        return "Sınıf Öğretmeni Paylaşımları";
      case 'branch_teacher':
        return "Branş Öğretmeni Paylaşımları";
      case 'student':
        return "Öğrenci Paylaşımları";
      default:
        return "Diğer Paylaşımlar";
    }
  }

  IconData _getRolIkonu(String rol) {
    switch (rol) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'guidance_teacher':
        return Icons.support_agent;
      case 'english_teacher':
      case 'religious_teacher':
      case 'classroom_teacher':
      case 'branch_teacher':
        return Icons.school;
      case 'student':
        return Icons.face;
      default:
        return Icons.folder;
    }
  }

  Color _getRolRengi(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.purple;
      case 'guidance_teacher':
        return Colors.teal;
      case 'english_teacher':
        return Colors.indigo;
      case 'religious_teacher':
        return Colors.deepOrange;
      case 'classroom_teacher':
        return Colors.blue;
      case 'branch_teacher':
        return Colors.cyan;
      default:
        return Colors.orange;
    }
  }

  // İçerik Oluşturma ve Düzenleme Penceresi
  void _linkEkleDuzenleDialog(
    BuildContext context, {
    String? docId,
    String? mevcutBaslik,
    String? mevcutUrl,
    String? mevcutKategori,
  }) {
    final TextEditingController baslikController = TextEditingController(
      text: mevcutBaslik ?? '',
    );
    final TextEditingController urlController = TextEditingController(
      text: mevcutUrl ?? '',
    );

    // Kategori seçimi veya yeni kategori ekleme için
    ValueNotifier<String> secilenKategori = ValueNotifier<String>(
      mevcutKategori ?? _sabitKategoriler.first,
    );
    final TextEditingController yeniKategoriController =
        TextEditingController();
    ValueNotifier<bool> yeniKategoriModu = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          docId == null ? "Yeni Bağlantı Paylaş" : "Paylaşımı Düzenle",
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baslikController,
                decoration: const InputDecoration(
                  labelText: "Bağlantı Konusu / Başlığı",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: "İnternet Bağlantı Linki (https://...)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Kategori Seçimi ve Yeni Kategori Ekleme
              ValueListenableBuilder<bool>(
                valueListenable: yeniKategoriModu,
                builder: (context, yeniMod, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!yeniMod) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<String>(
                                valueListenable: secilenKategori,
                                builder: (context, katVal, child) {
                                  return DropdownButtonFormField<String>(
                                    initialValue:
                                        _sabitKategoriler.contains(katVal)
                                        ? katVal
                                        : _sabitKategoriler.first,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: "Kategori Seçin",
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _sabitKategoriler.map((kat) {
                                      return DropdownMenuItem(
                                        value: kat,
                                        child: Text(
                                          kat,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        secilenKategori.value = val;
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Listede yoksa yeni kategori ekle"),
                          onPressed: () => yeniKategoriModu.value = true,
                        ),
                      ] else ...[
                        TextField(
                          controller: yeniKategoriController,
                          decoration: const InputDecoration(
                            labelText: "Yeni Kategori Adı Girin",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.list, size: 16),
                          label: const Text("Mevcut kategorilerden seç"),
                          onPressed: () => yeniKategoriModu.value = false,
                        ),
                      ],
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
              String url = urlController.text.trim();
              String kategori = yeniKategoriModu.value
                  ? yeniKategoriController.text.trim()
                  : secilenKategori.value;

              if (baslik.isEmpty || url.isEmpty || kategori.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Lütfen tüm alanları doldurun."),
                  ),
                );
                return;
              }

              Map<String, dynamic> veriMap = {
                'title': baslik,
                'url': url,
                'category': kategori,
                'role': userRole,
                'authorName': currentUserName,
                'authorId': currentUserId,
              };

              if (docId == null) {
                veriMap['timestamp'] = FieldValue.serverTimestamp();
                veriMap['views'] = []; // Tekil görüntüleme ID'leri
                veriMap['clicks'] =
                    []; // Tekil tıklama ID'leri ve toplam sayaç için
                await FirebaseFirestore.instance
                    .collection('useful_links')
                    .add(veriMap);
              } else {
                await FirebaseFirestore.instance
                    .collection('useful_links')
                    .doc(docId)
                    .update(veriMap);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bağlantı başarıyla paylaşıldı!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Paylaş"),
          ),
        ],
      ),
    );
  }

  void _linkSil(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paylaşımı Sil"),
        content: const Text("Bu bağlantıyı silmek istediğinize emin misiniz?"),
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
                  .collection('useful_links')
                  .doc(docId)
                  .delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Paylaşım silindi.")),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tekil Görüntüleme Kaydı
  Future<void> _goruntlenmeKaydet(String docId, List views) async {
    if (!views.contains(currentUserId)) {
      List yeniViews = List.from(views);
      yeniViews.add(currentUserId);
      await FirebaseFirestore.instance
          .collection('useful_links')
          .doc(docId)
          .update({'views': yeniViews});
    }
  }

  // Tekil Tıklama ve Toplam Tıklama Kaydı
  Future<void> _tiklamaKaydetVeAc(
    String docId,
    String urlStr,
    List clicks,
  ) async {
    List yeniClicks = List.from(clicks);
    if (!yeniClicks.contains(currentUserId)) {
      yeniClicks.add(currentUserId); // Tekil kullanıcı takibi için ID eklenir
    }
    // Toplam tıklama için her basıldığında bir öğe daha eklenir veya sayaç tutulur
    yeniClicks.add("click_${DateTime.now().millisecondsSinceEpoch}");

    await FirebaseFirestore.instance
        .collection('useful_links')
        .doc(docId)
        .update({'clicks': yeniClicks});

    final Uri url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faydalı Bağlantılar & Kaynaklar"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('useful_links')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.hasData ? snapshot.data!.docs : [];

          // Roller bazında gruplama (Ana Başlıklar)
          Map<String, List<QueryDocumentSnapshot>> rolGruplari = {};
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String rol = data['role'] ?? 'other';
            if (!rolGruplari.containsKey(rol)) {
              rolGruplari[rol] = [];
            }
            rolGruplari[rol]!.add(doc);
          }

          // Öncelikli rol sıralaması
          List<String> rolSirasi = [
            'admin',
            'guidance_teacher',
            'english_teacher',
            'religious_teacher',
            'classroom_teacher',
            'branch_teacher',
            'student',
          ];

          List<String> aktifRoller = rolSirasi
              .where((r) => rolGruplari.containsKey(r))
              .toList();
          for (var r in rolGruplari.keys) {
            if (!aktifRoller.contains(r)) aktifRoller.add(r);
          }

          if (aktifRoller.isEmpty) {
            return const Center(
              child: Text(
                "Henüz hiç bağlantı paylaşılmamış.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: aktifRoller.map((rol) {
              var rolDuyurulari = rolGruplari[rol]!;
              String anaBaslik = _getRolBasligi(rol);
              IconData ikon = _getRolIkonu(rol);
              Color renk = _getRolRengi(rol);

              // Bu rolün altındaki kategorileri gruplama
              Map<String, List<QueryDocumentSnapshot>> kategoriGruplari = {};
              for (var doc in rolDuyurulari) {
                var data = doc.data() as Map<String, dynamic>;
                String kat = data['category'] ?? 'Genel';
                if (!kategoriGruplari.containsKey(kat)) {
                  kategoriGruplari[kat] = [];
                }
                kategoriGruplari[kat]!.add(doc);
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: renk.withValues(alpha: 0.1),
                    child: Icon(ikon, color: renk),
                  ),
                  title: Text(
                    anaBaslik,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: renk,
                    ),
                  ),
                  subtitle: Text("${rolDuyurulari.length} kaynak paylaşıldı"),
                  children: [
                    ...kategoriGruplari.entries.map((entry) {
                      String kategoriAdi = entry.key;
                      var kategoriLinkleri = entry.value;

                      return ExpansionTile(
                        onExpansionChanged: (isOpen) {
                          if (isOpen) {
                            // Kategori açıldığı an bu kategorideki tüm linkler okundu/görüntülendi sayılır
                            for (var doc in kategoriLinkleri) {
                              var data = doc.data() as Map<String, dynamic>;
                              List views = data['views'] ?? [];
                              _goruntlenmeKaydet(doc.id, views);
                            }
                          }
                        },
                        title: Text(
                          kategoriAdi,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text("${kategoriLinkleri.length} bağlantı"),
                        children: kategoriLinkleri.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          String baslik = data['title'] ?? '';
                          String urlStr = data['url'] ?? '';
                          String authorName =
                              data['authorName'] ?? 'Bilinmiyor';
                          String authorId = data['authorId'] ?? '';
                          List views = data['views'] ?? [];
                          List clicks = data['clicks'] ?? [];

                          // Tekil tıklama sayısını hesaplama (ID içerenler) ve toplam tıklama
                          Set<String> tekilTiklayanlar = {};
                          int toplamTiklama = 0;
                          for (var item in clicks) {
                            toplamTiklama++;
                            if (item is String && !item.startsWith('click_')) {
                              tekilTiklayanlar.add(item);
                            }
                          }

                          bool benimPaylasimim = (authorId == currentUserId);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TEK VE DÜZGÜN BAŞLIK (Uzun olduğunda alt satırlara kayar)
                                Text(
                                  baslik,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // BUTONLAR VE İŞLEMLER (Sağa dayalı)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        "Git",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        _goruntlenmeKaydet(docId, views);
                                        _tiklamaKaydetVeAc(
                                          docId,
                                          urlStr,
                                          clicks,
                                        );
                                      },
                                    ),
                                    if (benimPaylasimim) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _linkEkleDuzenleDialog(
                                          context,
                                          docId: docId,
                                          mevcutBaslik: baslik,
                                          mevcutUrl: urlStr,
                                          mevcutKategori: kategoriAdi,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () =>
                                            _linkSil(context, docId),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Divider(height: 8),

                                // BİLGİ NOTLARI (Taşmaları önlemek için Flexible eklendi)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Paylaşan: $authorName",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Görüntüleme: ${views.length} | Tıklama: $toplamTiklama (Tekil: ${tekilTiklayanlar.length})",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      // Yeni bağlantı ekleme butonu
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_link),
        label: const Text("Bağlantı Paylaş"),
        onPressed: () => _linkEkleDuzenleDialog(context),
      ),
    );
  }
}
