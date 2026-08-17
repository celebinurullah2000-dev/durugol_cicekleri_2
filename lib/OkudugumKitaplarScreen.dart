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

  void _kitapEkle() async {
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

    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .collection('okunan_kitaplar')
        .add({
          'kitapAdi': _kitapAdiController.text.trim().toUpperCase(),
          'sayfaSayisi': int.parse(_sayfaSayisiController.text),
          'tarih': FieldValue.serverTimestamp(),
        });

    _kitapAdiController.clear();
    _sayfaSayisiController.clear();
    FocusScope.of(context).unfocus();

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
          SizedBox(
            height: 120,
            child: Lottie.asset(
              'assets/animations/Cute astronaut read book on planet cartoon.json',
              fit: BoxFit.contain,
              repeat: false,
              animate: true,
            ),
          ),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('okunan_kitaplar')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                int toplamKitap = docs.length;
                int toplamSayfa = 0;

                for (var doc in docs) {
                  toplamSayfa +=
                      ((doc.data() as Map<String, dynamic>)['sayfaSayisi']
                                  as num? ??
                              0)
                          .toInt();
                }

                String mevcutOdul = Oyunlastirma.getOdul(toplamSayfa);
                String mevcutUnvan = Oyunlastirma.getUnvan(toplamSayfa);

                return Column(
                  children: [
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
                    Expanded(
                      child: ListView.builder(
                        itemCount: toplamKitap,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          var data = doc.data() as Map<String, dynamic>;

                          Timestamp? timestamp = data['tarih'] as Timestamp?;
                          String tarihStr = "Yükleniyor...";
                          if (timestamp != null) {
                            DateTime tarih = timestamp.toDate();
                            tarihStr =
                                "${tarih.day}.${tarih.month}.${tarih.year}";
                          }

                          return ListTile(
                            title: Text(data['kitapAdi'] ?? ''),
                            subtitle: Text(tarihStr),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("${data['sayfaSayisi'] ?? 0} S."),
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
