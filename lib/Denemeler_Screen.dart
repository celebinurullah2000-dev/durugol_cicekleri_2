// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafik paketi (pubspec.yaml'da ekli olmalıdır)

class DenemelerScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String userRole;
  final String grade;

  const DenemelerScreen({
    super.key,
    required this.classId,
    required this.className,
    this.userRole = 'classroom_teacher',
    this.grade = '2',
  });

  bool get _isSinifOgretmeni =>
      userRole.trim().toLowerCase() == 'classroom_teacher';

  void _yeniSinavEkleDialog(BuildContext context) {
    if (!_isSinifOgretmeni) return;

    final TextEditingController adiController = TextEditingController();
    DateTime? sinavTarihi;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Yeni Deneme Sınavı Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: adiController,
                      decoration: const InputDecoration(
                        labelText: "Sınav Adı (Örn: 1. Kurşun Kalem Deneme)",
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sinavTarihi == null
                              ? "Tarih Seçilmedi"
                              : "Tarih: ${sinavTarihi!.day}.${sinavTarihi!.month}.${sinavTarihi!.year}",
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? secilen = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2026),
                              lastDate: DateTime(2030),
                            );
                            if (secilen != null) {
                              setStateDialog(() => sinavTarihi = secilen);
                            }
                          },
                          child: const Text("Tarih Seç"),
                        ),
                      ],
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
                    if (adiController.text.isNotEmpty && sinavTarihi != null) {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .collection('denemeler')
                          .add({
                            'sinavAdi': adiController.text,
                            'tarih': Timestamp.fromDate(sinavTarihi!),
                          });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sinavSil(BuildContext context, String sinavId, String sinavAdi) {
    if (!_isSinifOgretmeni) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("'$sinavAdi' Sil"),
        content: const Text(
          "Bu deneme sınavını ve girilen tüm öğrenci sonuçlarını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
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

              try {
                var sonuclarSnapshot = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('denemeler')
                    .doc(sinavId)
                    .collection('sonuclar')
                    .get();

                for (var doc in sonuclarSnapshot.docs) {
                  await doc.reference.delete();
                }

                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('denemeler')
                    .doc(sinavId)
                    .delete();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Deneme sınavı başarıyla silindi."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Silme sırasında hata oluştu: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deneme Sınavları"),
        centerTitle: true,
        actions: [
          if (_isSinifOgretmeni)
            IconButton(
              icon: const Icon(Icons.add_circle, size: 28),
              tooltip: "Yeni Sınav Ekle",
              onPressed: () => _yeniSinavEkleDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('denemeler')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz eklenmiş deneme sınavı yok."),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String sinavAdi = data['sinavAdi'] ?? '';
              Timestamp? tarih = data['tarih'] as Timestamp?;
              String tarihStr = tarih != null
                  ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
                  : "";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    sinavAdi,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Yapılış Tarihi: $tarihStr"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.leaderboard,
                          color: Colors.indigo,
                        ),
                        tooltip: "Sınıf Sıralaması ve Toplu Sonuçlar",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SinifTopluSonucScreen(
                                classId: classId,
                                sinavId: doc.id,
                                sinavAdi: sinavAdi,
                                grade: grade,
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isSinifOgretmeni) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Denemeyi Sil",
                          onPressed: () => _sinavSil(context, doc.id, sinavAdi),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DenemeOgrenciListesiScreen(
                          classId: classId,
                          sinavId: doc.id,
                          sinavAdi: sinavAdi,
                          userRole: userRole,
                          grade: grade,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------
// 1. AŞAMA: SINAVA AİT ÖĞRENCİ LİSTESİ EKRANI
// ------------------------------------------------------------------
class DenemeOgrenciListesiScreen extends StatelessWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final String userRole;
  final String grade;

  const DenemeOgrenciListesiScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    this.userRole = 'classroom_teacher',
    this.grade = '2',
  });

  bool get _isSinifOgretmeni =>
      userRole.trim().toLowerCase() == 'classroom_teacher';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sinavAdi), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: classId)
            .snapshots(),
        builder: (context, studentSnap) {
          if (studentSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!studentSnap.hasData || studentSnap.data!.docs.isEmpty) {
            return const Center(child: Text("Bu sınıfta öğrenci bulunamadı."));
          }

          var students = List.from(studentSnap.data!.docs);

          students.sort((docA, docB) {
            var dataA = docA.data() as Map<String, dynamic>;
            var dataB = docB.data() as Map<String, dynamic>;

            String adA = dataA['firstName'] ?? '';
            String adB = dataB['firstName'] ?? '';
            int adKarsilastir = _turkceKarsilastir(adA, adB);

            if (adKarsilastir != 0) {
              return adKarsilastir;
            }

            String soyadA = dataA['lastName'] ?? '';
            String soyadB = dataB['lastName'] ?? '';
            return _turkceKarsilastir(soyadA, soyadB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              var studentDoc = students[index];
              var studentData = studentDoc.data() as Map<String, dynamic>;
              String studentId = studentDoc.id;
              String adSoyad =
                  "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('denemeler')
                    .doc(sinavId)
                    .collection('sonuclar')
                    .doc(studentId)
                    .get(),
                builder: (context, sonucSnap) {
                  bool girildiMi = sonucSnap.hasData && sonucSnap.data!.exists;

                  return Card(
                    child: ListTile(
                      title: Text(
                        adSoyad,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        girildiMi ? "Sonuçlar girilmiş ✅" : "Sonuç girilmedi ❌",
                      ),
                      trailing: _isSinifOgretmeni
                          ? const Icon(
                              Icons.edit_note,
                              color: Colors.indigo,
                              size: 28,
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OgrenciSinavGirisScreen(
                              classId: classId,
                              sinavId: sinavId,
                              studentId: studentId,
                              ogrenciAdi: adSoyad,
                              userRole: userRole,
                              grade: grade,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------
// 2. AŞAMA: ÖĞRENCİ DERS BAZLI GİRİŞ/GÖRÜNTÜLEME VE GRAFİK EKRANI
// ------------------------------------------------------------------
class OgrenciSinavGirisScreen extends StatefulWidget {
  final String classId;
  final String sinavId;
  final String studentId;
  final String ogrenciAdi;
  final String userRole;
  final String grade;

  const OgrenciSinavGirisScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.studentId,
    required this.ogrenciAdi,
    this.userRole = 'classroom_teacher',
    this.grade = '2',
  });

  @override
  State<OgrenciSinavGirisScreen> createState() =>
      _OgrenciSinavGirisScreenState();
}

class _OgrenciSinavGirisScreenState extends State<OgrenciSinavGirisScreen> {
  List<String> get dersler {
    String g = widget.grade.trim();
    if (g == '1') {
      return ["Türkçe", "Matematik", "Hayat Bilgisi"];
    } else if (g == '2') {
      return ["Türkçe", "Matematik", "Hayat Bilgisi", "İngilizce"];
    } else if (g == '3') {
      return [
        "Türkçe",
        "Matematik",
        "Hayat Bilgisi",
        "Fen Bilimleri",
        "İngilizce",
      ];
    } else if (g == '4') {
      return [
        "Türkçe",
        "Matematik",
        "Fen Bilimleri",
        "İngilizce",
        "Sosyal Bilgiler",
      ];
    }
    return ["Türkçe", "Matematik", "Hayat Bilgisi", "İngilizce"];
  }

  final Map<String, Map<String, TextEditingController>> controllers = {};
  bool yukleniyor = true;

  // Öğrencinin geçmiş sınav başarı yüzdelerini tutmak için (Grafik verisi)
  List<FlSpot> _grafikNoktalari = [];
  List<String> _sinavIsimleri = [];
  bool _grafikYukleniyor = true;

  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  @override
  void initState() {
    super.initState();
    for (var ders in dersler) {
      controllers[ders] = {
        'd': TextEditingController(),
        'y': TextEditingController(),
        'b': TextEditingController(),
      };
      if (_isSinifOgretmeni) {
        controllers[ders]?['d']?.addListener(_hesaplaVeGuncelle);
        controllers[ders]?['y']?.addListener(_hesaplaVeGuncelle);
        controllers[ders]?['b']?.addListener(_hesaplaVeGuncelle);
      }
    }
    _verileriGetir();
    _gecmisSinavVerileriniGetir();
  }

  @override
  void dispose() {
    for (var ders in dersler) {
      controllers[ders]?['d']?.dispose();
      controllers[ders]?['y']?.dispose();
      controllers[ders]?['b']?.dispose();
    }
    super.dispose();
  }

  void _hesaplaVeGuncelle() {
    setState(() {});
  }

  int get toplamDogru {
    int toplam = 0;
    for (var ders in dersler) {
      toplam += int.tryParse(controllers[ders]?['d']?.text ?? '0') ?? 0;
    }
    return toplam;
  }

  int get toplamYanlis {
    int toplam = 0;
    for (var ders in dersler) {
      toplam += int.tryParse(controllers[ders]?['y']?.text ?? '0') ?? 0;
    }
    return toplam;
  }

  int get toplamBos {
    int toplam = 0;
    for (var ders in dersler) {
      toplam += int.tryParse(controllers[ders]?['b']?.text ?? '0') ?? 0;
    }
    return toplam;
  }

  void _verileriGetir() async {
    var doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('denemeler')
        .doc(widget.sinavId)
        .collection('sonuclar')
        .doc(widget.studentId)
        .get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      for (var ders in dersler) {
        if (data.containsKey(ders)) {
          var dersData = data[ders] as Map<String, dynamic>;
          controllers[ders]?['d']?.text = (dersData['d'] ?? '').toString();
          controllers[ders]?['y']?.text = (dersData['y'] ?? '').toString();
          controllers[ders]?['b']?.text = (dersData['b'] ?? '').toString();
        }
      }
    }
    setState(() => yukleniyor = false);
  }

  // Öğrencinin geçmiş tüm sınavlarındaki başarı yüzdelerini hesaplayan fonksiyon
  Future<void> _gecmisSinavVerileriniGetir() async {
    try {
      // 1. Sınıfa ait tüm denemeleri tarihe göre sıralı çek
      var denemelerSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .orderBy('tarih', descending: false)
          .get();

      List<FlSpot> spots = [];
      List<String> sinavlar = [];
      int index = 0;

      for (var denemeDoc in denemelerSnap.docs) {
        String sId = denemeDoc.id;
        var sData = denemeDoc.data();
        String sAdi = sData['sinavAdi'] ?? 'Deneme';

        // O denemede bu öğrencinin sonuçlarını al
        var sonucDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('denemeler')
            .doc(sId)
            .collection('sonuclar')
            .doc(widget.studentId)
            .get();

        if (sonucDoc.exists) {
          var sonucData = sonucDoc.data() as Map<String, dynamic>;
          int sinavToplamDogru = 0;
          int sinavToplamSoru = 0;

          // Bu sınıf düzeyindeki derslere göre toplam doğru ve toplam soru sayısını hesapla
          for (var ders in dersler) {
            if (sonucData.containsKey(ders)) {
              var dersData = sonucData[ders] as Map<String, dynamic>? ?? {};
              int d = (dersData['d'] ?? 0) as int;
              int y = (dersData['y'] ?? 0) as int;
              int b = (dersData['b'] ?? 0) as int;

              sinavToplamDogru += d;
              sinavToplamSoru += (d + y + b);
            }
          }

          // Yüzde başarı hesabı (Doğru / Toplam Soru * 100)
          double basariYuzdesi = 0.0;
          if (sinavToplamSoru > 0) {
            basariYuzdesi = (sinavToplamDogru / sinavToplamSoru) * 100;
          }

          spots.add(FlSpot(index.toDouble(), basariYuzdesi));
          sinavlar.add(sAdi);
          index++;
        }
      }

      setState(() {
        _grafikNoktalari = spots;
        _sinavIsimleri = sinavlar;
        _grafikYukleniyor = false;
      });
    } catch (e) {
      setState(() => _grafikYukleniyor = false);
    }
  }

  void _kaydet() async {
    if (!_isSinifOgretmeni) return;

    Map<String, dynamic> kayitVerisi = {};
    for (var ders in dersler) {
      kayitVerisi[ders] = {
        'd': int.tryParse(controllers[ders]?['d']?.text ?? '0') ?? 0,
        'y': int.tryParse(controllers[ders]?['y']?.text ?? '0') ?? 0,
        'b': int.tryParse(controllers[ders]?['b']?.text ?? '0') ?? 0,
      };
    }

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('denemeler')
        .doc(widget.sinavId)
        .collection('sonuclar')
        .doc(widget.studentId)
        .set(kayitVerisi);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sonuçlar başarıyla kaydedildi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ogrenciAdi), centerTitle: true),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Üst Kısım: Toplam Özet Kartı
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              "Toplam Doğru",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "$toplamDogru",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              "Toplam Yanlış",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              "$toplamYanlis",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              "Toplam Boş",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$toplamBos",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ders Bazlı Giriş / Görüntüleme Alanları
                  ...dersler.map((ders) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ders,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controllers[ders]?['d'],
                                    keyboardType: TextInputType.number,
                                    readOnly: !_isSinifOgretmeni,
                                    decoration: const InputDecoration(
                                      labelText: "Doğru",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: controllers[ders]?['y'],
                                    keyboardType: TextInputType.number,
                                    readOnly: !_isSinifOgretmeni,
                                    decoration: const InputDecoration(
                                      labelText: "Yanlış",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: controllers[ders]?['b'],
                                    keyboardType: TextInputType.number,
                                    readOnly: !_isSinifOgretmeni,
                                    decoration: const InputDecoration(
                                      labelText: "Boş",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // --- GEÇMİŞ DENEME BAŞARI GRAFİĞİ (YÜZDE TABANLI) ---
                  const Text(
                    "Geçmiş Deneme Sınavları Başarı Grafiği (%)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 240, // Grafik alanını biraz genişlettik
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _grafikYukleniyor
                        ? const Center(child: CircularProgressIndicator())
                        : _grafikNoktalari.isEmpty
                        ? const Center(
                            child: Text(
                              "Henüz geçmiş sınav verisi bulunmuyor.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: _grafikNoktalari.isNotEmpty
                                  ? (_grafikNoktalari.length - 1).toDouble()
                                  : 0,
                              minY: 0,
                              maxY: 100,
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        "%${spot.y.toInt()}",
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 35,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        "${value.toInt()}%",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 45,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.toInt();
                                      if (idx >= 0 &&
                                          idx < _sinavIsimleri.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8.0,
                                          child: Transform.rotate(
                                            angle: -0.25,
                                            child: Text(
                                              _sinavIsimleri[idx],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _grafikNoktalari,
                                  isCurved: true,
                                  color: Colors.indigo,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.indigo.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Kaydet Butonu (Sadece Sınıf Öğretmeni İçin)
                  if (_isSinifOgretmeni)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _kaydet,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Sonuçları Kaydet",
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
}

// ------------------------------------------------------------------
// 3. SINIF TOPLU SONUÇLAR VE SIRALAMA EKRANI
// ------------------------------------------------------------------
class SinifTopluSonucScreen extends StatefulWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final String grade;

  const SinifTopluSonucScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    this.grade = '2',
  });

  @override
  State<SinifTopluSonucScreen> createState() => _SinifTopluSonucScreenState();
}

class _SinifTopluSonucScreenState extends State<SinifTopluSonucScreen> {
  String _siralamaTuru = 'alfabetik';

  List<String> get dersler {
    String g = widget.grade.trim();
    if (g == '1') {
      return ["Türkçe", "Matematik", "Hayat Bilgisi"];
    } else if (g == '2') {
      return ["Türkçe", "Matematik", "Hayat Bilgisi", "İngilizce"];
    } else if (g == '3') {
      return [
        "Türkçe",
        "Matematik",
        "Hayat Bilgisi",
        "Fen Bilimleri",
        "İngilizce",
      ];
    } else if (g == '4') {
      return [
        "Türkçe",
        "Matematik",
        "Fen Bilimleri",
        "İngilizce",
        "Sosyal Bilgiler",
      ];
    }
    return ["Türkçe", "Matematik", "Hayat Bilgisi", "İngilizce"];
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
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.sinavAdi} - Toplu Sonuçlar"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: "Sıralama Seçenekleri",
            onSelected: (value) {
              setState(() {
                _siralamaTuru = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'alfabetik',
                child: Text("🔤 Türkçe Alfabetik Sıralama"),
              ),
              const PopupMenuItem(
                value: 'dogru_azalan',
                child: Text("📈 Doğru Sayısına Göre (Çoktan Aza)"),
              ),
              const PopupMenuItem(
                value: 'dogru_artan',
                child: Text("📉 Doğru Sayısına Göre (Azdan Çoğa)"),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, studentSnap) {
          if (studentSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!studentSnap.hasData || studentSnap.data!.docs.isEmpty) {
            return const Center(child: Text("Bu sınıfta öğrenci bulunamadı."));
          }

          var students = studentSnap.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('denemeler')
                .doc(widget.sinavId)
                .collection('sonuclar')
                .snapshots(),
            builder: (context, sonucSnap) {
              if (sonucSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, dynamic>> sonuclarMap = {};
              if (sonucSnap.hasData) {
                for (var doc in sonucSnap.data!.docs) {
                  sonuclarMap[doc.id] = doc.data() as Map<String, dynamic>;
                }
              }

              List<Map<String, dynamic>> ogrenciListesi = [];

              for (var studentDoc in students) {
                String studentId = studentDoc.id;
                var studentData = studentDoc.data() as Map<String, dynamic>;
                String ad = studentData['firstName'] ?? '';
                String soyad = studentData['lastName'] ?? '';
                String adSoyad = "$ad $soyad";

                int toplamD = 0;
                int toplamY = 0;
                int toplamB = 0;

                if (sonuclarMap.containsKey(studentId)) {
                  var data = sonuclarMap[studentId]!;
                  for (var ders in dersler) {
                    if (data.containsKey(ders)) {
                      var dersData = data[ders] as Map<String, dynamic>? ?? {};
                      toplamD += (dersData['d'] ?? 0) as int;
                      toplamY += (dersData['y'] ?? 0) as int;
                      toplamB += (dersData['b'] ?? 0) as int;
                    }
                  }
                }

                ogrenciListesi.add({
                  'ad': ad,
                  'soyad': soyad,
                  'adSoyad': adSoyad,
                  'dogru': toplamD,
                  'yanlis': toplamY,
                  'bos': toplamB,
                });
              }

              if (_siralamaTuru == 'alfabetik') {
                ogrenciListesi.sort((a, b) {
                  int adKarsilastir = _turkceKarsilastir(a['ad'], b['ad']);
                  if (adKarsilastir != 0) return adKarsilastir;
                  return _turkceKarsilastir(a['soyad'], b['soyad']);
                });
              } else if (_siralamaTuru == 'dogru_azalan') {
                ogrenciListesi.sort(
                  (a, b) => (b['dogru'] as int).compareTo(a['dogru'] as int),
                );
              } else if (_siralamaTuru == 'dogru_artan') {
                ogrenciListesi.sort(
                  (a, b) => (a['dogru'] as int).compareTo(b['dogru'] as int),
                );
              }

              List<Map<String, dynamic>> siraliOgrenciListesi = [];
              int currentRank = 1;
              for (int i = 0; i < ogrenciListesi.length; i++) {
                if (_siralamaTuru.startsWith('dogru')) {
                  if (i > 0 &&
                      ogrenciListesi[i]['dogru'] !=
                          ogrenciListesi[i - 1]['dogru']) {
                    currentRank = i + 1;
                  }
                } else {
                  currentRank = i + 1;
                }

                var ogrenci = Map<String, dynamic>.from(ogrenciListesi[i]);
                ogrenci['sira'] = currentRank;
                siraliOgrenciListesi.add(ogrenci);
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              "Sıra",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Öğrenci Adı Soyadı",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              "Doğru",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              "Yanlış",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              "Boş",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: siraliOgrenciListesi.length,
                        itemBuilder: (context, index) {
                          var ogrenci = siraliOgrenciListesi[index];
                          bool highlight = index % 2 == 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: highlight
                                  ? Colors.grey.shade100
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "${ogrenci['sira']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ogrenci['adSoyad'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    "${ogrenci['dogru']}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    "${ogrenci['yanlis']}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    "${ogrenci['bos']}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
