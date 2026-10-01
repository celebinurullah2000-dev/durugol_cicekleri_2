// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DersKitaplariScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String userRole;
  final String? ogretmenSinifSeviyesi;

  const DersKitaplariScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.userRole,
    this.ogretmenSinifSeviyesi,
  });

  @override
  State<DersKitaplariScreen> createState() => _DersKitaplariScreenState();
}

class _DersKitaplariScreenState extends State<DersKitaplariScreen>
    with SingleTickerProviderStateMixin {
  bool _isMaster = false;
  late TabController _tabController;

  final List<String> _siniflar = [
    "1. Sınıf",
    "2. Sınıf",
    "3. Sınıf",
    "4. Sınıf",
  ];

  @override
  void initState() {
    super.initState();
    _masterDurumunuKontrolEt();
    _tabController = TabController(length: _siniflar.length, vsync: this);

    // Eğer öğretmen sınıf seviyesi varsa ilgili sekmeyi aç
    if (widget.ogretmenSinifSeviyesi != null) {
      String temizSinif = widget.ogretmenSinifSeviyesi!.trim();
      if (!temizSinif.contains("Sınıf")) {
        temizSinif = "$temizSinif. Sınıf";
      }
      int index = _siniflar.indexOf(temizSinif);
      if (index != -1) {
        _tabController.index = index;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _masterDurumunuKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMaster = prefs.getBool('isMaster') ?? false;
    });
  }

  // Türkçe karakter duyarlı alfabetik sıralama fonksiyonu
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

  // Kitap / Link Ekleme Penceresi
  void _linkEkleDialog(BuildContext context) {
    String secilenSinif = _siniflar[_tabController.index];
    final TextEditingController baslikController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Yeni Ders Kitabı / Link Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: secilenSinif,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Sınıf Seviyesi",
                    border: OutlineInputBorder(),
                  ),
                  items: _siniflar
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        secilenSinif = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(
                    labelText: "Ders Adı / Kitap Adı (Örn: Türkçe Ders Kitabı)",
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String baslik = baslikController.text.trim();
                String url = urlController.text.trim();

                if (baslik.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lütfen tüm alanları doldurun."),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('ders_kitaplari')
                    .add({
                      'sinif': secilenSinif,
                      'baslik': baslik,
                      'url': url,
                      'authorId': widget.currentUserId,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kitap linki başarıyla eklendi!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  void _linkSil(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Sil"),
        content: const Text(
          "Bu ders kitabı bağlantısını silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('ders_kitaplari')
                  .doc(docId)
                  .delete();
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Future<void> _linkAc(String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bağlantı açılamadı.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSinifOgretmeni = (widget.userRole == 'classroom_teacher');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ders Kitapları & Kaynaklar"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: _siniflar.map((sinif) => Tab(text: sinif)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _siniflar.map((sinifSeviyesi) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ders_kitaplari')
                .where('sinif', isEqualTo: sinifSeviyesi)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.hasData ? List.from(snapshot.data!.docs) : [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    "$sinifSeviyesi için henüz eklenmiş ders kitabı yok.",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                );
              }

              // TÜRKÇE ALFABETİK SIRALAMA
              docs.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;

                String baslikA = dataA['baslik'] ?? '';
                String baslikB = dataB['baslik'] ?? '';

                return _turkceKarsilastir(baslikA, baslikB);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String docId = doc.id;
                  String baslik = data['baslik'] ?? '';
                  String urlStr = data['url'] ?? '';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.book, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text(
                              "Git",
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _linkAc(urlStr),
                          ),
                          // Sınıf öğretmeni veya Master hesaplar silebilir
                          if (isSinifOgretmeni || _isMaster) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: "Kitabı Sil",
                              onPressed: () => _linkSil(context, docId),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
      // LİNK EKLEME BUTONU (Sınıf Öğretmeni veya Master görebilir)
      floatingActionButton: (isSinifOgretmeni || _isMaster)
          ? FloatingActionButton.extended(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Kitap Linki Ekle"),
              onPressed: () => _linkEkleDialog(context),
            )
          : null,
    );
  }
}
