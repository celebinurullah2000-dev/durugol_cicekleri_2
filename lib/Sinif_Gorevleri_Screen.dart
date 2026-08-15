// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SinifGorevleriScreen extends StatefulWidget {
  final String classId;
  final String
  userRole; // Yeni eklenen rol parametresi ('classroom_teacher', 'branch_teacher', 'admin')

  const SinifGorevleriScreen({
    super.key,
    required this.classId,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<SinifGorevleriScreen> createState() => _SinifGorevleriScreenState();
}

class _SinifGorevleriScreenState extends State<SinifGorevleriScreen> {
  bool _secimModuAktif = false;
  bool _veriYukleniyor = true;

  List<Map<String, dynamic>> _kizOgrenciler = [];
  List<Map<String, dynamic>> _erkekOgrenciler = [];
  List<String> _eskiGorevliIds = [];

  Map<String, dynamic>? _aktifKizGorevli;
  Map<String, dynamic>? _aktifErkekGorevli;
  DateTime? _kizBaslangicTarihi;
  DateTime? _erkekBaslangicTarihi;

  final List<String?> _secilenKizAdaylar = [null, null, null];
  final List<String?> _secilenErkekAdaylar = [null, null, null];

  final List<TextEditingController> _kizOyControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _erkekOyControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  @override
  void dispose() {
    for (var c in _kizOyControllers) {
      c.dispose();
    }
    for (var c in _erkekOyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verileriGetir() async {
    setState(() => _veriYukleniyor = true);
    try {
      var ogrenciSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      List<Map<String, dynamic>> kizlar = [];
      List<Map<String, dynamic>> erkekler = [];

      for (var doc in ogrenciSnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        String firstName = (data['firstName'] ?? '').toString().trim();
        String lastName = (data['lastName'] ?? '').toString().trim();
        data['adSoyad'] = "$firstName $lastName".trim();

        String gender = (data['gender'] ?? '').toString().trim().toUpperCase();

        if (gender == 'K') {
          kizlar.add(data);
        } else if (gender == 'E') {
          erkekler.add(data);
        }
      }

      kizlar.sort(
        (a, b) => (a['adSoyad'] ?? '').toString().compareTo(b['adSoyad'] ?? ''),
      );
      erkekler.sort(
        (a, b) => (a['adSoyad'] ?? '').toString().compareTo(b['adSoyad'] ?? ''),
      );

      var gecmisSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('gecmisGorevliler')
          .get();

      List<String> eskiIds = [];
      for (var doc in gecmisSnapshot.docs) {
        eskiIds.add(doc.data()['ogrenciId']);
      }

      var aktifDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('aktifGorevliler')
          .doc('mevcut')
          .get();

      if (aktifDoc.exists) {
        var data = aktifDoc.data();
        if (data != null) {
          _aktifKizGorevli = data['kiz'];
          _kizBaslangicTarihi = (data['kizBaslangic'] as Timestamp?)?.toDate();

          _aktifErkekGorevli = data['erkek'];
          _erkekBaslangicTarihi = (data['erkekBaslangic'] as Timestamp?)
              ?.toDate();
        }
      }

      setState(() {
        _kizOgrenciler = kizlar;
        _erkekOgrenciler = erkekler;
        _eskiGorevliIds = eskiIds;
        _veriYukleniyor = false;
      });
    } catch (e) {
      setState(() => _veriYukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veriler yüklenirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _uygunAdaylariGetir(
    String cinsiyet,
    int currentIndex,
  ) {
    bool arananKizMi = cinsiyet == 'Kiz';

    List<Map<String, dynamic>> kaynakListe = arananKizMi
        ? _kizOgrenciler
        : _erkekOgrenciler;
    List<String?> seciliDigerleri = arananKizMi
        ? _secilenKizAdaylar
        : _secilenErkekAdaylar;

    String? aktifKizId = _aktifKizGorevli?['id'];
    String? aktifErkekId = _aktifErkekGorevli?['id'];

    return kaynakListe.where((ogrenci) {
      String id = ogrenci['id'];

      if (_eskiGorevliIds.contains(id)) return false;

      if (arananKizMi && id == aktifKizId) return false;
      if (!arananKizMi && id == aktifErkekId) return false;

      for (int i = 0; i < seciliDigerleri.length; i++) {
        if (i != currentIndex && seciliDigerleri[i] == id) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _secimiSonlandir() async {
    for (int i = 0; i < 3; i++) {
      if (_secilenKizAdaylar[i] == null || _secilenErkekAdaylar[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen tüm aday slotlarını doldurun!"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    try {
      int enCokKizOy = -1;
      String? secilenKizId;
      Map<String, dynamic>? yeniKizData;

      for (int i = 0; i < 3; i++) {
        int oy = int.tryParse(_kizOyControllers[i].text) ?? 0;
        if (oy > enCokKizOy) {
          enCokKizOy = oy;
          secilenKizId = _secilenKizAdaylar[i];
          yeniKizData = _kizOgrenciler.firstWhere(
            (o) => o['id'] == secilenKizId,
          );
        }
      }

      int enCokErkekOy = -1;
      String? secilenErkekId;
      Map<String, dynamic>? yeniErkekData;

      for (int i = 0; i < 3; i++) {
        int oy = int.tryParse(_erkekOyControllers[i].text) ?? 0;
        if (oy > enCokErkekOy) {
          enCokErkekOy = oy;
          secilenErkekId = _secilenErkekAdaylar[i];
          yeniErkekData = _erkekOgrenciler.firstWhere(
            (o) => o['id'] == secilenErkekId,
          );
        }
      }

      DateTime simdi = DateTime.now();
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (_aktifKizGorevli != null) {
        int gorevdeKaldigiGun = _kizBaslangicTarihi != null
            ? simdi.difference(_kizBaslangicTarihi!).inDays
            : 0;
        var gecmisRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('gecmisGorevliler')
            .doc();
        batch.set(gecmisRef, {
          'ogrenciId': _aktifKizGorevli!['id'],
          'adSoyad': _aktifKizGorevli!['adSoyad'],
          'cinsiyet': 'Kız',
          'baslangicTarihi': Timestamp.fromDate(_kizBaslangicTarihi ?? simdi),
          'bitisTarihi': Timestamp.fromDate(simdi),
          'gorevdeKaldigiGun': gorevdeKaldigiGun,
          'aldigiOy': -1,
        });
      }

      if (_aktifErkekGorevli != null) {
        int gorevdeKaldigiGun = _erkekBaslangicTarihi != null
            ? simdi.difference(_erkekBaslangicTarihi!).inDays
            : 0;
        var gecmisRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('gecmisGorevliler')
            .doc();
        batch.set(gecmisRef, {
          'ogrenciId': _aktifErkekGorevli!['id'],
          'adSoyad': _aktifErkekGorevli!['adSoyad'],
          'cinsiyet': 'Erkek',
          'baslangicTarihi': Timestamp.fromDate(_erkekBaslangicTarihi ?? simdi),
          'bitisTarihi': Timestamp.fromDate(simdi),
          'gorevdeKaldigiGun': gorevdeKaldigiGun,
          'aldigiOy': -1,
        });
      }

      var aktifRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('aktifGorevliler')
          .doc('mevcut');
      batch.set(aktifRef, {
        'kiz': yeniKizData,
        'kizBaslangic': Timestamp.fromDate(simdi),
        'erkek': yeniErkekData,
        'erkekBaslangic': Timestamp.fromDate(simdi),
      });

      await batch.commit();

      setState(() {
        _secimModuAktif = false;
        for (var c in _kizOyControllers) {
          c.clear();
        }
        for (var c in _erkekOyControllers) {
          c.clear();
        }
        _secilenKizAdaylar.fillRange(0, 3, null);
        _secilenErkekAdaylar.fillRange(0, 3, null);
      });

      _verileriGetir();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yeni sınıf görevlileri başarıyla seçildi! 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kayıt sırasında hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _gecmisGorevlileriGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eski Sınıf Görevlileri Arşivi"),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('gecmisGorevliler')
                .orderBy('bitisTarihi', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Henüz geçmiş görevli kaydı bulunmuyor.");
              }
              var docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String ad = data['adSoyad'] ?? '';
                  String cinsiyet = data['cinsiyet'] ?? '';
                  int gun = data['gorevdeKaldigiGun'] ?? 0;
                  Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
                  String tarihStr = bitis != null
                      ? "${bitis.toDate().day}.${bitis.toDate().month}.${bitis.toDate().year}"
                      : "";

                  return ListTile(
                    leading: Icon(
                      cinsiyet == 'Kız' ? Icons.girl : Icons.boy,
                      color: Colors.indigo,
                    ),
                    title: Text(
                      ad,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Görev Süresi: $gun gün\nBitiş Tarihi: $tarihStr",
                    ),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_veriYukleniyor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sadece sınıf öğretmeni ise yeni seçim başlatma butonuna izin verilir (İdareci ve Branş Öğretmeninde gizlenir)
    bool isSinifOgretmeni = widget.userRole == 'classroom_teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Görevlileri Modülü"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: "Eski Görevliler Arşivi",
            onPressed: _gecmisGorevlileriGoster,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Mevcut Sınıf Görevlileri",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _gorevliKarti(
                          "Kız Görevli",
                          _aktifKizGorevli,
                          _kizBaslangicTarihi,
                          Icons.girl,
                        ),
                        _gorevliKarti(
                          "Erkek Görevli",
                          _aktifErkekGorevli,
                          _erkekBaslangicTarihi,
                          Icons.boy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sadece sınıf öğretmeniyse "Yeni Seçim Başlat" butonu görünsün
            if (isSinifOgretmeni) ...[
              if (!_secimModuAktif) ...[
                ElevatedButton.icon(
                  onPressed: () => setState(() => _secimModuAktif = true),
                  icon: const Icon(Icons.how_to_vote, size: 24),
                  label: const Text(
                    "Yeni Seçim Başlat",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const Text(
                  "Aday Öğrenci Seçimi ve Oy Girişi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Not: Daha önce görev yapmış olanlar aday listesinde görünmez.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Kız Adaylar ve Oylar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < 3; i++) _adaySatiriOlustur('Kiz', i),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Erkek Adaylar ve Oylar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < 3; i++) _adaySatiriOlustur('Erkek', i),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _secimModuAktif = false),
                      child: const Text("İptal Et"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _secimiSonlandir,
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Seçimi Sonlandır ve Kaydet"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _gorevliKarti(
    String baslik,
    Map<String, dynamic>? gorevli,
    DateTime? baslangicTarihi,
    IconData ikon,
  ) {
    String ad = gorevli != null
        ? (gorevli['adSoyad'] ?? 'Atanmadı')
        : 'Henüz Seçilmedi';
    String tarihStr = '';
    if (baslangicTarihi != null) {
      tarihStr =
          "Başlangıç: ${baslangicTarihi.day}.${baslangicTarihi.month}.${baslangicTarihi.year}";
    }

    return Column(
      children: [
        Icon(ikon, size: 40, color: Colors.indigo),
        const SizedBox(height: 4),
        Text(baslik, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          ad,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        if (tarihStr.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            tarihStr,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  Widget _adaySatiriOlustur(String cinsiyet, int index) {
    List<Map<String, dynamic>> uygunAdaylar = _uygunAdaylariGetir(
      cinsiyet,
      index,
    );
    List<String?> secilenler = (cinsiyet == 'Kiz')
        ? _secilenKizAdaylar
        : _secilenErkekAdaylar;
    TextEditingController oyController = (cinsiyet == 'Kiz')
        ? _kizOyControllers[index]
        : _erkekOyControllers[index];
    String gorunenCinsiyet = (cinsiyet == 'Kiz') ? 'Kız' : 'Erkek';

    String? secilenOgrenciAdi;
    if (secilenler[index] != null) {
      var bulunan = uygunAdaylar.firstWhere(
        (o) => o['id'] == secilenler[index],
        orElse: () => {'adSoyad': '${index + 1}. $gorunenCinsiyet Aday Seç'},
      );
      secilenOgrenciAdi = bulunan['adSoyad'];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: oyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Oy",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("${index + 1}. $gorunenCinsiyet Adayı Seç"),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: uygunAdaylar.length,
                        itemBuilder: (context, itemIndex) {
                          var ogrenci = uygunAdaylar[itemIndex];
                          return ListTile(
                            title: Text(ogrenci['adSoyad'] ?? ''),
                            onTap: () {
                              setState(() {
                                secilenler[index] = ogrenci['id'];
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            secilenler[index] = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Seçimi Temizle",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("İptal"),
                      ),
                    ],
                  ),
                );
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        secilenler[index] == null
                            ? "${index + 1}. $gorunenCinsiyet Aday Seç"
                            : (secilenOgrenciAdi ??
                                  "${index + 1}. $gorunenCinsiyet Aday Seç"),
                        style: TextStyle(
                          color: secilenler[index] == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
