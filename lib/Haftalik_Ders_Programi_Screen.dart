import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HaftalikDersProgramiScreen extends StatefulWidget {
  final String classId;
  final bool isTeacher;
  final String userRole;
  final String scheduleDocId; // Firebase'den okunacak yol/doküman adı
  final String sayfaBasligi; // AppBar başlığı
  final bool canEdit; // Düzenleme yetkisi var mı?
  final bool
  isBranchSchedule; // true ise ders adı yerine şube (2/A vb.) seçilir

  const HaftalikDersProgramiScreen({
    super.key,
    required this.classId,
    required this.isTeacher,
    this.userRole = 'classroom_teacher',
    this.scheduleDocId = 'haftalik',
    this.sayfaBasligi = "Haftalık Ders Programı",
    this.canEdit = false,
    this.isBranchSchedule = false,
  });

  @override
  State<HaftalikDersProgramiScreen> createState() =>
      _HaftalikDersProgramiScreenState();
}

class _HaftalikDersProgramiScreenState extends State<HaftalikDersProgramiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
  ];

  // Sınıf programları için standart ders listesi (Boş ve Teneffüs dahil)
  final List<String> dersSecenekleri = [
    'Boş',
    'Teneffüs',
    'Türkçe',
    'Matematik',
    'Hayat Bilgisi',
    'İngilizce',
    'Görsel Sanatlar',
    'Müzik',
    'Beden Eğitimi ve Oyun',
    'Serbest Etkinlikler',
    'Oyun ve Fiziki Etkinlikler',
    'Etüt: Modern Dans',
    'Etüt: Halk Oyunları',
    'Etüt: Zeka Oyunları',
    'Etüt: Ödev',
    'Etüt: Satranç',
    'Etüt: Drama',
    'Etüt: Resim',
    'Etüt: Müzik & Ritm',
    'Etüt: Müzik & Enstrüman',
    'Etüt: Kodlama',
    'Etüt: Robotik',
    'Etüt: Yüzme',
    'Etüt: Jimnastik',
    'Etüt: Basketbol',
    'Etüt: Voleybol',
    'Etüt: Futbol',
    'Etüt: Tenis',
    'Etüt: Atletizm',
    'Etüt: Masa Tenisi',
  ];

  // Branş/Şube programları için veritabanından dinamik olarak çekilecek şube listesi
  List<String> dinamikSubeler = ['Boş', 'Teneffüs'];
  bool subelerYukleniyor = true;

  late List<TextEditingController> saatControllers;
  late List<List<String>> dersMatrisi;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.canEdit ? 2 : 1, vsync: this);

    saatControllers = List.generate(
      15,
      (index) => TextEditingController(text: "${9 + (index ~/ 2)}:00"),
    );
    dersMatrisi = List.generate(15, (_) => List.generate(5, (_) => 'Boş'));

    // Eğer branş programı ise şubeleri Firebase'den çek
    if (widget.isBranchSchedule) {
      _subeleriGetir();
    } else {
      subelerYukleniyor = false;
    }

    programiGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in saatControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Firebase'den classes koleksiyonundaki className değerlerini çekme
  Future<void> _subeleriGetir() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      List<String> subeler = ['Boş', 'Teneffüs'];

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String? className = data['className']; // Örn: "2/A", "4/B"

        if (className != null && className.isNotEmpty) {
          // --- BURASI EKLENDİ / GÜNCELLENDİ ---
          // Sadece gerçek sınıf/şube isimlerini almak için içinde "/" geçip geçmediğini
          // ve "Branş" veya "İdareci" gibi ifadeler içermediğini kontrol ediyoruz.
          if (className.contains('/') &&
              !className.contains('Öğretmen') &&
              !className.contains('İdareci')) {
            if (widget.scheduleDocId == 'branch_religion') {
              // Sadece 4. sınıflar
              if (className.startsWith('4/')) {
                subeler.add(className);
              }
            } else if (widget.scheduleDocId == 'branch_english') {
              // 2, 3 ve 4. sınıflar
              if (className.startsWith('2/') ||
                  className.startsWith('3/') ||
                  className.startsWith('4/')) {
                subeler.add(className);
              }
            } else {
              // Kişisel branş programı için tüm geçerli sınıflar
              subeler.add(className);
            }
          }
        }
      }

      // Şube listesini sıralama
      subeler.sort();

      setState(() {
        dinamikSubeler = subeler;
        subelerYukleniyor = false;
      });
    } catch (e) {
      setState(() {
        subelerYukleniyor = false;
      });
    }
  }

  Future<void> programiGetir() async {
    try {
      DocumentReference docRef;
      if (widget.scheduleDocId == 'haftalik') {
        docRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('program')
            .doc(widget.scheduleDocId);
      } else {
        docRef = FirebaseFirestore.instance
            .collection('branch_schedules')
            .doc(widget.scheduleDocId);
      }

      var doc = await docRef.get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          if (data.containsKey('saatler')) {
            List<dynamic> savedSaatler = data['saatler'];
            for (int i = 0; i < savedSaatler.length && i < 15; i++) {
              saatControllers[i].text = savedSaatler[i].toString();
            }
          }
          if (data.containsKey('satirlar')) {
            List<dynamic> savedSatirlar = data['satirlar'];
            for (int i = 0; i < savedSatirlar.length && i < 15; i++) {
              var satirItem = savedSatirlar[i];
              if (satirItem is Map && satirItem.containsKey('gunler')) {
                List<dynamic> gunlerListesi = satirItem['gunler'];
                for (int j = 0; j < gunlerListesi.length && j < 5; j++) {
                  dersMatrisi[i][j] = gunlerListesi[j].toString();
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Hata yönetimi
    }
    setState(() {
      yukleniyor = false;
    });
  }

  Future<void> programiKaydet() async {
    setState(() => yukleniyor = true);
    try {
      List<String> saatlerListesi = saatControllers
          .map((c) => c.text.trim())
          .toList();

      List<Map<String, dynamic>> matrisVerisi = [];
      for (int i = 0; i < dersMatrisi.length; i++) {
        List<String> satirListesi = [];
        for (int j = 0; j < dersMatrisi[i].length; j++) {
          satirListesi.add(dersMatrisi[i][j]);
        }
        matrisVerisi.add({'gunler': satirListesi});
      }

      DocumentReference docRef;
      if (widget.scheduleDocId == 'haftalik') {
        docRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('program')
            .doc(widget.scheduleDocId);
      } else {
        docRef = FirebaseFirestore.instance
            .collection('branch_schedules')
            .doc(widget.scheduleDocId);
      }

      await docRef.set({'saatler': saatlerListesi, 'satirlar': matrisVerisi});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ders programı başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kaydedilirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sayfaBasligi),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: widget.canEdit
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_month),
                    text: "Programı Görüntüle",
                  ),
                  Tab(
                    icon: Icon(Icons.edit_calendar),
                    text: "Programı Düzenle",
                  ),
                ],
              )
            : null,
      ),
      body: (yukleniyor || subelerYukleniyor)
          ? const Center(child: CircularProgressIndicator())
          : widget.canEdit
          ? TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildGoruntulemeSekmesi(), _buildDuzenlemeSekmesi()],
            )
          : _buildGoruntulemeSekmesi(),
    );
  }

  // --- 1. SEKME: PROGRAMI GÖRÜNTÜLE ---
  Widget _buildGoruntulemeSekmesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, gunIndex) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            initiallyExpanded: gunIndex == 0,
            title: Text(
              gunler[gunIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.indigo,
              ),
            ),
            subtitle: const Text("Günlük ders programını görmek için dokunun"),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < 15; i++)
                      () {
                        bool isTenOrOgle =
                            (i == 1 ||
                            i == 3 ||
                            i == 5 ||
                            i == 7 ||
                            i == 9 ||
                            i == 11 ||
                            i == 13);

                        if (isTenOrOgle) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              i == 7
                                  ? "--- ÖĞLE ARASI ---"
                                  : "--- TENEFFÜS ---",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: i == 7 ? Colors.deepOrange : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          );
                        }

                        String deger = dersMatrisi[i][gunIndex];
                        bool bosMu = (deger == 'Boş' || deger.isEmpty);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: bosMu ? Colors.white : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 75,
                                child: Text(
                                  saatControllers[i].text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    bosMu ? "-" : deger.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: bosMu
                                          ? Colors.grey.shade400
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 75),
                            ],
                          ),
                        );
                      }(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. SEKME: PROGRAMI DÜZENLE ---
  Widget _buildDuzenlemeSekmesi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: ExpansionTile(
              title: const Text(
                "Ders Saatlerini Düzenle",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              subtitle: const Text(
                "Ders başlangıç ve bitiş saatlerini değiştirebilirsiniz.",
              ),
              children: [
                for (int i = 0; i < 15; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${i + 1}. Ders/Etkinlik: ",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: saatControllers[i],
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isBranchSchedule
                ? "Günlere Göre Şube Atama:"
                : "Günlere Göre Ders Atama:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          for (int gunIndex = 0; gunIndex < 5; gunIndex++)
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                title: Text(
                  gunler[gunIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  widget.isBranchSchedule
                      ? "Bu günün şube programını ayarlamak için dokunun"
                      : "Bu günün ders programını ayarlamak için dokunun",
                ),
                children: _buildGunDersSecimListesi(gunIndex),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: programiKaydet,
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: const Text(
                "Değişiklikleri ve Programı Kaydet",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  List<Widget> _buildGunDersSecimListesi(int gunIndex) {
    List<Widget> liste = [];

    // Hangi listenin seçileceğini belirliyoruz (Sınıf için dersSecenekleri, Branş için dinamikSubeler)
    List<String> seceneklerListesi = widget.isBranchSchedule
        ? dinamikSubeler
        : dersSecenekleri;

    for (int i = 0; i < 15; i++) {
      bool isTenOrOgle =
          (i == 1 ||
          i == 3 ||
          i == 5 ||
          i == 7 ||
          i == 9 ||
          i == 11 ||
          i == 13);

      if (isTenOrOgle) {
        liste.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Text(
              i == 7 ? "--- ÖĞLE ARASI ---" : "--- TENEFFÜS ---",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        );
      } else {
        liste.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    saatControllers[i].text,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        seceneklerListesi.contains(dersMatrisi[i][gunIndex])
                        ? dersMatrisi[i][gunIndex]
                        : 'Boş',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: seceneklerListesi.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? yeniDeger) {
                      if (yeniDeger != null) {
                        setState(() {
                          dersMatrisi[i][gunIndex] = yeniDeger;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    liste.add(const SizedBox(height: 10));
    return liste;
  }
}
