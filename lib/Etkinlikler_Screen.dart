// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Etkinlik_Detay_Screen.dart';

class EtkinliklerScreen extends StatelessWidget {
  final String classId;
  final bool isTeacher;

  const EtkinliklerScreen({
    super.key,
    required this.classId,
    this.isTeacher = true,
  });

  void _yeniEtkinlikEkleDialog(BuildContext context) {
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
              title: const Text("Yeni Etkinlik Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: adiController,
                      decoration: const InputDecoration(
                        labelText: "Etkinlik Adı",
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
                          .collection('etkinlikler')
                          .add({
                            'etkinlik Adi': adiController.text,
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
        title: const Text("Sınıf Etkinlikleri"),
        actions: [
          // Sadece sınıf öğretmenine üst sağdaki + butonu görünür[cite: 10]
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_circle, size: 28),
              tooltip: "Yeni Etkinlik Ekle",
              onPressed: () => _yeniEtkinlikEkleDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('etkinlikler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz kayıtlı etkinlik bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;
          DateTime simdi = DateTime.now();

          List<QueryDocumentSnapshot> aktifEtkinlikler = [];
          List<QueryDocumentSnapshot> gecmisEtkinlikler = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
            if (bitis != null && bitis.toDate().isAfter(simdi)) {
              aktifEtkinlikler.add(doc);
            } else {
              gecmisEtkinlikler.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                "🟢 Aktif Etkinlikler",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              if (aktifEtkinlikler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Aktif etkinlik bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...aktifEtkinlikler.map(
                (doc) => _etkinlikKarti(context, doc, true),
              ),
              const SizedBox(height: 20),
              const Text(
                "📁 Geçmiş Etkinlikler",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              if (gecmisEtkinlikler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Geçmiş etkinlik bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...gecmisEtkinlikler.map(
                (doc) => _etkinlikKarti(context, doc, false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _etkinlikKarti(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool aktifMi,
  ) {
    var data = doc.data() as Map<String, dynamic>;
    String ad = data['etkinlik Adi'] ?? '';
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
                builder: (context) => EtkinlikDetayScreen(
                  classId: classId,
                  etkinlikId: doc.id,
                  etkinlikAdi: ad,
                  aciklama: data['aciklama'] ?? '',
                  aktifMi: aktifMi,
                  isTeacher: isTeacher, // Rolü detay sayfasına aktarıyoruz
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
                data['aciklama'].isEmpty
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
