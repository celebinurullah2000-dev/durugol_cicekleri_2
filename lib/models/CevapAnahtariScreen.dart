// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'image_service.dart';
import 'gemini_vision_service.dart';
import 'dart:convert';
import 'dart:async';

class CevapAnahtariScreen extends StatefulWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final Map<String, int> lessonQuestionCounts;

  const CevapAnahtariScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    required this.lessonQuestionCounts,
  });

  @override
  State<CevapAnahtariScreen> createState() => _CevapAnahtariScreenState();
}

class _CevapAnahtariScreenState extends State<CevapAnahtariScreen> {
  String _secilenKitapcik = "A";
  bool _yukleniyor = false;
  double _yuklemeYuzdesi = 0.0;
  Timer? _timer;

  // Yerel değiştirilebilir soru sayıları haritası
  late Map<String, int> _dersSoruSayilari;
  Map<String, Map<int, String>> _cevapAnahtari = {};

  final ImageService _imageService = ImageService();
  final GeminiVisionService _visionService = GeminiVisionService(
    apiKey: "AQ.Ab8RN6Jp3_E-d-lApaMTog7eYgRTbBUHLzc_YehbBZejPSRhMw",
  );

  final List<String> _idealDersSirasi = [
    "Türkçe",
    "Matematik",
    "Hayat Bilgisi",
    "İngilizce",
    "Fen Bilimleri",
    "Sosyal Bilgiler",
  ];

  @override
  void initState() {
    super.initState();
    // Gelen soru sayılarını kopyalıyoruz, boşsa standart dersleri ekliyoruz
    _dersSoruSayilari = Map.from(widget.lessonQuestionCounts);
    if (_dersSoruSayilari.isEmpty) {
      for (var ders in _idealDersSirasi) {
        _dersSoruSayilari[ders] = 13; // Varsayılan formunuza uygun 13 soru
      }
    } else {
      // Eksik standart dersler varsa onları da ekleyelim
      for (var ders in _idealDersSirasi) {
        if (!_dersSoruSayilari.containsKey(ders) &&
            (ders == "İngilizce" || ders == "Hayat Bilgisi")) {
          _dersSoruSayilari[ders] = 13;
        }
      }
    }

    _bosAnahtarOlustur();
    _mevcutAnahtariGetir();
  }

  // Soru sayılarına göre cevap anahtarı şablonunu kurar
  void _bosAnahtarOlustur() {
    Map<String, Map<int, String>> yeniAnahtar = {};
    _dersSoruSayilari.forEach((ders, soruSayisi) {
      Map<int, String> sorular = {};
      // Mevcut cevaplar varsa koruyalım, yoksa "A" atayalım
      for (int i = 1; i <= soruSayisi; i++) {
        sorular[i] = _cevapAnahtari[ders]?[i] ?? "A";
      }
      yeniAnahtar[ders] = sorular;
    });
    _cevapAnahtari = yeniAnahtar;
  }

