// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  final String userRole;
  final String classId;

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.studentId,
    this.userRole = 'classroom_teacher',
    required this.classId,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final TextEditingController _tcController;
  late final TextEditingController _dogumTarihiController;
  late final TextEditingController _anneAdiController;
  late final TextEditingController _babaAdiController;
  late final TextEditingController _anneCepController;
  late final TextEditingController _babaCepController;
  late final TextEditingController _anneMeslegiController;
  late final TextEditingController _babaMeslegiController;
  late final TextEditingController _kardesleriController;

  String? ogrenciProfilResmiUrl;
  bool _isSaving = false;

  // 360 Derece İstatistik Verileri
  bool _isLoadingStats = true;
  Map<String, dynamic> _istatistikVerileri = {};

  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  @override
  void initState() {
    super.initState();
    _tcController = TextEditingController(text: widget.studentData['tc'] ?? '');
    _dogumTarihiController = TextEditingController(
      text: widget.studentData['dogumTarihi'] ?? '',
    );
    _anneAdiController = TextEditingController(
      text: widget.studentData['anneAdi'] ?? '',
    );
    _babaAdiController = TextEditingController(
      text: widget.studentData['babaAdi'] ?? '',
    );
    _anneCepController = TextEditingController(
      text: widget.studentData['anneCep'] ?? '',
    );
    _babaCepController = TextEditingController(
      text: widget.studentData['babaCep'] ?? '',
    );
    _anneMeslegiController = TextEditingController(
      text: widget.studentData['anneMeslegi'] ?? '',
    );
    _babaMeslegiController = TextEditingController(
      text: widget.studentData['babaMeslegi'] ?? '',
    );
    _kardesleriController = TextEditingController(
      text: widget.studentData['kardesleri'] ?? '',
    );

    ogrenciProfilResmiUrl =
        widget.studentData['profileImageUrl'] ??
        widget.studentData['resimBase64'];

    // Verileri doğrudan bu sınıf içinde paralel olarak çekelim
    _ogrenciTumVerileriniGetir();
  }

  // --- 360 DERECE VERİ TOPLAMA FONKSİYONU ---
  Future<void> _ogrenciTumVerileriniGetir() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String studentId = widget.studentId;
      String classId = widget.classId;

      var odevlerFuture = firestore
          .collection('students')
          .doc(studentId)
          .collection('odevler')
          .get();
      var kitaplarFuture = firestore
          .collection('students')
          .doc(studentId)
          .collection('okunan_kitaplar')
          .get();
      var istatistiklerFuture = firestore
          .collection('students')
          .doc(studentId)
          .collection('istatistikler')
          .get();
      var isVerileriFuture = firestore
          .collection('students')
          .doc(studentId)
          .collection('is_verileri')
          .get();

      var davranislarFuture = firestore
          .collection('classes')
          .doc(classId)
          .collection('davranislar')
          .where('studentId', isEqualTo: studentId)
          .get();

      var etkinliklerFuture = firestore
          .collection('classes')
          .doc(classId)
          .collection('etkinlikler')
          .where('katilanlar', arrayContains: studentId)
          .get();

      var dutyRecordsFuture = firestore
          .collection('classes')
          .doc(classId)
          .collection('duty_records')
          .where('studentId', isEqualTo: studentId)
          .get();

      List<QuerySnapshot> results = await Future.wait([
        odevlerFuture,
        kitaplarFuture,
        istatistiklerFuture,
        isVerileriFuture,
        davranislarFuture,
        etkinliklerFuture,
        dutyRecordsFuture,
      ]);

      QuerySnapshot odevlerSnap = results[0];
      QuerySnapshot kitaplarSnap = results[1];
      QuerySnapshot istatistiklerSnap = results[2];
      QuerySnapshot isVerileriSnap = results[3];
      QuerySnapshot davranislarSnap = results[4];
      QuerySnapshot etkinliklerSnap = results[5];
      QuerySnapshot dutySnap = results[6];

      int toplamKitapSayisi = kitaplarSnap.docs.length;
      int toplamSayfaSayisi = 0;
      for (var doc in kitaplarSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        toplamSayfaSayisi +=
            int.tryParse(data['sayfaSayisi']?.toString() ?? '0') ?? 0;
      }

      int yapilanOdev = 0;
      int yapilmayanOdev = 0;
      int kilitliOdev = 0;
      for (var doc in odevlerSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String durum = data['durum'] ?? '';
        if (durum == 'yapildi') {
          yapilanOdev++;
        } else if (durum == 'yapilmadi') {
          yapilmayanOdev++;
        } else if (durum == 'kilitli') {
          kilitliOdev++;
        }
      }

      int nobetSayisi = dutySnap.docs.length;
      int gorevlilikSayisi = 0;
      int renkliKartSayisi = davranislarSnap.docs.length;
      int etkinlikSayisi = etkinliklerSnap.docs.length;

      if (mounted) {
        setState(() {
          _istatistikVerileri = {
            'toplamKitapSayisi': toplamKitapSayisi,
            'toplamSayfaSayisi': toplamSayfaSayisi,
            'yapilanOdev': yapilanOdev,
            'yapilmayanOdev': yapilmayanOdev,
            'kilitliOdev': kilitliOdev,
            'nobetSayisi': nobetSayisi,
            'gorevlilikSayisi': gorevlilikSayisi,
            'renkliKartSayisi': renkliKartSayisi,
            'etkinlikSayisi': etkinlikSayisi,
            'istatistiklerDocs': istatistiklerSnap.docs
                .map((e) => e.data())
                .toList(),
            'isVerileriDocs': isVerileriSnap.docs.map((e) => e.data()).toList(),
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print("Öğrenci profili veri çekme hatası: $e");
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  void dispose() {
    _tcController.dispose();
    _dogumTarihiController.dispose();
    _anneAdiController.dispose();
    _babaAdiController.dispose();
    _anneCepController.dispose();
    _babaCepController.dispose();
    _anneMeslegiController.dispose();
    _babaMeslegiController.dispose();
    _kardesleriController.dispose();
    super.dispose();
  }

  Future<void> _profilResmiDegistir() async {
    if (!_isSinifOgretmeni) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/${widget.studentId}.jpg',
      );

      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(image.path));
      }

      final String downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({'profileImageUrl': downloadUrl});

      setState(() {
        ogrenciProfilResmiUrl = downloadUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Öğrenci profil resmi başarıyla güncellendi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Resim yüklenirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bilgileriKaydet() async {
    if (!_isSinifOgretmeni) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({
            'tc': _tcController.text.trim(),
            'dogumTarihi': _dogumTarihiController.text.trim(),
            'anneAdi': _anneAdiController.text.trim(),
            'babaAdi': _babaAdiController.text.trim(),
            'anneCep': _anneCepController.text.trim(),
            'babaCep': _babaCepController.text.trim(),
            'anneMeslegi': _anneMeslegiController.text.trim(),
            'babaMeslegi': _babaMeslegiController.text.trim(),
            'kardesleri': _kardesleriController.text.trim(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Öğrenci bilgileri başarıyla güncellendi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Güncelleme sırasında hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resmiTamBoyutGoster() {
    if (ogrenciProfilResmiUrl == null || ogrenciProfilResmiUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ogrenciProfilResmiUrl!.startsWith('http')
                      ? Image.network(
                          ogrenciProfilResmiUrl!,
                          fit: BoxFit.contain,
                        )
                      : Image.memory(
                          base64Decode(ogrenciProfilResmiUrl!),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        "${widget.studentData['firstName'] ?? ''} ${widget.studentData['lastName'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: Text("$fullName - 360° Öğrenci Profili"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PROFİL FOTOĞRAFI ---
            Center(
              child: GestureDetector(
                onTap: () {
                  if (ogrenciProfilResmiUrl != null &&
                      ogrenciProfilResmiUrl!.isNotEmpty) {
                    _resmiTamBoyutGoster();
                  } else if (_isSinifOgretmeni) {
                    _profilResmiDegistir();
                  }
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage:
                          (ogrenciProfilResmiUrl != null &&
                              ogrenciProfilResmiUrl!.isNotEmpty)
                          ? (ogrenciProfilResmiUrl!.startsWith('http')
                                ? NetworkImage(ogrenciProfilResmiUrl!)
                                      as ImageProvider
                                : MemoryImage(
                                    base64Decode(ogrenciProfilResmiUrl!),
                                  ))
                          : null,
                      child:
                          (ogrenciProfilResmiUrl == null ||
                              ogrenciProfilResmiUrl!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.indigo,
                            )
                          : null,
                    ),
                    if (_isSinifOgretmeni)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _profilResmiDegistir,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.indigoAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 360 DERECE ÖZET İSTATİSTİK KARTLARI ---
            const Text(
              "📊 Öğrenci Performans & Takip Özeti",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),

            _isLoadingStats
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            "Okunan Kitap",
                            "${_istatistikVerileri['toplamKitapSayisi'] ?? 0}",
                            Icons.book,
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Toplam Sayfa",
                            "${_istatistikVerileri['toplamSayfaSayisi'] ?? 0}",
                            Icons.menu_book,
                            Colors.cyan,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Nöbet Sayısı",
                            "${_istatistikVerileri['nobetSayisi'] ?? 0}",
                            Icons.event_available,
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatCard(
                            "Yapılan Ödev",
                            "${_istatistikVerileri['yapilanOdev'] ?? 0}",
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Yapılmayan",
                            "${_istatistikVerileri['yapilmayanOdev'] ?? 0}",
                            Icons.cancel,
                            Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Kilitli Ödev",
                            "${_istatistikVerileri['kilitliOdev'] ?? 0}",
                            Icons.lock,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatCard(
                            "Etkinlikler",
                            "${_istatistikVerileri['etkinlikSayisi'] ?? 0}",
                            Icons.star,
                            Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Renkli Kartlar",
                            "${_istatistikVerileri['renkliKartSayisi'] ?? 0}",
                            Icons.palette,
                            Colors.pink,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            "Görevlilik",
                            "${_istatistikVerileri['gorevlilikSayisi'] ?? 0}",
                            Icons.assignment_ind,
                            Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),

            const Divider(height: 40, thickness: 2),

            // --- KİŞİSEL BİLGİLER FORMU ---
            const Text(
              "📝 Kimlik ve Aile Bilgileri",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _tcController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "T.C. Kimlik No"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dogumTarihiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Doğum Tarihi"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneAdiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaAdiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneCepController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaCepController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneMeslegiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaMeslegiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kardesleriController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Kardeşleri"),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            if (_isSinifOgretmeni)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _bilgileriKaydet,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Değişiklikleri Kaydet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
