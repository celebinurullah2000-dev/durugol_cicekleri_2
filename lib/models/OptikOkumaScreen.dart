// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'image_service.dart';
import 'gemini_vision_service.dart';

class OptikOkumaScreen extends StatefulWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final Map<String, int> lessonQuestionCounts;

  const OptikOkumaScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    required this.lessonQuestionCounts,
  });

  @override
  State<OptikOkumaScreen> createState() => _OptikOkumaScreenState();
}

class _OptikOkumaScreenState extends State<OptikOkumaScreen> {
  bool _yukleniyor = false;
  double _yuklemeYuzdesi = 0.0;
  Timer? _timer;

  String _secilenKitapcik = "A";
  String? _okunanOgrenciAdi;
  String? _secilenOgrenciId;

  late Map<String, int> _dersSoruSayilari;
  List<Map<String, dynamic>> _sinifOgrencileri = [];
  Map<String, Map<int, String>> _ogrenciCevaplari = {};
  Map<String, Map<String, int>> _hesaplananSonuclar = {};

  final ImageService _imageService = ImageService();
  final GeminiVisionService _visionService = GeminiVisionService(
    apiKey: const String.fromEnvironment(
      'AQ.Ab8RN6Jp3_E-d-lApaMTog7eYgRTbBUHLzc_YehbBZejPSRhMw',
    ),
  );

