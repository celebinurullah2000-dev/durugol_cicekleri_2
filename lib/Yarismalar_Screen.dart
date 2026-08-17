// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class YarismalarScreen extends StatelessWidget {
  final String classId;
  final bool isTeacher;

  const YarismalarScreen({
    super.key,
    required this.classId,
    this.isTeacher = true,
  });

  void _yeniYarismaEkleDialog(BuildContext context) {
    final TextEditingController adiController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();
    DateTime? baslangicTarihi;
    DateTime? bitisTarihi;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Yeni Yarışma Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: adiController,
                      decoration: const InputDecoration(
                        labelText: "Yarışma Adı",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aciklamaController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Açıklama"),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          baslangicTarihi == null
                              ? "Başlangıç Seçilmedi"
                              : "Başla: ${baslangicTarihi!.day}.${baslangicTarihi!.month}.${baslangicTarihi!.year}",
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
                              setStateDialog(() => baslangicTarihi = secilen);
                            }
                          },
                          child: const Text("Tarih Seç"),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bitisTarihi == null
                              ? "Bitiş Seçilmedi"
                              : "Bitiş: ${bitisTarihi!.day}.${bitisTarihi!.month}.${bitisTarihi!.year}",
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
                              setStateDialog(() => bitisTarihi = secilen);
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
                    if (adiController.text.isNotEmpty &&
                        baslangicTarihi != null &&
                        bitisTarihi != null) {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .collection('yarismalar')
                          .add({
                            'yarismaAdi': adiController.text,
                            'aciklama': aciklamaController.text,
                            'baslangicTarihi': Timestamp.fromDate(
                              baslangicTarihi!,
                            ),
                            'bitisTarihi': Timestamp.fromDate(bitisTarihi!),
                            'katilanOgrenciler': {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Yarışmaları"),
        centerTitle: true,
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_circle, size: 28),
              tooltip: "Yeni Yarışma Ekle",
              onPressed: () => _yeniYarismaEkleDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('yarismalar')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz kayıtlı yarışma bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;
          DateTime simdi = DateTime.now();

          List<QueryDocumentSnapshot> aktifYarismalar = [];
          List<QueryDocumentSnapshot> gecmisYarismalar = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
            if (bitis != null && bitis.toDate().isAfter(simdi)) {
              aktifYarismalar.add(doc);
            } else {
              gecmisYarismalar.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                "🏆 Aktif Yarışmalar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              if (aktifYarismalar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Aktif yarışma bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...aktifYarismalar.map(
                (doc) => _yarismaKarti(context, doc, true),
              ),
              const SizedBox(height: 20),
              const Text(
                "📁 Geçmiş Yarışmalar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              if (gecmisYarismalar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Geçmiş yarışma bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...gecmisYarismalar.map(
                (doc) => _yarismaKarti(context, doc, false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _yarismaKarti(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool aktifMi,
  ) {
    var data = doc.data() as Map<String, dynamic>;
    String ad = data['yarismaAdi'] ?? '';
    Timestamp? baslangic = data['baslangicTarihi'] as Timestamp?;
    Timestamp? bitis = data['bitisTarihi'] as Timestamp?;

    String baslaStr = baslangic != null
        ? "${baslangic.toDate().day}.${baslangic.toDate().month}.${baslangic.toDate().year}"
        : "";
    String bitisStr = bitis != null
        ? "${bitis.toDate().day}.${bitis.toDate().month}.${bitis.toDate().year}"
        : "";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Başlangıç: $baslaStr | Bitiş: $bitisStr"),
        trailing: IconButton(
          icon: const Icon(Icons.people, color: Colors.indigo),
          tooltip: "Öğrenci Katılım Listesi",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YarismaDetayScreen(
                  classId: classId,
                  yarismaId: doc.id,
                  yarismaAdi: ad,
                  aciklama: data['aciklama'] ?? '',
                  aktifMi: aktifMi,
                  isTeacher: isTeacher, // Rolü detay ekranına aktarıyoruz
                ),
              ),
            );
          },
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(ad),
              content: Text(
                (data['aciklama'] == null ||
                        (data['aciklama'] as String).isEmpty)
                    ? "Açıklama girilmemiş."
                    : data['aciklama'],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Öğretmen İçin Yarışma Detay ve Katılım Listesi
class YarismaDetayScreen extends StatelessWidget {
  final String classId;
  final String yarismaId;
  final String yarismaAdi;
  final String aciklama;
  final bool aktifMi;
  final bool isTeacher; // Rol parametresi eklendi

  const YarismaDetayScreen({
    super.key,
    required this.classId,
    required this.yarismaId,
    required this.yarismaAdi,
    required this.aciklama,
    required this.aktifMi,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(yarismaAdi), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Açıklama:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              aciklama.isEmpty ? "Açıklama girilmemiş." : aciklama,
              style: const TextStyle(fontSize: 15),
            ),
            const Divider(height: 30),
            const Text(
              "Öğrenci Katılım Durumları:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('yarismalar')
                    .doc(yarismaId)
                    .snapshots(),
                builder: (context, yarismaSnap) {
                  if (yarismaSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var yarismaData =
                      yarismaSnap.data?.data() as Map<String, dynamic>? ?? {};
                  Map<String, dynamic> katilanlarMap =
                      yarismaData['katilanOgrenciler'] ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('classId', isEqualTo: classId)
                        .snapshots(),
                    builder: (context, studentSnap) {
                      if (studentSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!studentSnap.hasData ||
                          studentSnap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("Bu sınıfta öğrenci bulunamadı."),
                        );
                      }

                      var students = studentSnap.data!.docs;

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var studentDoc = students[index];
                          var studentData =
                              studentDoc.data() as Map<String, dynamic>;
                          String studentId = studentDoc.id;
                          String adSoyad =
                              "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

                          bool yapildiMi = katilanlarMap[studentId] == true;

                          Color renk = Colors.black87;
                          String durumMetni = "";

                          if (yapildiMi) {
                            renk = Colors.green.shade700;
                            durumMetni = "Katıldı ✅";
                          } else if (aktifMi) {
                            renk = Colors.black87;
                            durumMetni = "Henüz Katılmadı";
                          } else {
                            renk = Colors.red.shade700;
                            durumMetni = "Katılmadı ❌";
                          }

                          return ListTile(
                            title: Text(
                              adSoyad,
                              style: TextStyle(
                                color: renk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              durumMetni,
                              style: TextStyle(color: renk, fontSize: 12),
                            ),
                            leading: Checkbox(
                              value: yapildiMi,
                              activeColor: Colors.indigo,
                              // Sadece sınıf öğretmeniyse tıklanabilir, diğerleri için null (pasif) yapılır
                              onChanged: isTeacher
                                  ? (yeniDeger) async {
                                      katilanlarMap[studentId] =
                                          yeniDeger ?? false;
                                      await FirebaseFirestore.instance
                                          .collection('classes')
                                          .doc(classId)
                                          .collection('yarismalar')
                                          .doc(yarismaId)
                                          .update({
                                            'katilanOgrenciler': katilanlarMap,
                                          });
                                    }
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
