// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class KisiselIngilizceSozluk extends StatefulWidget {
  final String classId;
  final String userRole;

  const KisiselIngilizceSozluk({
    super.key,
    required this.classId,
    required this.userRole,
    required bool isTeacher,
  });

  @override
  State<KisiselIngilizceSozluk> createState() =>
      _KisiselIngilizceSozlukScreenState();
}

class _KisiselIngilizceSozlukScreenState extends State<KisiselIngilizceSozluk> {
  String _aramaMetni = "";

  // Filtre Değişkenleri
  String _secilenSinifFiltre = "Tüm Sınıflar";
  String _secilenTemaFiltre = "Tüm Temalar";

  final List<String> _sinifSecenekleri = [
    "Tüm Sınıflar",
    "2. Sınıf",
    "3. Sınıf",
    "4. Sınıf",
  ];

  List<String> get _aktifTemaSecenekleri {
    if (_secilenSinifFiltre == "4. Sınıf") {
      return [
        "Tüm Temalar",
        "Theme 1",
        "Theme 2",
        "Theme 3",
        "Theme 4",
        "Theme 5",
        "Theme 6",
        "Theme 7",
        "Theme 8",
        "Theme 9",
        "Theme 10",
      ];
    } else {
      return [
        "Tüm Temalar",
        "Theme 1",
        "Theme 2",
        "Theme 3",
        "Theme 4",
        "Theme 5",
        "Theme 6",
      ];
    }
  }

