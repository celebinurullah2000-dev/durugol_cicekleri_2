// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils.dart';
import 'package:lottie/lottie.dart';

class OkudugumKitaplarScreen extends StatefulWidget {
  final String studentId;
  const OkudugumKitaplarScreen({super.key, required this.studentId});

  @override
  State<OkudugumKitaplarScreen> createState() => _OkudugumKitaplarScreenState();
}

class _OkudugumKitaplarScreenState extends State<OkudugumKitaplarScreen> {
  final TextEditingController _kitapAdiController = TextEditingController();
  final TextEditingController _sayfaSayisiController = TextEditingController();

  // Kitap ekleme fonksiyonu
  void _kitapEkle() async {
    // 1. Veri Doğrulama
    if (_kitapAdiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir kitap adı girin!")),
      );
      return;
    }

    if (_sayfaSayisiController.text.isEmpty ||
        int.parse(_sayfaSayisiController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir sayfa sayısı girin!")),
      );
      return;
    }

    // Firestore'a gönderim
    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .collection('okunan_kitaplar')
        .add({
          'kitapAdi': _kitapAdiController.text.trim().toUpperCase(),
          'sayfaSayisi': int.parse(_sayfaSayisiController.text),
          'tarih': FieldValue.serverTimestamp(),
        });

    // 2. Klavye Kapatma ve Temizleme
    _kitapAdiController.clear();
    _sayfaSayisiController.clear();
    FocusScope.of(context).unfocus(); // Klavyeyi kapatır

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kitap başarıyla eklendi!")));
    }
  }

  void _kitapDuzenle(BuildContext context, DocumentSnapshot doc) {
    TextEditingController editAdiController = TextEditingController(
      text: doc['kitapAdi'],
    );
    TextEditingController editSayfaController = TextEditingController(
      text: doc['sayfaSayisi'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kitabı Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editAdiController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "Kitap Adı"),
            ),
            TextField(
              controller: editSayfaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Sayfa Sayısı"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('okunan_kitaplar')
                  .doc(doc.id)
                  .update({
                    'kitapAdi': editAdiController.text.trim().toUpperCase(),
                    'sayfaSayisi': int.parse(editSayfaController.text),
                  });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Okuduğum Kitaplar")),
      body: Column(
        children: [
          // 1. LOTTIE ANİMASYONU (Artık StreamBuilder'ın dışında, sabit duruyor)
          SizedBox(
            height: 120,
            child: Lottie.asset(
              'assets/animations/Cute astronaut read book on planet cartoon.json',
              fit: BoxFit.contain,
              repeat: false,
              animate: true,
            ),
          ),

          // 2. KİTAP EKLEME ALANI (Üste almak kullanım açısından da daha kolay olur)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kitapAdiController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: "Kitap Adı"),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _sayfaSayisiController,
                    decoration: const InputDecoration(labelText: "Sayfa"),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.indigo,
                    size: 30,
                  ),
                  onPressed: _kitapEkle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. LİSTE VE ÖZET KARTI (Veriye bağlı kısımlar StreamBuilder içinde)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('okunan_kitaplar')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                int toplamKitap = docs.length;
                int toplamSayfa = 0;

                for (var doc in docs) {
                  toplamSayfa += (doc['sayfaSayisi'] as num).toInt();
                }

                String mevcutOdul = Oyunlastirma.getOdul(toplamSayfa);
                String mevcutUnvan = Oyunlastirma.getUnvan(toplamSayfa);

                return Column(
                  children: [
                    // DİNAMİK ÖZET KARTI
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ozetBilgi("Kitap", "$toplamKitap"),
                          _ozetBilgi("Sayfa", "$toplamSayfa"),
                          _ozetBilgi("Ünvan", mevcutUnvan),
                          _ozetBilgi("Ödül", mevcutOdul),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // LİSTELEME
                    Expanded(
                      child: ListView.builder(
                        itemCount: toplamKitap,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          DateTime tarih = (doc['tarih'] as Timestamp).toDate();
                          String tarihStr =
                              "${tarih.day}.${tarih.month}.${tarih.year}";

                          return ListTile(
                            title: Text(doc['kitapAdi']),
                            subtitle: Text(tarihStr),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("${doc['sayfaSayisi']} S."),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () => _kitapDuzenle(context, doc),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetBilgi(String baslik, String deger) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(deger, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