  // Yeni Ders Ekleme Dialogu
  void _yeniDersEkleDialog() {
    final TextEditingController dersAdiController = TextEditingController();
    final TextEditingController soruSayisiController = TextEditingController(
      text: "13",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Ders Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dersAdiController,
                decoration: const InputDecoration(
                  labelText: "Ders Adı (Örn: İngilizce)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: soruSayisiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Soru Sayısı"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                String dersAdi = dersAdiController.text.trim();
                int soruSayisi = int.tryParse(soruSayisiController.text) ?? 13;
                if (dersAdi.isNotEmpty) {
                  setState(() {
                    _dersSoruSayilari[dersAdi] = soruSayisi;
                    _bosAnahtarOlustur();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mevcutAnahtariGetir() async {
    setState(() => _yukleniyor = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .doc(widget.sinavId)
          .collection('cevapAnahtarlari')
          .doc(_secilenKitapcik)
          .get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data()!['answers'] as Map<String, dynamic>;

        // Eğer veritabanında kayıtlı ders soru sayıları varsa onları da güncelleyelim
        data.forEach((ders, sorular) {
          if (sorular is Map) {
            _dersSoruSayilari[ders] = sorular.length;
          }
        });

        _bosAnahtarOlustur();

        data.forEach((ders, sorular) {
          if (sorular is Map) {
            sorular.forEach((qNo, cevap) {
              int? sNo = int.tryParse(qNo.toString());
              if (sNo != null &&
                  _cevapAnahtari.containsKey(ders) &&
                  _cevapAnahtari[ders]!.containsKey(sNo)) {
                String harf = cevap.toString().toUpperCase();
                if (["A", "B", "C", "D"].contains(harf)) {
                  _cevapAnahtari[ders]![sNo] = harf;
                }
              }
            });
          }
        });
        setState(() {});
      } else {
        _bosAnahtarOlustur();
      }
    } catch (e) {
      print("Cevap anahtarı getirme hatası: $e");
      _bosAnahtarOlustur();
    }
    setState(() => _yukleniyor = false);
  }

  Future<void> _cevapAnahtariGorselindenOku(bool kameraMi) async {
    final image = kameraMi
        ? await _imageService.captureWithCamera()
        : await _imageService.pickFromGallery();

    if (image == null) return;

    setState(() {
      _yukleniyor = true;
      _yuklemeYuzdesi = 0.0;
    });

    // --- 20 SANİYEDE DOLACAK ŞEKİLDE AYARLANDI ---
    // Her 200 milisaniyede bir %1 (%0.01) artar.
    // 100 adım x 200ms = 20 saniyede %95'e ulaşır.
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (_yuklemeYuzdesi < 0.95) {
          _yuklemeYuzdesi += 0.01;
        }
      });
    });

    try {
      Uint8List bytes = await image.readAsBytes();

      String prompt =
          """
Bu görsel resmi bir sınavın cevap anahtarıdır. 
Sınavdaki dersler ve soru sayıları şunlardır: ${_dersSoruSayilari.toString()}.
Lütfen bu görseli analiz ederek her dersin soru numaralarına karşılık gelen doğru cevapları (A, B, C, D) tespit et.
Çıktıyı kesinlikle sadece şu JSON formatında ver, markdown blokları (örn. ```json) kullanma, başka hiçbir açıklama yazma:
{
  "DersAdi": { "1": "A", "2": "B" }
}
""";

      String? aiResponse = await _visionService.analyzeFormImage(
        imageBytes: bytes,
        promptText: prompt,
      );

      // 1. Timer'ı durdur
      _timer?.cancel();

      // 2. Barı anında %100 yap ve ekrana yansıt
      setState(() {
        _yuklemeYuzdesi = 1.0;
      });

      // 3. Kullanıcının %100'ü ve yeşil/tam dolu barı 300ms boyunca görebilmesi için minik bir bekleme
      await Future.delayed(const Duration(milliseconds: 300));

      if (aiResponse != null) {
        String temizJson = aiResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        Map<String, dynamic> decodedData = jsonDecode(temizJson);

        setState(() {
          decodedData.forEach((ders, sorular) {
            if (_cevapAnahtari.containsKey(ders) && sorular is Map) {
              sorular.forEach((qNo, cevap) {
                int? soruNumarasi = int.tryParse(qNo.toString());
                if (soruNumarasi != null &&
                    _cevapAnahtari[ders]!.containsKey(soruNumarasi)) {
                  String harf = cevap.toString().toUpperCase();
                  if (["A", "B", "C", "D"].contains(harf)) {
                    _cevapAnahtari[ders]![soruNumarasi] = harf;
                  }
                }
              });
            }
          });
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Cevap anahtarı yapay zeka ile başarıyla okundu ve yüklendi! ✅",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Okuma veya işleme hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _timer?.cancel();
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  Future<void> _kaydet() async {
    setState(() => _yukleniyor = true);
    try {
      // Güncel soru sayılarını da ana sınav dokümanına kaydedelim ki diğer ekranlar da bilsin
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .doc(widget.sinavId)
          .update({'lessonQuestionCounts': _dersSoruSayilari});

      // Cevap anahtarını kaydet
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .doc(widget.sinavId)
          .collection('cevapAnahtarlari')
          .doc(_secilenKitapcik)
          .set({
            'bookletType': _secilenKitapcik,
            'answers': _cevapAnahtari.map(
              (ders, sorular) => MapEntry(
                ders,
                sorular.map((no, cevap) => MapEntry(no.toString(), cevap)),
              ),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$_secilenKitapcik Kitapçığı ve Soru Sayıları Başarıyla Kaydedildi! 💾",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kaydetme hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    var siraliEntries = _cevapAnahtari.entries.toList()
      ..sort((a, b) {
        int indexA = _idealDersSirasi.indexOf(a.key);
        int indexB = _idealDersSirasi.indexOf(b.key);
        if (indexA == -1) indexA = 99;
        if (indexB == -1) indexB = 99;
        return indexA.compareTo(indexB);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.sinavAdi} - Cevap Anahtarı"),
        centerTitle: true,
      ),
      body: _yukleniyor
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.document_scanner,
                      size: 50,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Yapay zeka optik formu inceliyor...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Yüzde İlerleyen Bar
                    LinearProgressIndicator(
                      value: _yuklemeYuzdesi,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.indigo,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 10),
                    // Yüzde Metni (%0 -> %100)
                    Text(
                      "%${(_yuklemeYuzdesi * 100).toInt()}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- KİTAPÇIK SEÇİMİ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Kitapçık Türü: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("A Kitapçığı"),
                        selected: _secilenKitapcik == "A",
                        onSelected: (val) {
                          setState(() => _secilenKitapcik = "A");
                          _mevcutAnahtariGetir();
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("B Kitapçığı"),
                        selected: _secilenKitapcik == "B",
                        onSelected: (val) {
                          setState(() => _secilenKitapcik = "B");
                          _mevcutAnahtariGetir();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- SORU SAYISI YÖNETİM PANELİ (YENİ) ---
                  Card(
                    color: Colors.indigo.shade50,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ders Soru Sayıları (Örn: 13 Soru)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _yeniDersEkleDialog,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Ders Ekle"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dersSoruSayilari.entries.map((entry) {
                              return Chip(
                                backgroundColor: Colors.white,
                                label: Text(
                                  "${entry.key}: ${entry.value} Soru",
                                ),
                                deleteIcon: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.indigo,
                                ),
                                onDeleted: () {
                                  TextEditingController ctrl =
                                      TextEditingController(
                                        text: entry.value.toString(),
                                      );
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("${entry.key} Soru Sayısı"),
                                      content: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: "Soru Sayısı (Örn: 13)",
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("İptal"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            int val =
                                                int.tryParse(ctrl.text) ??
                                                entry.value;
                                            setState(() {
                                              _dersSoruSayilari[entry.key] =
                                                  val;
                                              _bosAnahtarOlustur();
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Güncelle"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- RESİM YÜKLEME / OKUTMA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _cevapAnahtariGorselindenOku(false),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galeriden Seç"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _cevapAnahtariGorselindenOku(true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Fotoğraf Çek"),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // --- DERSLER VE SORU SEÇENEKLERİ LİSTESİ ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: siraliEntries.length,
                    itemBuilder: (context, index) {
                      String dersAdi = siraliEntries[index].key;
                      Map<int, String> sorular = siraliEntries[index].value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dersAdi,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: sorular.entries.map((soru) {
                                  int soruNo = soru.key;
                                  String hamCevap = soru.value;

                                  String gecerliCevap =
                                      [
                                        "A",
                                        "B",
                                        "C",
                                        "D",
                                      ].contains(hamCevap.toUpperCase())
                                      ? hamCevap.toUpperCase()
                                      : "A";

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "$soruNo.",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        DropdownButton<String>(
                                          value: gecerliCevap,
                                          isDense: true,
                                          items: ["A", "B", "C", "D"].map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            );
                                          }).toList(),
                                          onChanged: (yeniDeger) {
                                            if (yeniDeger != null) {
                                              setState(() {
                                                _cevapAnahtari[dersAdi]![soruNo] =
                                                    yeniDeger;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- KAYDET BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _kaydet,
                      child: const Text(
                        "Cevap Anahtarını Kaydet",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