  bool get _yetkiliMi {
    String rol = widget.userRole.trim().toLowerCase();
    return rol != 'admin' && rol != 'guidance_teacher';
  }

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
        if (comp != 0) {
          return comp;
        }
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }
    return aKucuk.length.compareTo(bKucuk.length);
  }

  // --- CİHAZDAN YEREL RESİM SEÇME YARDIMCISI ---
  Future<void> _yerelResimSec(
    ImageSource source,
    Function(XFile file, Uint8List bytes) onSecildi,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image == null) {
        return;
      }

      var bytes = await image.readAsBytes();
      onSecildi(image, bytes);
    } catch (e) {
      print("Görsel seçme hatası: $e");
    }
  }

  // --- PİKABAY GÖRSEL SEÇİM DIALOGU ---
  void _gosterGorselOnayDialog(
    String kelime,
    Function(String secilenUrl) onOnaySecildi,
  ) {
    if (kelime.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce bir sözcük (Word) yazın!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          _GorselOnayPopup(kelime: kelime.trim(), onOnaySecildi: onOnaySecildi),
    );
  }

  // --- YENİ SÖZCÜK EKLEME PENCERESİ ---
  void _yeniSozlukDialogGoster(BuildContext context) {
    final TextEditingController sozcukController = TextEditingController();
    final TextEditingController anlamController = TextEditingController();
    final TextEditingController gorselUrlController = TextEditingController();
    final TextEditingController cumle1Controller = TextEditingController();
    final TextEditingController cumle2Controller = TextEditingController();
    final TextEditingController cumle3Controller = TextEditingController();

    String dialogSecilenSinif = "4. Sınıf";
    String dialogSecilenTema = "Theme 1";

    XFile? secilenYerelDosya;
    Uint8List? secilenDosyaBytes;

    List<String> getDialogTemalar(String sinif) {
      if (sinif == "4. Sınıf") {
        return [
          "Theme 1",
          "Theme 2",
          "Theme 3",
          "Theme 4",
          "Theme 5",
          "Theme 6",
          "Theme 7",
          "Theme 8",
          "Theme 9",
          "Theme 10",
        ];
      } else {
        return [
          "Theme 1",
          "Theme 2",
          "Theme 3",
          "Theme 4",
          "Theme 5",
          "Theme 6",
        ];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yeni İngilizce Sözcük Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: dialogSecilenSinif,
                  decoration: const InputDecoration(
                    labelText: "Sınıf Seviyesi",
                  ),
                  items: ["2. Sınıf", "3. Sınıf", "4. Sınıf"]
                      .map(
                        (sinif) =>
                            DropdownMenuItem(value: sinif, child: Text(sinif)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        dialogSecilenSinif = val;
                        List<String> yeniTemalar = getDialogTemalar(val);
                        if (!yeniTemalar.contains(dialogSecilenTema)) {
                          dialogSecilenTema = yeniTemalar.first;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: dialogSecilenTema,
                  decoration: const InputDecoration(labelText: "Tema (Theme)"),
                  items: getDialogTemalar(dialogSecilenSinif)
                      .map(
                        (tema) =>
                            DropdownMenuItem(value: tema, child: Text(tema)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => dialogSecilenTema = val);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sozcukController,
                  decoration: const InputDecoration(labelText: "Word (Sözcük)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: anlamController,
                  decoration: const InputDecoration(
                    labelText: "Meaning (Anlamı)",
                  ),
                ),
                const SizedBox(height: 12),

                // --- GÖRSEL KAYNAĞI SEÇİM ALANI ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gorselUrlController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Görsel Durumu",
                          hintText: "Görsel seçilmedi",
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Pixabay Arama Butonu
                    IconButton(
                      tooltip: "Pixabay'den Bul",
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.indigo,
                      ),
                      onPressed: () {
                        _gosterGorselOnayDialog(sozcukController.text.trim(), (
                          secilenUrl,
                        ) {
                          setDialogState(() {
                            gorselUrlController.text = secilenUrl;
                            secilenYerelDosya = null;
                            secilenDosyaBytes = null;
                          });
                        });
                      },
                    ),
                    // Galeriden Seç Butonu
                    IconButton(
                      tooltip: "Galeriden Seç",
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.green,
                      ),
                      onPressed: () async {
                        await _yerelResimSec(ImageSource.gallery, (
                          file,
                          bytes,
                        ) {
                          setDialogState(() {
                            secilenYerelDosya = file;
                            secilenDosyaBytes = bytes;
                            gorselUrlController.text = file.name;
                          });
                        });
                      },
                    ),
                    // Kameradan Çek Butonu
                    IconButton(
                      tooltip: "Kameradan Çek",
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: () async {
                        await _yerelResimSec(ImageSource.camera, (file, bytes) {
                          setDialogState(() {
                            secilenYerelDosya = file;
                            secilenDosyaBytes = bytes;
                            gorselUrlController.text = file.name;
                          });
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (secilenDosyaBytes != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          secilenDosyaBytes!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else if (gorselUrlController.text.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: gorselUrlController.text,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle1Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 1",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle2Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 2",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle3Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 3",
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
                String sozcuk = sozcukController.text.trim();
                String anlam = anlamController.text.trim();
                String finalGorselUrl = gorselUrlController.text.trim();
                List<String> cumleler = [
                  cumle1Controller.text.trim(),
                  cumle2Controller.text.trim(),
                  cumle3Controller.text.trim(),
                ].where((c) => c.isNotEmpty).toList();

                if (sozcuk.isNotEmpty && anlam.isNotEmpty) {
                  // Eğer yerel bir dosya seçildiyse, kaydetme anında Storage'a yükle
                  if (secilenYerelDosya != null && secilenDosyaBytes != null) {
                    try {
                      String fileName = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      Reference ref = FirebaseStorage.instance.ref().child(
                        'sozluk_gorselleri/$fileName.jpg',
                      );
                      UploadTask uploadTask = ref.putData(secilenDosyaBytes!);
                      TaskSnapshot snapshot = await uploadTask;
                      finalGorselUrl = await snapshot.ref.getDownloadURL();
                    } catch (e) {
                      print("Storage yükleme hatası: $e");
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Görsel yüklenemedi: $e")),
                      );
                      return;
                    }
                  }

                  await FirebaseFirestore.instance
                      .collection('genel_ingilizce_sozluk')
                      .add({
                        'sozcuk': sozcuk,
                        'anlam': anlam,
                        'gorselUrl': finalGorselUrl,
                        'cumleler': cumleler,
                        'sinifSeviyesi': dialogSecilenSinif,
                        'tema': dialogSecilenTema,
                        'tarih': Timestamp.now(),
                      });

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sözcük başarıyla eklendi! ✅"),
                    ),
                  );
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  // --- SÖZCÜK DÜZENLEME PENCERESİ (SADECE ÖĞRETMEN) ---
  void _sozcukDuzenleDialogGoster(Map<String, dynamic> item) {
    final String docId = item['id'];
    final TextEditingController sozcukController = TextEditingController(
      text: item['sozcuk'] ?? '',
    );
    final TextEditingController anlamController = TextEditingController(
      text: item['anlam'] ?? '',
    );
    final TextEditingController gorselUrlController = TextEditingController(
      text: item['gorselUrl'] ?? '',
    );

    String dialogSecilenSinif = item['sinifSeviyesi'] ?? "4. Sınıf";
    String dialogSecilenTema = item['tema'] ?? "Theme 1";

    XFile? secilenYerelDosya;
    Uint8List? secilenDosyaBytes;

    List<String> getDialogTemalar(String sinif) {
      if (sinif == "4. Sınıf") {
        return [
          "Theme 1",
          "Theme 2",
          "Theme 3",
          "Theme 4",
          "Theme 5",
          "Theme 6",
          "Theme 7",
          "Theme 8",
          "Theme 9",
          "Theme 10",
        ];
      } else {
        return [
          "Theme 1",
          "Theme 2",
          "Theme 3",
          "Theme 4",
          "Theme 5",
          "Theme 6",
        ];
      }
    }

    if (!getDialogTemalar(dialogSecilenSinif).contains(dialogSecilenTema)) {
      dialogSecilenTema = "Theme 1";
    }

    List<dynamic> mevcutCumleler = item['cumleler'] ?? [];
    final TextEditingController cumle1Controller = TextEditingController(
      text: mevcutCumleler.isNotEmpty ? mevcutCumleler[0] : '',
    );
    final TextEditingController cumle2Controller = TextEditingController(
      text: mevcutCumleler.length > 1 ? mevcutCumleler[1] : '',
    );
    final TextEditingController cumle3Controller = TextEditingController(
      text: mevcutCumleler.length > 2 ? mevcutCumleler[2] : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Sözcüğü Düzenle: ${item['sozcuk']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                      [
                        "2. Sınıf",
                        "3. Sınıf",
                        "4. Sınıf",
                      ].contains(dialogSecilenSinif)
                      ? dialogSecilenSinif
                      : "4. Sınıf",
                  decoration: const InputDecoration(
                    labelText: "Sınıf Seviyesi",
                  ),
                  items: ["2. Sınıf", "3. Sınıf", "4. Sınıf"]
                      .map(
                        (sinif) =>
                            DropdownMenuItem(value: sinif, child: Text(sinif)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        dialogSecilenSinif = val;
                        List<String> yeniTemalar = getDialogTemalar(val);
                        if (!yeniTemalar.contains(dialogSecilenTema)) {
                          dialogSecilenTema = yeniTemalar.first;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue:
                      getDialogTemalar(
                        dialogSecilenSinif,
                      ).contains(dialogSecilenTema)
                      ? dialogSecilenTema
                      : getDialogTemalar(dialogSecilenSinif).first,
                  decoration: const InputDecoration(labelText: "Tema (Theme)"),
                  items: getDialogTemalar(dialogSecilenSinif)
                      .map(
                        (tema) =>
                            DropdownMenuItem(value: tema, child: Text(tema)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => dialogSecilenTema = val);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sozcukController,
                  decoration: const InputDecoration(labelText: "Word (Sözcük)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: anlamController,
                  decoration: const InputDecoration(
                    labelText: "Meaning (Anlamı)",
                  ),
                ),
                const SizedBox(height: 12),

                // --- GÖRSEL KAYNAĞI SEÇİM ALANI ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gorselUrlController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Görsel Durumu",
                          hintText: "Görsel seçilmedi",
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: "Pixabay'den Değiştir",
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.indigo,
                      ),
                      onPressed: () {
                        _gosterGorselOnayDialog(sozcukController.text.trim(), (
                          secilenUrl,
                        ) {
                          setDialogState(() {
                            gorselUrlController.text = secilenUrl;
                            secilenYerelDosya = null;
                            secilenDosyaBytes = null;
                          });
                        });
                      },
                    ),
                    IconButton(
                      tooltip: "Galeriden Seç",
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.green,
                      ),
                      onPressed: () async {
                        await _yerelResimSec(ImageSource.gallery, (
                          file,
                          bytes,
                        ) {
                          setDialogState(() {
                            secilenYerelDosya = file;
                            secilenDosyaBytes = bytes;
                            gorselUrlController.text = file.name;
                          });
                        });
                      },
                    ),
                    IconButton(
                      tooltip: "Kameradan Çek",
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: () async {
                        await _yerelResimSec(ImageSource.camera, (file, bytes) {
                          setDialogState(() {
                            secilenYerelDosya = file;
                            secilenDosyaBytes = bytes;
                            gorselUrlController.text = file.name;
                          });
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (secilenDosyaBytes != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          secilenDosyaBytes!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else if (gorselUrlController.text.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: gorselUrlController.text,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle1Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 1",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle2Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 2",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cumle3Controller,
                  decoration: const InputDecoration(
                    labelText: "Example Sentence 3",
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
                String sozcuk = sozcukController.text.trim();
                String anlam = anlamController.text.trim();
                String finalGorselUrl = gorselUrlController.text.trim();
                List<String> cumleler = [
                  cumle1Controller.text.trim(),
                  cumle2Controller.text.trim(),
                  cumle3Controller.text.trim(),
                ].where((c) => c.isNotEmpty).toList();

                if (sozcuk.isNotEmpty && anlam.isNotEmpty) {
                  // Eğer yeni bir yerel dosya seçildiyse güncelleme anında Storage'a yükle
                  if (secilenYerelDosya != null && secilenDosyaBytes != null) {
                    try {
                      String fileName = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      Reference ref = FirebaseStorage.instance.ref().child(
                        'sozluk_gorselleri/$fileName.jpg',
                      );
                      UploadTask uploadTask = ref.putData(secilenDosyaBytes!);
                      TaskSnapshot snapshot = await uploadTask;
                      finalGorselUrl = await snapshot.ref.getDownloadURL();
                    } catch (e) {
                      print("Storage yükleme hatası: $e");
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Görsel yüklenemedi: $e")),
                      );
                      return;
                    }
                  }

                  await FirebaseFirestore.instance
                      .collection('genel_ingilizce_sozluk')
                      .doc(docId)
                      .update({
                        'sozcuk': sozcuk,
                        'anlam': anlam,
                        'gorselUrl': finalGorselUrl,
                        'cumleler': cumleler,
                        'sinifSeviyesi': dialogSecilenSinif,
                        'tema': dialogSecilenTema,
                      });

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sözcük başarıyla güncellendi! ✅"),
                    ),
                  );
                }
              },
              child: const Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÖĞRENCİLER İÇİN SALT OKUNUR DETAY PENCERESİ ---
  void _sozcukDetayGoster(Map<String, dynamic> data) {
    String sozcuk = data['sozcuk'] ?? '';
    String anlam = data['anlam'] ?? '';
    String gorselUrl = data['gorselUrl'] ?? '';
    String sinif = data['sinifSeviyesi'] ?? 'Belirtilmemiş';
    String tema = data['tema'] ?? 'Belirtilmemiş';
    List<dynamic> cumleler = data['cumleler'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          sozcuk,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(sinif, style: const TextStyle(fontSize: 11)),
                  ),
                  Chip(label: Text(tema, style: const TextStyle(fontSize: 11))),
                ],
              ),
              const SizedBox(height: 8),
              if (gorselUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: gorselUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 120,
                        width: 120,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                "Meaning (Anlamı):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                anlam,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Example Sentences:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (cumleler.isEmpty)
                const Text(
                  "Örnek cümle eklenmemiş.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                ...cumleler.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${entry.key + 1}. \"${entry.value}\"",
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İngilizce Sözlük Sayfası"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          /* --- TOPLU YÜKLEME BUTONU PASİFLEŞTİRİLDİ ---
          if (_yetkiliMi)
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: "Kelimeleri Firestore'a Yükle",
              onPressed: _topluKelimeYukle,
            ),
          */
        ],
      ),
      body: Column(
        children: [
          // --- FİLTRELEME ALANI (ÜST KISIM) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // 1. Filtre: Sınıf Seviyesi
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _secilenSinifFiltre,
                        isExpanded: true,
                        items: _sinifSecenekleri
                            .map(
                              (sinif) => DropdownMenuItem(
                                value: sinif,
                                child: Text(
                                  sinif,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _secilenSinifFiltre = val;
                              if (!_aktifTemaSecenekleri.contains(
                                _secilenTemaFiltre,
                              )) {
                                _secilenTemaFiltre = "Tüm Temalar";
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 2. Filtre: Tema
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            _aktifTemaSecenekleri.contains(_secilenTemaFiltre)
                            ? _secilenTemaFiltre
                            : "Tüm Temalar",
                        isExpanded: true,
                        items: _aktifTemaSecenekleri
                            .map(
                              (tema) => DropdownMenuItem(
                                value: tema,
                                child: Text(
                                  tema,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _secilenTemaFiltre = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- ARAMA ÇUBUĞU ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (deger) => setState(() => _aramaMetni = deger.trim()),
              decoration: InputDecoration(
                labelText: "Search Word (Sözcük Ara)",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // --- LİSTELEME VE FİLTRE UYGULAMA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('genel_ingilizce_sozluk')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz sözcük eklenmemiş."));
                }

                var docs = snapshot.data!.docs;
                List<Map<String, dynamic>> sozlukListesi = [];
                for (var doc in docs) {
                  sozlukListesi.add({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  });
                }

                // 1. Sınıf Filtresi Uygula
                if (_secilenSinifFiltre != "Tüm Sınıflar") {
                  sozlukListesi = sozlukListesi.where((item) {
                    return item['sinifSeviyesi'] == _secilenSinifFiltre;
                  }).toList();
                }

                // 2. Tema Filtresi Uygula
                if (_secilenTemaFiltre != "Tüm Temalar") {
                  sozlukListesi = sozlukListesi.where((item) {
                    return item['tema'] == _secilenTemaFiltre;
                  }).toList();
                }

                // Alfabetik Sıralama
                sozlukListesi.sort(
                  (a, b) =>
                      _turkceKarsilastir(a['sozcuk'] ?? '', b['sozcuk'] ?? ''),
                );

                // Arama Metni Filtresi Uygula
                if (_aramaMetni.isNotEmpty) {
                  sozlukListesi = sozlukListesi.where((item) {
                    return (item['sozcuk'] ?? '')
                        .toString()
                        .toLowerCase()
                        .startsWith(_aramaMetni.toLowerCase());
                  }).toList();
                }

                if (sozlukListesi.isEmpty) {
                  return const Center(
                    child: Text("Seçilen kriterlere uygun sözcük bulunamadı."),
                  );
                }

                return ListView.builder(
                  itemCount: sozlukListesi.length,
                  itemBuilder: (context, index) {
                    var item = sozlukListesi[index];
                    String gorselUrl = item['gorselUrl'] ?? '';
                    String sinifEtiket = item['sinifSeviyesi'] ?? '';
                    String temaEtiket = item['tema'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: gorselUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  gorselUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      backgroundColor: Colors.indigo.shade100,
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                        title: Row(
                          children: [
                            Text(
                              item['sozcuk'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (sinifEtiket.isNotEmpty || temaEtiket.isNotEmpty)
                              Text(
                                "$sinifEtiket | $temaEtiket",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          item['anlam'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_yetkiliMi)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('genel_ingilizce_sozluk')
                                      .doc(item['id'])
                                      .delete();
                                },
                              ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                        onTap: () {
                          if (_yetkiliMi) {
                            _sozcukDuzenleDialogGoster(item);
                          } else {
                            _sozcukDetayGoster(item);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _yetkiliMi
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              onPressed: () => _yeniSozlukDialogGoster(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// --- PİKABAY DESTEKLİ GÖRSEL SEÇİM POPUP'I ---
class _GorselOnayPopup extends StatefulWidget {
  final String kelime;
  final Function(String) onOnaySecildi;

  const _GorselOnayPopup({required this.kelime, required this.onOnaySecildi});

  @override
  State<_GorselOnayPopup> createState() => _GorselOnayPopupState();
}

class _GorselOnayPopupState extends State<_GorselOnayPopup> {
  bool _isLoading = true;
  String _guncelUrl = "";
  List<dynamic> _fotografListesi = [];

  static const String pixabayApiKey = "57543644-49cd4fd82ee9d73e7230201fb";

  @override
  void initState() {
    super.initState();
    _pixabaydenGorselCek();
  }

  Future<void> _pixabaydenGorselCek() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String arananKelime = widget.kelime.trim();
      if (arananKelime.isEmpty) {
        arananKelime = "school";
      }

      if (_fotografListesi.isEmpty) {
        final encodedQuery = Uri.encodeComponent(arananKelime);
        final url = Uri.parse(
          'https://pixabay.com/api/?key=$pixabayApiKey&q=$encodedQuery&image_type=photo&safesearch=true&per_page=15',
        );

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _fotografListesi = data['hits'] ?? [];
        }
      }

      if (_fotografListesi.isNotEmpty) {
        _fotografListesi.shuffle();
        var secilenFoto = _fotografListesi.first;
        _guncelUrl = secilenFoto['webformatURL'];
      } else {
        _guncelUrl =
            "https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=400";
      }
    } catch (e) {
      print("Pixabay API Hatası: $e");
      _guncelUrl =
          "https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=400";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Görsel Önerisi: ${widget.kelime}",
        style: const TextStyle(color: Colors.indigo, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade200, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isLoading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 12),
                        Text(
                          "Görsel aranıyor...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : CachedNetworkImage(
                      imageUrl: _guncelUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Görsel yüklenemedi",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Beğenmediyseniz 'Yeni Öneri Al' butonuna basarak veritabanından başka bir fotoğraf getirebilirsiniz.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal", style: TextStyle(color: Colors.red)),
        ),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _pixabaydenGorselCek,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text("Yeni Öneri Al"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading || _guncelUrl.isEmpty
              ? null
              : () {
                  widget.onOnaySecildi(_guncelUrl);
                  Navigator.pop(context);
                },
          child: const Text("Onayla"),
        ),
      ],
    );
  }
}
