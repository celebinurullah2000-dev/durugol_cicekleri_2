// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class etutlerscreen extends StatefulWidget {
  final String classId;
  final String className;
  final String userRole; // Rol parametresi eklendi

  const etutlerscreen({
    super.key,
    required this.classId,
    required this.className,
    this.userRole = 'classroom_teacher', // Varsayılan sınıf öğretmeni
  });

  @override
  State<etutlerscreen> createState() => _etutlerscreenState();
}

class _etutlerscreenState extends State<etutlerscreen> {
  // Sadece rolü kesin olarak 'classroom_teacher' olanlar yetkilidir
  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  // --- YENİ ETÜT EKLEME VEYA DÜZENLEME DİALOGU ---
  void _etutEkleDuzenleDialog(
    BuildContext context, {
    DocumentSnapshot? etutDoc,
  }) {
    if (!_isSinifOgretmeni) return;

    bool isEditing = etutDoc != null;

    final Map<String, dynamic>? data = isEditing
        ? etutDoc.data() as Map<String, dynamic>?
        : null;

    final TextEditingController etutAdiController = TextEditingController(
      text: isEditing ? (data?['etutAdi'] ?? '') : '',
    );
    final TextEditingController ogretmenController = TextEditingController(
      text: isEditing ? (data?['etutOgretmeni'] ?? '') : '',
    );
    final TextEditingController gunController = TextEditingController(
      text: isEditing ? (data?['etutGunu'] ?? '') : '',
    );
    final TextEditingController baslangicController = TextEditingController(
      text: isEditing ? (data?['baslangicSaati'] ?? '') : '15:00',
    );
    final TextEditingController bitisController = TextEditingController(
      text: isEditing ? (data?['bitisSaati'] ?? '') : '16:00',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? "Etütü Düzenle" : "Yeni Etüt Ekle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: etutAdiController,
                decoration: const InputDecoration(
                  labelText: "Etüt Adı (Örn: Matematik Etütü)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ogretmenController,
                decoration: const InputDecoration(labelText: "Etüt Öğretmeni"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gunController,
                decoration: const InputDecoration(
                  labelText: "Etüt Günü (Örn: Pazartesi)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: baslangicController,
                decoration: const InputDecoration(
                  labelText: "Başlangıç Saati (Örn: 15:00)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bitisController,
                decoration: const InputDecoration(
                  labelText: "Bitiş Saati (Örn: 16:00)",
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
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String etutAdi = etutAdiController.text.trim();
              String ogretmen = ogretmenController.text.trim();
              String gun = gunController.text.trim();
              String baslangic = baslangicController.text.trim();
              String bitis = bitisController.text.trim();

              if (etutAdi.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen etüt adını yazın.")),
                );
                return;
              }

              if (isEditing) {
                await FirebaseFirestore.instance
                    .collection('etutler')
                    .doc(etutDoc.id)
                    .update({
                      'etutAdi': etutAdi,
                      'etutOgretmeni': ogretmen,
                      'etutGunu': gun,
                      'baslangicSaati': baslangic,
                      'bitisSaati': bitis,
                    });
              } else {
                await FirebaseFirestore.instance.collection('etutler').add({
                  'classId': widget.classId,
                  'etutAdi': etutAdi,
                  'etutOgretmeni': ogretmen,
                  'etutGunu': gun,
                  'baslangicSaati': baslangic,
                  'bitisSaati': bitis,
                  'katilimciIdleri': [],
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? "Etüt başarıyla güncellendi."
                        : "Etüt başarıyla oluşturuldu.",
                  ),
                ),
              );
            },
            child: Text(isEditing ? "Güncelle" : "Kaydet"),
          ),
        ],
      ),
    );
  }

