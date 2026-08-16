// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NobetciScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  final bool isTeacher;
  final String userRole; // ('classroom_teacher', 'branch_teacher', 'admin')

  const NobetciScreen({
    super.key,
    required this.studentId,
    required this.classId,
    this.isTeacher = false,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<NobetciScreen> createState() => _NobetciScreenState();
}

class _NobetciScreenState extends State<NobetciScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _bugunNobetciler = [];
  bool _isWeekend = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bugunNobetcileriGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bugunNobetcileriGetir() async {
    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    if (now.weekday == 6 || now.weekday == 7) {
      setState(() {
        _isWeekend = true;
        _isLoading = false;
      });
      return;
    }

    String dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      DocumentSnapshot dutySnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('duty_records')
          .doc(dateKey)
          .get();

      if (dutySnapshot.exists) {
        var data = dutySnapshot.data() as Map<String, dynamic>?;
        var list = data?['nobetciler'] as List<dynamic>? ?? [];
        setState(() {
          _bugunNobetciler = list
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      } else {
        setState(() {
          _bugunNobetciler = [];
        });
      }
    } catch (e) {
      debugPrint("Nöbetçileri getirme hatası: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _tumSinifSiciliniSifirla() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    for (var doc in snapshot.docs) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(doc.id)
          .update({'hasBeenOnDuty': false});
    }
  }

  void _manuelNobetAtamaDialogAc(BuildContext context) {
    int secilenKisiSayisi = 2; // Standart: 2
    String secilenCinsiyet = 'Kız-Erkek'; // Standart: Kız-Erkek
    String secilenGecmisDurumu = 'Hariç tutulsun'; // Standart: Hariç tutulsun

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Manuel Nöbetçi Atama"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "1. Aynı Gün Atanacak Kişi Sayısı:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: secilenKisiSayisi,
                      isExpanded: true,
                      items: [1, 2, 3, 4, 5].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value Kişi"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => secilenKisiSayisi = val);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "2. Cinsiyet Dağılımı:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: secilenCinsiyet,
                      isExpanded: true,
                      items:
                          [
                            'Kız-Kız',
                            'Erkek-Erkek',
                            'Kız-Erkek',
                            'Farketmez',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => secilenCinsiyet = val);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "3. Daha Önce Nöbet Görevi Alanlar:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: secilenGecmisDurumu,
                      isExpanded: true,
                      items: ['Dahil edilsin', 'Hariç tutulsun'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => secilenGecmisDurumu = val);
                        }
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
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _rastgeleSecimUygula(
                      secilenKisiSayisi,
                      secilenCinsiyet,
                      secilenGecmisDurumu,
                    );
                  },
                  child: const Text("🎲 Rastgele Seç"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _adaySecimListesiniAc(
                      context,
                      secilenKisiSayisi,
                      secilenCinsiyet,
                      secilenGecmisDurumu,
                    );
                  },
                  child: const Text("İleri / Seç"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rastgeleSecimUygula(
    int kisiSayisi,
    String cinsiyetKriteri,
    String gecmisKriteri,
  ) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      var students = snapshot.docs;

      var havuz = students.where((doc) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        bool nobetMusait = data['nobetMusait'] ?? true;
        if (!nobetMusait) return false;

        bool hasBeenOnDuty = data['hasBeenOnDuty'] ?? false;
        if (gecmisKriteri == 'Hariç tutulsun' && hasBeenOnDuty) {
          return false;
        }

        String gender = data['gender'] ?? 'K';
        if (cinsiyetKriteri == 'Kız-Kız' && gender != 'K') return false;
        if (cinsiyetKriteri == 'Erkek-Erkek' && gender != 'E') return false;

        return true;
      }).toList();

      if (havuz.length < kisiSayisi && gecmisKriteri == 'Hariç tutulsun') {
        await _tumSinifSiciliniSifirla();

        snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .get();
        students = snapshot.docs;

        havuz = students.where((doc) {
          var data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;
          bool nobetMusait = data['nobetMusait'] ?? true;
          if (!nobetMusait) return false;

          String gender = data['gender'] ?? 'K';
          if (cinsiyetKriteri == 'Kız-Kız' && gender != 'K') return false;
          if (cinsiyetKriteri == 'Erkek-Erkek' && gender != 'E') return false;

          return true;
        }).toList();
      }

      List<DocumentSnapshot> secilenler = [];

      if (cinsiyetKriteri == 'Kız-Erkek' && kisiSayisi == 2) {
        var kizlar = havuz.where((d) {
          var data = d.data() as Map<String, dynamic>?;
          return data?['gender'] == 'K';
        }).toList();
        var erkekler = havuz.where((d) {
          var data = d.data() as Map<String, dynamic>?;
          return data?['gender'] == 'E';
        }).toList();

        kizlar.shuffle();
        erkekler.shuffle();

        if (kizlar.isNotEmpty && erkekler.isNotEmpty) {
          secilenler.add(kizlar.first);
          secilenler.add(erkekler.first);
        }
      }

      if (secilenler.length < kisiSayisi) {
        havuz.shuffle();
        for (var doc in havuz) {
          if (!secilenler.contains(doc) && secilenler.length < kisiSayisi) {
            secilenler.add(doc);
          }
        }
      }

      if (secilenler.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Belirlediğiniz kriterlere uygun öğrenci bulunamadı!",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      List<String> secilenIdler = secilenler.map((e) => e.id).toList();
      await _secilenNobetcileriKaydet(secilenIdler);
    } catch (e) {
      debugPrint("Rastgele atama hatası: $e");
    }
  }

  void _adaySecimListesiniAc(
    BuildContext context,
    int kisiSayisi,
    String cinsiyetKriteri,
    String gecmisKriteri,
  ) {
    List<String> secilenOgrenciIdleri = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Nöbetçi Seç ($kisiSayisi Kişi)"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('students')
                      .where('classId', isEqualTo: widget.classId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var students = snapshot.data!.docs;

                    var filtrelenmisOgrenciler = students.where((doc) {
                      var data = doc.data() as Map<String, dynamic>?;
                      if (data == null) return false;
                      bool nobetMusait = data['nobetMusait'] ?? true;
                      if (!nobetMusait) return false;

                      bool hasBeenOnDuty = data['hasBeenOnDuty'] ?? false;
                      if (gecmisKriteri == 'Hariç tutulsun' && hasBeenOnDuty) {
                        return false;
                      }

                      String gender = data['gender'] ?? 'K';
                      if (cinsiyetKriteri == 'Kız-Kız' && gender != 'K') {
                        return false;
                      }
                      if (cinsiyetKriteri == 'Erkek-Erkek' && gender != 'E') {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (filtrelenmisOgrenciler.isEmpty &&
                        gecmisKriteri == 'Hariç tutulsun') {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Nöbet tutmayan uygun öğrenci kalmadı.\nTüm sınıfın nöbet geçmişi sıfırlansın mı?",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                await _tumSinifSiciliniSifirla();
                                setDialogState(() {});
                              },
                              child: const Text("Tüm Sınıfın Sicilini Sıfırla"),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtrelenmisOgrenciler.length,
                      itemBuilder: (context, index) {
                        var ogrenciDoc = filtrelenmisOgrenciler[index];
                        var ogrenciData =
                            ogrenciDoc.data() as Map<String, dynamic>? ?? {};
                        String ogrenciId = ogrenciDoc.id;
                        String adSoyad =
                            "${ogrenciData['firstName'] ?? ''} ${ogrenciData['lastName'] ?? ''}";
                        String cinsiyet = ogrenciData['gender'] == 'K'
                            ? 'Kız 👧'
                            : 'Erkek 👦';

                        bool seciliMi = secilenOgrenciIdleri.contains(
                          ogrenciId,
                        );

                        return CheckboxListTile(
                          title: Text(adSoyad),
                          subtitle: Text("Cinsiyet: $cinsiyet"),
                          value: seciliMi,
                          onChanged: (bool? deger) {
                            setDialogState(() {
                              if (deger == true) {
                                if (secilenOgrenciIdleri.length < kisiSayisi) {
                                  secilenOgrenciIdleri.add(ogrenciId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "En fazla $kisiSayisi kişi seçebilirsiniz!",
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                secilenOgrenciIdleri.remove(ogrenciId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: secilenOgrenciIdleri.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _secilenNobetcileriKaydet(secilenOgrenciIdleri);
                        },
                  child: const Text("Ata ve Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _secilenNobetcileriKaydet(List<String> ogrenciIdleri) async {
    DateTime now = DateTime.now();
    String dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    List<Map<String, dynamic>> yeniNobetciListesi = [];
    List<String> secilenIsimler = [];

    for (String id in ogrenciIdleri) {
      var doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(id)
          .get();
      if (doc.exists) {
        var data = doc.data();
        if (data != null) {
          String adSoyad =
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
          yeniNobetciListesi.add({'id': id, 'name': adSoyad});
          secilenIsimler.add(adSoyad);
        }

        await FirebaseFirestore.instance.collection('students').doc(id).update({
          'hasBeenOnDuty': true,
        });
      }
    }

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('duty_records')
        .doc(dateKey)
        .set({'date': dateKey, 'nobetciler': yeniNobetciListesi});

    _bugunNobetcileriGetir();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Nöbetçi Ataması Tamamlandı"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bugün için görevlendirilen öğrenciler:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...secilenIsimler.map(
              (isim) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      isim,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Harika!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String bugunTarihStr =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    bool isSinifOgretmeni = widget.userRole == 'classroom_teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nöbetçi Öğrenci Takibi"),
        actions: [
          if (widget.isTeacher && isSinifOgretmeni)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, size: 28),
              tooltip: "Nöbetçi Ata",
              onPressed: () => _manuelNobetAtamaDialogAc(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Güncel Nöbetçiler & Liste", icon: Icon(Icons.today)),
            Tab(text: "Geçmiş Nöbetler", icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                        Text(
                          "Tarih: $bugunTarihStr",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                        const Divider(height: 20),
                        _isWeekend
                            ? const Text(
                                "Bugün hafta sonu, nöbetçi öğrenci bulunmuyor.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : _isLoading
                            ? const CircularProgressIndicator()
                            : _bugunNobetciler.isEmpty
                            ? const Text(
                                "Bugün için henüz nöbetçi atanmadı. Üstteki butondan atayabilirsiniz.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: _bugunNobetciler.map((nobetci) {
                                  return Chip(
                                    avatar: const CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    label: Text(
                                      nobetci['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Sınıf Öğrenci Listesi ve Nöbet Durumları",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('students')
                                  .where('classId', isEqualTo: widget.classId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      "Bu sınıfta öğrenci bulunamadı.",
                                    ),
                                  );
                                }

                                int turkceKarsilastir(String a, String b) {
                                  const String turkceAlfabe =
                                      'aabcçdefgğhıijklmnoöprsştuüvyz';

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
                                    int indexA = turkceAlfabe.indexOf(
                                      aKucuk[i],
                                    );
                                    int indexB = turkceAlfabe.indexOf(
                                      bKucuk[i],
                                    );

                                    if (indexA == -1 || indexB == -1) {
                                      int comp = aKucuk
                                          .codeUnitAt(i)
                                          .compareTo(bKucuk.codeUnitAt(i));
                                      if (comp != 0) return comp;
                                    } else if (indexA != indexB) {
                                      return indexA.compareTo(indexB);
                                    }
                                  }

                                  return aKucuk.length.compareTo(bKucuk.length);
                                }

                                var students = snapshot.data!.docs;

                                students.sort((a, b) {
                                  var dataA =
                                      a.data() as Map<String, dynamic>? ?? {};
                                  var dataB =
                                      b.data() as Map<String, dynamic>? ?? {};
                                  String nameA =
                                      "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                                  String nameB =
                                      "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
                                  return turkceKarsilastir(nameA, nameB);
                                });

                                return ListView.builder(
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    var studentDoc = students[index];
                                    var studentData =
                                        studentDoc.data()
                                            as Map<String, dynamic>? ??
                                        {};
                                    String studentId = studentDoc.id;
                                    String adSoyad =
                                        "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";
                                    bool hasBeenOnDuty =
                                        studentData['hasBeenOnDuty'] ?? false;
                                    bool nobetMusait =
                                        studentData['nobetMusait'] ?? true;

                                    bool bugunNobetciMi = _bugunNobetciler.any(
                                      (n) => n['id'] == studentId,
                                    );

                                    Color textColor = Colors.black87;
                                    String durumMetni = "Sıra Bekliyor";

                                    if (!nobetMusait) {
                                      textColor = Colors.grey;
                                      durumMetni = "Nöbet İptal Edildi (Pasif)";
                                    } else if (bugunNobetciMi) {
                                      textColor = Colors.green.shade700;
                                      durumMetni = "Bugün Nöbetçi 🟢";
                                    } else if (hasBeenOnDuty) {
                                      textColor = Colors.red.shade300;
                                      durumMetni = "Nöbet Tuttu";
                                    }

                                    return ListTile(
                                      leading: Checkbox(
                                        value: nobetMusait,
                                        activeColor: Colors.indigo,
                                        onChanged:
                                            (widget.isTeacher &&
                                                isSinifOgretmeni)
                                            ? (bool? yeniDeger) async {
                                                if (yeniDeger != null) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('students')
                                                      .doc(studentId)
                                                      .update({
                                                        'nobetMusait':
                                                            yeniDeger,
                                                      });
                                                }
                                              }
                                            : null,
                                      ),
                                      title: Text(
                                        adSoyad,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: nobetMusait
                                              ? TextDecoration.none
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      subtitle: Text(
                                        durumMetni,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(
                                            alpha: 0.8,
                                          ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('duty_records')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Henüz geçmiş nöbet kaydı bulunmuyor."),
                );
              }

              var records = snapshot.data!.docs;

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var record = records[index].data() as Map<String, dynamic>;
                  String tarih = record['date'] ?? '';
                  var nobetciListesi =
                      record['nobetciler'] as List<dynamic>? ?? [];

                  String isimlerStr = nobetciListesi
                      .map((n) => n['name'].toString())
                      .join(', ');

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        "Tarih: $tarih",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Nöbetçiler: $isimlerStr"),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
