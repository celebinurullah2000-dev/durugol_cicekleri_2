// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SinifIsTakipScreen extends StatefulWidget {
  final String classId;
  final String userRole;

  const SinifIsTakipScreen({
    super.key,
    required this.classId,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<SinifIsTakipScreen> createState() => _SinifIsTakipScreenState();
}

class _SinifIsTakipScreenState extends State<SinifIsTakipScreen> {
  final Map<String, Map<String, String>> _isVeriHavuzlari = {};
  final Map<String, Map<String, TextEditingController>> _isControllerHavuzlari =
      {};

  String? _acikolanIsId;

  void _isSilDialog(String isId, String isAdi, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İşi Sil"),
        content: Text(
          "'$isAdi' adlı işi ve bu işe ait tüm öğrenci girişlerini kalıcı olarak silmek istediğinize emin misiniz?",
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

              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('sinif_isleri')
                  .doc(isId)
                  .delete();

              var studentsSnapshot = await FirebaseFirestore.instance
                  .collection('students')
                  .where('classId', isEqualTo: widget.classId)
                  .get();

              for (var doc in studentsSnapshot.docs) {
                await doc.reference
                    .collection('is_verileri')
                    .doc(isId)
                    .delete();
              }

              _isVeriHavuzlari.remove(isId);
              _isControllerHavuzlari.remove(isId);

              setState(() {});

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("İş ve ilgili tüm veriler başarıyla silindi."),
                ),
              );
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _yeniIsEkleDialog(BuildContext context) {
    final TextEditingController isAdiController = TextEditingController();
    String secilenVeriTuru = 'artı_eksi';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yeni İş / Etkinlik Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: isAdiController,
                  decoration: const InputDecoration(
                    labelText: "İş Adı (Örn: Ödev Kontrolü, Sözlü)",
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Veri Türü Seçin:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                DropdownButton<String>(
                  value: secilenVeriTuru,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'artı_eksi',
                      child: Text("(+) veya (-)"),
                    ),
                    DropdownMenuItem(
                      value: 'rakam',
                      child: Text("Rakamlı Giriş (Örn: Puan, Sayfa)"),
                    ),
                    DropdownMenuItem(
                      value: 'sozel',
                      child: Text("Sözel Giriş (Örn: İyi, Geliştirilmeli)"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        secilenVeriTuru = val;
                      });
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
            ElevatedButton(
              onPressed: () async {
                String isAdi = isAdiController.text.trim();
                if (isAdi.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('sinif_isleri')
                    .add({
                      'isAdi': isAdi,
                      'veriTuru': secilenVeriTuru,
                      'tarih': Timestamp.now(),
                    });

                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yeni iş başarıyla eklendi.")),
                );
              },
              child: const Text("Oluştur"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _topluDegerAta(
    String isId,
    String veriTuru,
    BuildContext context,
  ) async {
    String varsayilanDeger = '+';
    if (veriTuru == 'artı_eksi') varsayilanDeger = '+';
    if (veriTuru == 'rakam') varsayilanDeger = '100';
    if (veriTuru == 'sozel') varsayilanDeger = 'Tamamladı';

    final TextEditingController controller = TextEditingController(
      text: varsayilanDeger,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tüm Sınıfa Toplu Değer Ata"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tüm öğrencilere uygulanacak değer (${veriTuru.toUpperCase()}):",
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Değer Girin"),
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
              String girilenDeger = controller.text.trim();
              Navigator.pop(context);

              var studentsSnapshot = await FirebaseFirestore.instance
                  .collection('students')
                  .where('classId', isEqualTo: widget.classId)
                  .get();

              _isVeriHavuzlari.putIfAbsent(isId, () => {});
              var havuz = _isVeriHavuzlari[isId]!;

              for (var doc in studentsSnapshot.docs) {
                havuz[doc.id] = girilenDeger;
                await doc.reference.collection('is_verileri').doc(isId).set({
                  'deger': girilenDeger,
                }, SetOptions(merge: true));
              }

              setState(() {});
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tüm sınıfa değer başarıyla uygulandı."),
                ),
              );
            },
            child: const Text("Uygula"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSinifOgretmeni = widget.userRole == 'classroom_teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text("İş Takibi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('sinif_isleri')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, isSnapshot) {
          if (isSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!isSnapshot.hasData || isSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                isSinifOgretmeni
                    ? "Henüz eklenmiş bir iş/etkinlik yok.\nSağ alttan 'Yeni İş Ekle' butonunu kullanın."
                    : "Henüz eklenmiş bir iş/etkinlik yok.",
                textAlign: TextAlign.center,
              ),
            );
          }

          var isler = isSnapshot.data!.docs;

          return ListView.builder(
            itemCount: isler.length,
            itemBuilder: (context, index) {
              var isDoc = isler[index];
              var isData = isDoc.data() as Map<String, dynamic>;
              String isAdi = isData['isAdi'] ?? '';
              String veriTuru = isData['veriTuru'] ?? 'artı_eksi';
              String isId = isDoc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  initiallyExpanded: _acikolanIsId == isId,
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      if (isExpanded) {
                        _acikolanIsId = isId;
                      } else {
                        if (_acikolanIsId == isId) {
                          _acikolanIsId = null;
                        }
                      }
                    });
                  },
                  leading: const Icon(Icons.assignment, color: Colors.indigo),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAdi,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isSinifOgretmeni)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: "Bu İşi Sil",
                          onPressed: () => _isSilDialog(isId, isAdi, context),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "Tür: ${veriTuru.toUpperCase()} • Detay için tıkla",
                  ),
                  children: [
                    if (isSinifOgretmeni)
                      Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tüm Sınıfa Toplu Değer Ver:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _topluDegerAta(isId, veriTuru, context),
                              icon: const Icon(
                                Icons.playlist_add_check,
                                size: 16,
                              ),
                              label: const Text(
                                "Toplu Ata",
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .where('classId', isEqualTo: widget.classId)
                          .snapshots(),
                      builder: (context, studentSnapshot) {
                        if (!studentSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          );
                        }

                        var ogrenciler = studentSnapshot.data!.docs;
                        ogrenciler.sort((a, b) {
                          var adA =
                              "${(a.data() as Map<String, dynamic>)['firstName'] ?? ''} ${(a.data() as Map<String, dynamic>)['lastName'] ?? ''}"
                                  .toLowerCase();
                          var adB =
                              "${(b.data() as Map<String, dynamic>)['firstName'] ?? ''} ${(b.data() as Map<String, dynamic>)['lastName'] ?? ''}"
                                  .toLowerCase();
                          return adA.compareTo(adB);
                        });

                        _isVeriHavuzlari.putIfAbsent(isId, () => {});
                        _isControllerHavuzlari.putIfAbsent(isId, () => {});
                        var sinifVeriHavuzu = _isVeriHavuzlari[isId]!;
                        var oIsinControllerlari = _isControllerHavuzlari[isId]!;

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ogrenciler.length,
                              itemBuilder: (context, oIdx) {
                                var ogrDoc = ogrenciler[oIdx];
                                var ogrData =
                                    ogrDoc.data() as Map<String, dynamic>;
                                String ogrAd =
                                    "${ogrData['firstName'] ?? ''} ${ogrData['lastName'] ?? ''}"
                                        .toUpperCase();
                                String ogrId = ogrDoc.id;

                                return FutureBuilder<DocumentSnapshot>(
                                  future: ogrDoc.reference
                                      .collection('is_verileri')
                                      .doc(isId)
                                      .get(
                                        const GetOptions(
                                          source: Source.serverAndCache,
                                        ),
                                      ),
                                  builder: (context, veriSnap) {
                                    String serverDeger = '+';
                                    if (veriSnap.hasData &&
                                        veriSnap.data!.exists) {
                                      var vData =
                                          veriSnap.data!.data()
                                              as Map<String, dynamic>?;
                                      if (vData != null &&
                                          vData.containsKey('deger')) {
                                        serverDeger = vData['deger'] ?? '+';
                                      }
                                    }

                                    String aktifDeger =
                                        sinifVeriHavuzu.containsKey(ogrId)
                                        ? sinifVeriHavuzu[ogrId]!
                                        : serverDeger;

                                    if (veriTuru != 'artı_eksi') {
                                      oIsinControllerlari.putIfAbsent(
                                        ogrId,
                                        () {
                                          return TextEditingController(
                                            text:
                                                (aktifDeger == '+' ||
                                                    aktifDeger == '-')
                                                ? ''
                                                : aktifDeger,
                                          );
                                        },
                                      );
                                    }

                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        ogrAd,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: SizedBox(
                                        width: 130,
                                        child: _buildGirisWidgeti(
                                          veriTuru,
                                          aktifDeger,
                                          veriTuru == 'artı_eksi'
                                              ? null
                                              : oIsinControllerlari[ogrId],
                                          (yeniDeger) {
                                            sinifVeriHavuzu[ogrId] = yeniDeger;
                                          },
                                          isSinifOgretmeni,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            if (isSinifOgretmeni)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      for (var entry
                                          in sinifVeriHavuzu.entries) {
                                        await FirebaseFirestore.instance
                                            .collection('students')
                                            .doc(entry.key)
                                            .collection('is_verileri')
                                            .doc(isId)
                                            .set({
                                              'deger': entry.value,
                                            }, SetOptions(merge: true));
                                      }
                                      setState(() {});

                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tüm girişler başarıyla kaydedildi!",
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text(
                                      "Bu İşin Girişlerini Kaydet",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isSinifOgretmeni
          ? FloatingActionButton.extended(
              onPressed: () => _yeniIsEkleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Yeni İş Ekle"),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildGirisWidgeti(
    String veriTuru,
    String mevcutDeger,
    TextEditingController? controller,
    Function(String) onDegisti,
    bool isSinifOgretmeni,
  ) {
    if (veriTuru == 'artı_eksi') {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: isSinifOgretmeni
                    ? () {
                        setLocalState(() => mevcutDeger = '+');
                        onDegisti('+');
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mevcutDeger == '+'
                        ? Colors.green.shade200
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Text(
                    "+",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: isSinifOgretmeni
                    ? () {
                        setLocalState(() => mevcutDeger = '-');
                        onDegisti('-');
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mevcutDeger == '-'
                        ? Colors.red.shade200
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Text(
                    "-",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (veriTuru == 'rakam') {
      return SizedBox(
        width: 80,
        child: TextField(
          controller: controller,
          readOnly: !isSinifOgretmeni,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Puan',
          ),
          onChanged: (val) {
            if (isSinifOgretmeni) {
              onDegisti(val.isEmpty ? '+' : val);
            }
          },
        ),
      );
    } else {
      return SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          readOnly: !isSinifOgretmeni,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Yazı',
          ),
          onChanged: (val) {
            if (isSinifOgretmeni) {
              onDegisti(val.isEmpty ? '+' : val);
            }
          },
        ),
      );
    }
  }
}