  // --- ETÜT SİLME ---
  void _etutSil(String etutId) {
    if (!_isSinifOgretmeni) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Etütü Sil"),
        content: const Text(
          "Bu etütü ve katılımcı kayıtlarını silmek istediğinize emin misiniz?",
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
              await FirebaseFirestore.instance
                  .collection('etutler')
                  .doc(etutId)
                  .delete();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> gunSiralamasi = {
      'pazartesi': 1,
      'salı': 2,
      'sali': 2,
      'çarşamba': 3,
      'carsamba': 3,
      'perşembe': 4,
      'persembe': 4,
      'cuma': 5,
      'cumartesi': 6,
      'pazar': 7,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Etüt Yönetimi"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('etutler')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                _isSinifOgretmeni
                    ? "Bu sınıfa ait henüz bir etüt oluşturulmamış.\nSağ alttan yeni etüt ekleyebilirsiniz."
                    : "Bu sınıfa ait henüz bir etüt bulunmuyor.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          var etutListesi = snapshot.data!.docs;

          etutListesi.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;

            String gunA = (dataA['etutGunu'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            String gunB = (dataB['etutGunu'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            int siraA = gunSiralamasi[gunA] ?? 99;
            int siraB = gunSiralamasi[gunB] ?? 99;

            return siraA.compareTo(siraB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: etutListesi.length,
            itemBuilder: (context, index) {
              var etutDoc = etutListesi[index];
              var etutData = etutDoc.data() as Map<String, dynamic>;
              String etutId = etutDoc.id;
              String etutAdi = etutData['etutAdi'] ?? '';
              String ogretmen = etutData['etutOgretmeni'] ?? '';
              String gun = etutData['etutGunu'] ?? '';
              String baslangic = etutData['baslangicSaati'] ?? '';
              String bitis = etutData['bitisSaati'] ?? '';
              List katilimcilar = etutData['katilimciIdleri'] ?? [];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: const Icon(
                      Icons.event_note,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    etutAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (ogretmen.isNotEmpty) Text("Öğretmen: $ogretmen"),
                      if (gun.isNotEmpty)
                        Text(
                          "Gün: $gun",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                        ),
                      Text("Saat: $baslangic - $bitis"),
                      const SizedBox(height: 2),
                      Text(
                        "Katılımcı Öğrenci Sayısı: ${katilimcilar.length}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // SADECE SINIF ÖĞRETMENİYSE KALEM VE ÇÖP KUTUSU GÖRÜNÜR
                  trailing: _isSinifOgretmeni
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _etutEkleDuzenleDialog(
                                context,
                                etutDoc: etutDoc,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _etutSil(etutId),
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EtutKatilimciSecimScreen(
                          etutId: etutId,
                          etutAdi: etutAdi,
                          classId: widget.classId,
                          userRole: widget.userRole, // Rol açıkça aktarılıyor
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
      // SADECE SINIF ÖĞRETMENİYSE YENİ ETÜT EKLEME (+) BUTONU GÖRÜNÜR
      floatingActionButton: _isSinifOgretmeni
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              onPressed: () => _etutEkleDuzenleDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// --- ÖĞRENCİ SEÇİM VE TİK ATMA EKRANI ---
class EtutKatilimciSecimScreen extends StatefulWidget {
  final String etutId;
  final String etutAdi;
  final String classId;
  final String userRole;

  const EtutKatilimciSecimScreen({
    super.key,
    required this.etutId,
    required this.etutAdi,
    required this.classId,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<EtutKatilimciSecimScreen> createState() =>
      _EtutKatilimciSecimScreenState();
}

class _EtutKatilimciSecimScreenState extends State<EtutKatilimciSecimScreen> {
  final Set<String> _secilenOgrenciIdleri = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _ogrenciler = [];

  // Sadece sınıf öğretmeni yetkili
  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  @override
  void initState() {
    super.initState();
    _verileriYukle();
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

  Future<void> _verileriYukle() async {
    try {
      var etutDoc = await FirebaseFirestore.instance
          .collection('etutler')
          .doc(widget.etutId)
          .get();

      if (etutDoc.exists) {
        var data = etutDoc.data() as Map<String, dynamic>;
        List mevcutKatilimcilar = data['katilimciIdleri'] ?? [];
        _secilenOgrenciIdleri.addAll(
          mevcutKatilimcilar.map((e) => e.toString()),
        );
      }

      var studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      List<Map<String, dynamic>> tempOgrenciler = [];
      for (var doc in studentSnapshot.docs) {
        tempOgrenciler.add({'id': doc.id, ...doc.data()});
      }

      tempOgrenciler.sort((a, b) {
        String adA = a['firstName'] ?? '';
        String adB = b['firstName'] ?? '';
        int adKarsilastir = _turkceKarsilastir(adA, adB);

        if (adKarsilastir != 0) return adKarsilastir;

        String soyadA = a['lastName'] ?? '';
        String soyadB = b['lastName'] ?? '';
        return _turkceKarsilastir(soyadA, soyadB);
      });

      setState(() {
        _ogrenciler = tempOgrenciler;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veriler yüklenirken hata oluştu: $e")),
      );
    }
  }

  bool get _tumunuSeciliMi {
    if (_ogrenciler.isEmpty) return false;
    for (var ogrenci in _ogrenciler) {
      if (!_secilenOgrenciIdleri.contains(ogrenci['id'])) {
        return false;
      }
    }
    return true;
  }

  void _tumunuTetikle(bool? value) {
    if (!_isSinifOgretmeni) return;
    setState(() {
      if (value == true) {
        for (var ogrenci in _ogrenciler) {
          _secilenOgrenciIdleri.add(ogrenci['id']);
        }
      } else {
        _secilenOgrenciIdleri.clear();
      }
    });
  }

  Future<void> _degisiklikleriKaydet() async {
    if (!_isSinifOgretmeni) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('etutler')
          .doc(widget.etutId)
          .update({'katilimciIdleri': _secilenOgrenciIdleri.toList()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Katılımcı listesi başarıyla kaydedildi."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kaydetme sırasında hata oluştu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool tumSecili = _tumunuSeciliMi;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.etutAdi} - Katılımcılar"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ogrenciler.isEmpty
          ? const Center(child: Text("Bu sınıfta kayıtlı öğrenci bulunmuyor."))
          : Column(
              children: [
                // Üstteki "Tümünü Seç / Kaldır" kutusu (Sınıf öğretmeni değilse pasif/tıklanamaz olur)
                Container(
                  color: Colors.deepPurple.shade50,
                  child: CheckboxListTile(
                    title: const Text(
                      "Tümünü Seç / Kaldır",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    value: tumSecili,
                    activeColor: Colors.deepPurple,
                    onChanged: _isSinifOgretmeni ? _tumunuTetikle : null,
                    secondary: const Icon(
                      Icons.select_all,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _ogrenciler.length,
                    itemBuilder: (context, index) {
                      var student = _ogrenciler[index];
                      String studentId = student['id'];
                      String firstName = student['firstName'] ?? '';
                      String lastName = student['lastName'] ?? '';
                      String adSoyad = "$firstName $lastName";
                      String okulNo = student['schoolNumber'] ?? '-';

                      bool isSelected = _secilenOgrenciIdleri.contains(
                        studentId,
                      );

                      return CheckboxListTile(
                        title: Text(
                          adSoyad,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("Öğrenci No: $okulNo"),
                        value: isSelected,
                        activeColor: Colors.deepPurple,
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade200,
                          child: Text(
                            adSoyad.isNotEmpty ? adSoyad[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        // ÖĞRENCİ LİSTESİNDEKİ CHECKBOXLAR: Sınıf öğretmeniyse değiştirilebilir, değilse null (pasif)
                        onChanged: _isSinifOgretmeni
                            ? (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _secilenOgrenciIdleri.add(studentId);
                                  } else {
                                    _secilenOgrenciIdleri.remove(studentId);
                                  }
                                });
                              }
                            : null,
                      );
                    },
                  ),
                ),
                // EN ALTTAKİ KAYDET BUTONU: Sadece sınıf öğretmeniyse görünür, diğerlerinde tamamen gizlenir
                if (_isSinifOgretmeni)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _degisiklikleriKaydet,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Kaydet",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
