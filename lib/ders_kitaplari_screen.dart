// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DersKitaplariScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String userRole; // Kullanıcının rolü (classroom_teacher, admin, vb.)
  final String?
  ogretmenSinifSeviyesi; // Sınıf öğretmeninin kendi sınıfı (Örn: "3. Sınıf")

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

class _DersKitaplariScreenState extends State<DersKitaplariScreen> {
  bool _isMaster = false;
  String? _secilenSinifFiltresi; // Arama/Listeleme için seçilen sınıf

  final List<String> _siniflar = [
    "1. Sınıf",
    "2. Sınıf",
    "3. Sınıf",
    "4. Sınıf",
  ];

  final Map<String, List<String>> _sinifDersleri = {
    "1. Sınıf": [
      "Türkçe",
      "Matematik",
      "Hayat Bilgisi",
      "Görsel Sanatlar",
      "Müzik",
      "Oyun ve Fiziki Etkinlikler",
    ],
    "2. Sınıf": [
      "Türkçe",
      "Matematik",
      "Hayat Bilgisi",
      "İngilizce",
      "Görsel Sanatlar",
      "Müzik",
    ],
    "3. Sınıf": [
      "Türkçe",
      "Matematik",
      "Hayat Bilgisi",
      "Fen Bilimleri",
      "İngilizce",
      "Din Kültürü ve Ahlak Bilgisi",
      "Görsel Sanatlar",
      "Müzik",
    ],
    "4. Sınıf": [
      "Türkçe",
      "Matematik",
      "Fen Bilimleri",
      "Sosyal Bilgiler",
      "İngilizce",
      "Din Kültürü ve Ahlak Bilgisi",
      "İnsan Hakları, Yurttaşlık ve Demokrasi",
      "Görsel Sanatlar",
      "Müzik",
    ],
  };

  @override
  void initState() {
    super.initState();
    _masterDurumunuKontrolEt();

    // Sınıf öğretmeni ise sınıf seviyesini filtreye ata
    if (widget.userRole == 'classroom_teacher') {
      if (widget.ogretmenSinifSeviyesi != null &&
          widget.ogretmenSinifSeviyesi!.trim().isNotEmpty) {
        String temizSinif = widget.ogretmenSinifSeviyesi!.trim();
        if (temizSinif.contains("Sınıf")) {
          _secilenSinifFiltresi = temizSinif;
        } else {
          _secilenSinifFiltresi = "$temizSinif. Sınıf";
        }
      } else {
        // Eğer ogretmenSinifSeviyesi parametresi null geldiyse,
        // buraya kendi sınıfınızı (örneğin 1. sınıf öğretmeni için "1. Sınıf") varsayılan olarak atayabilirsiniz:
        _secilenSinifFiltresi = "1. Sınıf";
      }
    }
  }

  Future<void> _masterDurumunuKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMaster = prefs.getBool('isMaster') ?? false;
    });
  }

  // Master Hesap için Kaynak Ekleme Penceresi (Sınıf ve Ders Seçimli)
  void _linkEkleDialog(BuildContext context) {
    String? dialogSecilenSinif = _secilenSinifFiltresi ?? _siniflar.first;
    String? dialogSecilenDers = _sinifDersleri[dialogSecilenSinif]?.first;

    final TextEditingController baslikController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Yeni Ders Kitabı / Kaynak Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: dialogSecilenSinif,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Sınıf Seviyesi Seçin",
                    border: OutlineInputBorder(),
                  ),
                  items: _siniflar
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      dialogSecilenSinif = val;
                      dialogSecilenDers = _sinifDersleri[val!]?.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: dialogSecilenDers,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Ders Seçin",
                    border: OutlineInputBorder(),
                  ),
                  items: dialogSecilenSinif == null
                      ? []
                      : _sinifDersleri[dialogSecilenSinif]!
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      dialogSecilenDers = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(
                    labelText: "Kitap / Kaynak Adı (Örn: Ders Kitabı PDF)",
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

                if (baslik.isEmpty ||
                    url.isEmpty ||
                    dialogSecilenSinif == null ||
                    dialogSecilenDers == null) {
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
                      'sinif': dialogSecilenSinif,
                      'ders': dialogSecilenDers,
                      'baslik': baslik,
                      'url': url,
                      'authorId': widget.currentUserId,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kaynak başarıyla eklendi!"),
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
          "Bu ders kitabı bağlantısını silmek istiyor musunuz?",
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
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSinifOgretmeni = (widget.userRole == 'classroom_teacher');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSinifOgretmeni && widget.ogretmenSinifSeviyesi != null
              ? "${widget.ogretmenSinifSeviyesi} Ders Kitapları"
              : "Ders Kitapları & Kaynaklar",
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Sınıf Öğretmeni DEĞİLSE üst kısımda sadece SINIF SEÇME dropdown'ı görünür
          if (!isSinifOgretmeni)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.indigo.shade50,
              child: DropdownButtonFormField<String>(
                initialValue: _secilenSinifFiltresi,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Görüntülenecek Sınıf Seviyesini Seçin",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: _siniflar
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _secilenSinifFiltresi = val),
              ),
            ),

          // LİSTELEME ALANI
          Expanded(
            child: _secilenSinifFiltresi == null
                ? const Center(
                    child: Text(
                      "Lütfen yukarıdan bir sınıf seçimi yapın.",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ders_kitaplari')
                        .where('sinif', isEqualTo: _secilenSinifFiltresi)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.hasData
                          ? List.from(snapshot.data!.docs)
                          : [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "$_secilenSinifFiltresi için henüz ders kitabı eklenmemiş.",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      // TÜRKÇE ALFABETİK SIRALAMA
                      docs.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;

                        String baslikA = dataA['baslik'] ?? '';
                        String baslikB = dataB['baslik'] ?? '';

                        // Türkçe karakterleri dikkate alarak karşılaştırma
                        return baslikA.compareTo(baslikB);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          String dersAdi = data['ders'] ?? 'Genel';
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
                                child: Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                baslik,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                "Ders: $dersAdi",
                                style: TextStyle(
                                  color: Colors.indigo.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                                        horizontal: 10,
                                        vertical: 4,
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
                                    onPressed: () => _linkAc(urlStr),
                                  ),
                                  if (_isMaster) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
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
                  ),
          ),
        ],
      ),
      // SADECE MASTER HESAPTA "KAYNAK EKLE" BUTONU ÇIKAR
      floatingActionButton: _isMaster
          ? FloatingActionButton.extended(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Kaynak Ekle"),
              onPressed: () => _linkEkleDialog(context),
            )
          : null,
    );
  }
}