  @override
  void initState() {
    super.initState();
    _dersSoruSayilari = Map.from(widget.lessonQuestionCounts);
    _sinifOgrencileriniGetir();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Sınıftaki öğrencileri çekme (Boşluk düzeltmeli ve Türkçe alfabetik sıralı)
  Future<void> _sinifOgrencileriniGetir() async {
    var snap = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciler = snap.docs.map((doc) {
      var data = doc.data();
      String ad = data['firstName'] ?? data['ad'] ?? '';
      String soyad = data['lastName'] ?? data['soyad'] ?? '';

      // Eğer ad ve soyad ayrı ayrı tutulmuyorsa veya bitişikse akıllıca düzeltelim
      String duzenlenmisAdSoyad = _duzeltAdSoyad(ad, soyad);

      if (duzenlenmisAdSoyad.trim().isEmpty) {
        duzenlenmisAdSoyad = data['adSoyad'] ?? "İsimsiz Öğrenci";
      }

      return {
        'id': doc.id,
        'adSoyad': duzenlenmisAdSoyad.replaceAll(RegExp(r'\s+'), ' ').trim(),
      };
    }).toList();

    // Türkçe karakter uyumlu kusursuz alfabetik sıralama
    ogrenciler.sort((a, b) => _turkceKarsilastir(a['adSoyad'], b['adSoyad']));

    setState(() {
      _sinifOgrencileri = ogrenciler;
    });
  }

  // Bitişik yazılmış ad ve soyadları akıllıca ayıran yardımcı metot
  String _duzeltAdSoyad(String ad, String soyad) {
    String birlesik = "$ad $soyad".replaceAll(RegExp(r'\s+'), ' ').trim();

    // Eğer arada hiç boşluk yoksa ve veritabanında tek kelime gibi birleşmişse
    if (!birlesik.contains(' ')) {
      // Sınıfınızda geçen veya yaygın olan birleşik soyadlar listesi
      const bilinenSoyadlar = [
        'AKÇAY',
        'ARSLAN',
        'AYDIN',
        'ODABAŞI',
        'ODABAŞ',
        'GÜZELSU',
        'ÖZTOPRAK',
        'BAYRAMLI',
        'YİĞİTAKSOY',
        'NİSAARSLAN',
        'SAREYILDIRIM',
        'BERENYONDEMİR',
        'ALPGÖZÜTOK',
        'NAZÖNCÜ',
        'YAĞİZOĞLU',
        'ALPYAZIM',
        'DENİZKEÇECİ',
      ];

      String buyukHarfHali = birlesik.toUpperCase();
      for (var soy in bilinenSoyadlar) {
        if (buyukHarfHali.endsWith(soy) && buyukHarfHali.length > soy.length) {
          int index = buyukHarfHali.length - soy.length;
          String isimKismi = birlesik.substring(0, index);
          String soyadKismi = birlesik.substring(index);
          return "$isimKismi $soyadKismi";
        }
      }
    }

    return birlesik;
  }

  // Türkçe Alfabetik Sıralama Yardımcı Metodu
  int _turkceKarsilastir(String a, String b) {
    const trMap = {
      'Ç': 'C',
      'ç': 'c',
      'Ğ': 'G',
      'ğ': 'g',
      'İ': 'I',
      'ı': 'i',
      'Ö': 'O',
      'ö': 'o',
      'Ş': 'S',
      'ş': 's',
      'Ü': 'U',
      'ü': 'u',
    };

    String normalize(String str) {
      String sonuc = str;
      trMap.forEach((tr, en) {
        sonuc = sonuc.replaceAll(tr, en);
      });
      return sonuc.toLowerCase();
    }

    return normalize(a).compareTo(normalize(b));
  }

  void _yeniDersEkleDialog() {
    final TextEditingController dersAdiController = TextEditingController();
    final TextEditingController soruSayisiController = TextEditingController(
      text: "13",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eksik Ders Ekle"),
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

  Future<void> _formuOkut(bool kameraMi) async {
    final image = kameraMi
        ? await _imageService.captureWithCamera()
        : await _imageService.pickFromGallery();

    if (image == null) return;

    setState(() {
      _yukleniyor = true;
      _yuklemeYuzdesi = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (_yuklemeYuzdesi < 0.95) {
          _yuklemeYuzdesi += 0.01;
        }
      });
    });

    try {
      Uint8List bytes = await image.readAsBytes();

      // Güçlendirilmiş prompt (karalanmış daireleri daha hassas okuması için)
      String prompt =
          """
Bu görsel bir ilkokul öğrencisinin doldurduğu optik sınav formudur.
Sınavdaki dersler ve soru sayıları şunlardır: ${_dersSoruSayilari.toString()}.

Çok dikkatli incele:
- Öğrencinin cevapları form üzerinde siyah kalemle tamamen KARALANMIŞ (doldurulmuş) dairelerdir (●). 
- Boş bırakılan daireler ise sadece çerçevedir (○).
- Lütfen her bir soru satırını tek tek dikkatlice takip et ve öğrencinin gerçekten hangi şıkkı karaladığını tespit et. 

Çıktıyı kesinlikle sadece şu JSON formatında ver, markdown blokları (örn. ```json) kullanma, başka hiçbir açıklama yazma:
{
  "ogrenciAdi": "Öğrencinin Adı Soyadı",
  "cevaplar": {
    "DersAdi": { "1": "A", "2": "C" }
  }
}
""";

      String? aiResponse = await _visionService.analyzeFormImage(
        imageBytes: bytes,
        promptText: prompt,
      );

      _timer?.cancel();
      setState(() {
        _yuklemeYuzdesi = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 300));

      if (aiResponse != null) {
        String temizJson = aiResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        Map<String, dynamic> decodedData = jsonDecode(temizJson);

        String aiOgrenciAdi = decodedData['ogrenciAdi'] ?? '';
        var rawCevaplar =
            decodedData['cevaplar'] as Map<String, dynamic>? ?? {};

        Map<String, Map<int, String>> parsedCevaplar = {};
        rawCevaplar.forEach((ders, sorular) {
          if (sorular is Map) {
            Map<int, String> qMap = {};
            sorular.forEach((qNo, cevap) {
              int? sNo = int.tryParse(qNo.toString());
              if (sNo != null) {
                qMap[sNo] = cevap.toString().toUpperCase();
              }
            });
            parsedCevaplar[ders] = qMap;
          }
        });

        String? bulunanId;
        if (aiOgrenciAdi.isNotEmpty) {
          for (var ogrenci in _sinifOgrencileri) {
            if (ogrenci['adSoyad'].toLowerCase().contains(
                  aiOgrenciAdi.toLowerCase(),
                ) ||
                aiOgrenciAdi.toLowerCase().contains(
                  ogrenci['adSoyad'].toLowerCase(),
                )) {
              bulunanId = ogrenci['id'];
              break;
            }
          }
        }

        setState(() {
          _okunanOgrenciAdi = aiOgrenciAdi;
          _ogrenciCevaplari = parsedCevaplar;
          if (bulunanId != null) {
            _secilenOgrenciId = bulunanId;
          }
        });

        await _sonuclariHesaplaVePuanla();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Optik form başarıyla okundu ve analiz edildi! ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Okuma hatası: $e"),
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

  Future<void> _sonuclariHesaplaVePuanla() async {
    try {
      var anahtarDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .doc(widget.sinavId)
          .collection('cevapAnahtarlari')
          .doc(_secilenKitapcik)
          .get();

      if (!anahtarDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$_secilenKitapcik Kitapçığı için cevap anahtarı bulunamadı! Önce cevap anahtarı yükleyin.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      var anahtarData = anahtarDoc.data()!['answers'] as Map<String, dynamic>;
      Map<String, Map<int, String>> dogruCevaplar = {};
      anahtarData.forEach((ders, sorular) {
        var sMap = (sorular as Map<String, dynamic>).map(
          (qNo, cevap) =>
              MapEntry(int.parse(qNo), cevap.toString().toUpperCase()),
        );
        dogruCevaplar[ders] = sMap;
      });

      Map<String, Map<String, int>> hesaplanan = {};

      _dersSoruSayilari.forEach((ders, soruSayisi) {
        int d = 0;
        int y = 0;
        int b = 0;

        var ogrenciDersCevaplari = _ogrenciCevaplari[ders] ?? {};
        var dersDogruAnahtari = dogruCevaplar[ders] ?? {};

        for (int i = 1; i <= soruSayisi; i++) {
          String ogrenciCevap = (ogrenciDersCevaplari[i] ?? "-").toUpperCase();
          String dogruCevap = (dersDogruAnahtari[i] ?? "A").toUpperCase();

          if (ogrenciCevap == "-" || ogrenciCevap.isEmpty) {
            b++;
          } else if (ogrenciCevap == dogruCevap) {
            d++;
          } else {
            y++;
          }
        }

        hesaplanan[ders] = {'d': d, 'y': y, 'b': b};
      });

      setState(() {
        _hesaplananSonuclar = hesaplanan;
      });
    } catch (e) {
      print("Puanlama hesaplama hatası: $e");
    }
  }

  Future<void> _kaydet() async {
    if (_secilenOgrenciId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen öğrenci seçiniz!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hesaplananSonuclar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Henüz hesaplanmış sonuç bulunmuyor. Formu okutun."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .doc(widget.sinavId)
          .collection('sonuclar')
          .doc(_secilenOgrenciId)
          .set(_hesaplananSonuclar);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Öğrenci sınav sonuçları başarıyla kaydedildi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kaydetme hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.sinavAdi} - Optik Okuma"),
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // 1. KİTAPÇIK SEÇİMİ VE SORU SAYISI
                  Card(
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
                                "Kitapçık Türü:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text("A Kitapçığı"),
                                    selected: _secilenKitapcik == "A",
                                    onSelected: (val) {
                                      setState(() => _secilenKitapcik = "A");
                                      if (_ogrenciCevaplari.isNotEmpty) {
                                        _sonuclariHesaplaVePuanla();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text("B Kitapçığı"),
                                    selected: _secilenKitapcik == "B",
                                    onSelected: (val) {
                                      setState(() => _secilenKitapcik = "B");
                                      if (_ogrenciCevaplari.isNotEmpty) {
                                        _sonuclariHesaplaVePuanla();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ders Soru Sayıları:",
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
                                label: Text(
                                  "${entry.key}: ${entry.value} Soru",
                                ),
                                deleteIcon: const Icon(Icons.edit, size: 14),
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
                                          labelText: "Yeni Soru Sayısı",
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
                                            });
                                            Navigator.pop(context);
                                            if (_ogrenciCevaplari.isNotEmpty) {
                                              _sonuclariHesaplaVePuanla();
                                            }
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

                  // 2. FORM OKUTMA BUTONLARI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _formuOkut(false),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galeriden Form Seç"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _formuOkut(true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Form Fotoğrafı Çek"),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // 3. ÖĞRENCİ EŞLEŞTİRME ALANI
                  Card(
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _okunanOgrenciAdi != null
                                ? "Okunan Öğrenci (AI): $_okunanOgrenciAdi"
                                : "Öğrenci henüz okunmadı veya taranamadı.",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Öğrenciyi Kontrol Et / Manuel Seç:",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _secilenOgrenciId,
                            isExpanded: true,
                            hint: const Text("Listeden Öğrenci Seçin"),
                            items: _sinifOgrencileri.map((ogrenci) {
                              return DropdownMenuItem(
                                value: ogrenci['id'].toString(),
                                child: Text(ogrenci['adSoyad']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _secilenOgrenciId = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 4. OKUNAN ŞIKLARI GÖRME VE MANUEL DÜZELTME ALANI (YENİ)
                  if (_ogrenciCevaplari.isNotEmpty) ...[
                    const Text(
                      "Okunan Şıklar (Hatalı okunanları buradan düzeltebilirsiniz):",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._ogrenciCevaplari.entries.map((entry) {
                      String ders = entry.key;
                      Map<int, String> sorular = entry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ders,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const Divider(),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: sorular.entries.map((soru) {
                                  int sNo = soru.key;
                                  String secilenCevap = soru.value;

                                  String gecerliSecenek =
                                      [
                                        "A",
                                        "B",
                                        "C",
                                        "D",
                                        "-",
                                      ].contains(secilenCevap.toUpperCase())
                                      ? secilenCevap.toUpperCase()
                                      : "A";

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "$sNo.",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        DropdownButton<String>(
                                          value: gecerliSecenek,
                                          isDense: true,
                                          items: ["A", "B", "C", "D", "-"].map((
                                            s,
                                          ) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            );
                                          }).toList(),
                                          onChanged: (yeniDeger) {
                                            if (yeniDeger != null) {
                                              setState(() {
                                                _ogrenciCevaplari[ders]![sNo] =
                                                    yeniDeger;
                                              });
                                              _sonuclariHesaplaVePuanla(); // Şık değişince puanları otomatik güncelle
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
                    }),
                    const SizedBox(height: 15),
                  ],

                  // 5. HESAPLANAN SONUÇLAR ÖZETİ
                  if (_hesaplananSonuclar.isNotEmpty) ...[
                    const Text(
                      "Hesaplanan Başarı Özeti:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._hesaplananSonuclar.entries.map((entry) {
                      String ders = entry.key;
                      var res = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            ders,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Doğru: ${res['d']}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Yanlış: ${res['y']}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Boş: ${res['b']}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 6. KAYDET BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _secilenOgrenciId == null ? null : _kaydet,
                      child: const Text(
                        "Sonuçları Kaydet",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
