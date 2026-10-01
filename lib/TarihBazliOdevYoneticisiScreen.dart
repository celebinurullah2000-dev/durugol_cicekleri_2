// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TarihBazliOdevYoneticisiScreen extends StatefulWidget {
  final String classId;

  const TarihBazliOdevYoneticisiScreen({super.key, required this.classId});

  @override
  State<TarihBazliOdevYoneticisiScreen> createState() =>
      _TarihBazliOdevYoneticisiScreenState();
}

class _TarihBazliOdevYoneticisiScreenState
    extends State<TarihBazliOdevYoneticisiScreen> {
  final Map<String, String> _filtreler = {};

  // Yerel olarak yapılan değişiklikleri tutacak harita:
  // Key: "studentId___tarihStr___kitapIndex", Value: "yeni_durum"
  final Map<String, String> _yerelDegisiklikler = {};

  bool _isSaving = false;

  // Toplu durum değiştirme (Sadece yerel state'i günceller)
  void _topluDurumYerelGuncelle(
    List<QueryDocumentSnapshot<Object?>> ogrenciler,
    String tarihStr,
    int kitapIndex,
    String yeniDurum,
  ) {
    setState(() {
      for (var ogrDoc in ogrenciler) {
        String anahtar = "${ogrDoc.id}___${tarihStr}___$kitapIndex";
        _yerelDegisiklikler[anahtar] = yeniDurum;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sınıftaki tüm öğrencilerin durumu '$yeniDurum' olarak seçildi. Kaydetmeyi unutmayın!",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Tekil durum değiştirme (Sadece yerel state'i günceller)
  void _tekilDurumYerelGuncelle(
    String studentId,
    String tarihStr,
    int kitapIndex,
    String yeniDurum,
  ) {
    setState(() {
      String anahtar = "${studentId}___${tarihStr}___$kitapIndex";
      _yerelDegisiklikler[anahtar] = yeniDurum;
    });
  }

  // Gerçek Veritabanı Kayıt İşlemi
  Future<void> _tumDegisiklikleriKaydet() async {
    if (_yerelDegisiklikler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kaydedilecek değişiklik yok.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (var entry in _yerelDegisiklikler.entries) {
        var parts = entry.key.split('___');
        if (parts.length != 3) continue;

        String studentId = parts[0];
        String tarihStr = parts[1];
        int kitapIndex = int.parse(parts[2]);
        String yeniDurum = entry.value;

        var odevlerRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .collection('odevler');

        var odevQuery = await odevlerRef
            .where('tarihStr', isEqualTo: tarihStr)
            .get();

        if (odevQuery.docs.isNotEmpty) {
          var docId = odevQuery.docs.first.id;
          var veri = odevQuery.docs.first.data();
          List kitaplar = List.from(veri['kitaplar'] ?? []);

          if (kitaplar.length > kitapIndex) {
            Map<String, dynamic> kitap = Map.from(kitaplar[kitapIndex]);
            String eskiDurum = kitap['durum'] ?? 'bekliyor';

            kitap['durum'] = yeniDurum;
            kitaplar[kitapIndex] = kitap;

            await odevlerRef.doc(docId).update({'kitaplar': kitaplar});

            // Eğer 'yapildi' iken 'ogretmen_reddi' (yapılmadı) yapıldıysa sarı kart ekle
            if (eskiDurum == 'yapildi' && yeniDurum == 'ogretmen_reddi') {
              var davranisRef = FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('davranislar')
                  .doc(studentId);

              await FirebaseFirestore.instance.runTransaction((
                transaction,
              ) async {
                var snapshot = await transaction.get(davranisRef);
                int mevcutSari = 0;
                if (snapshot.exists && snapshot.data() != null) {
                  mevcutSari = (snapshot.data()!['sariKart'] ?? 0) as int;
                }
                transaction.set(davranisRef, {
                  'sariKart': mevcutSari + 1,
                  'guncellemeTarihi': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              });
            }
          }
        }
      }

      setState(() {
        _yerelDegisiklikler.clear();
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tüm ödev değişiklikleri başarıyla kaydedildi! 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kayıt sırasında hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Türkçe tarih stringini DateTime nesnesine çeviren yardımcı fonksiyon
  DateTime? _parseTurkishDate(String str) {
    try {
      str = str.replaceAll(',', '').trim();
      var parts = str.split(RegExp(r'\s+'));
      if (parts.length < 3) return null;

      int day = int.parse(parts[0]);
      String monthName = parts[1].toLowerCase();
      int year = int.parse(parts[2]);

      Map<String, int> monthsMap = {
        'ocak': 1,
        'şubat': 2,
        'mart': 3,
        'nisan': 4,
        'mayıs': 5,
        'haziran': 6,
        'temmuz': 7,
        'ağustos': 8,
        'eylül': 9,
        'ekim': 10,
        'kasım': 11,
        'aralık': 12,
      };

      int month = monthsMap[monthName] ?? 1;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Toplu Ödev Düzenleme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .limit(1)
            .snapshots(),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Sınıfta öğrenci bulunamadı."));
          }

          var sampleStudentId = studentSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(sampleStudentId)
                .collection('odevler')
                .snapshots(),
            builder: (context, odevSnapshot) {
              if (odevSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!odevSnapshot.hasData || odevSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Henüz verilmiş bir ödev bulunmuyor."),
                );
              }

              var odevler = List.from(odevSnapshot.data!.docs);
              odevler.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                String tarihA = dataA['tarihStr'] ?? '';
                String tarihB = dataB['tarihStr'] ?? '';

                DateTime? dtA = _parseTurkishDate(tarihA);
                DateTime? dtB = _parseTurkishDate(tarihB);

                if (dtA == null && dtB == null) return 0;
                if (dtA == null) return 1;
                if (dtB == null) return -1;

                return dtB.compareTo(dtA);
              });

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80.0),
                itemCount: odevler.length,
                itemBuilder: (context, index) {
                  var odevData = odevler[index].data() as Map<String, dynamic>;
                  String tarihStr =
                      odevData['tarihStr'] ?? 'Tarih Belirtilmemiş';
                  List kitaplar = odevData['kitaplar'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey<String>('tarih_$tarihStr'),
                      title: Text(
                        tarihStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      subtitle: Text(
                        "${kitaplar.length} adet ödev kitabı/kalemi bulunuyor",
                      ),
                      children: [
                        ...kitaplar.asMap().entries.map((kitapEntry) {
                          int kIndex = kitapEntry.key;
                          var k = kitapEntry.value;
                          String kitapAdi = k['kitapAdi'] ?? 'Kitap';
                          String sayfa = k['sayfaAraligi'] ?? '';
                          String anahtarKullanim = "${tarihStr}_$kIndex";
                          String mevcutFiltre =
                              _filtreler[anahtarKullanim] ?? 'tumu';

                          return ExpansionTile(
                            key: PageStorageKey<String>(
                              'kitap_${tarihStr}_$kIndex',
                            ),
                            leading: const Icon(
                              Icons.book,
                              color: Colors.indigo,
                            ),
                            title: Text(
                              "$kitapAdi (Sayfa: $sayfa)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.0,
                              ),
                            ),
                            subtitle: const Text(
                              "Öğrenci listesini görmek için dokun",
                              style: TextStyle(fontSize: 11.0),
                            ),
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('students')
                                    .where('classId', isEqualTo: widget.classId)
                                    .snapshots(),
                                builder: (context, sinifSnapshot) {
                                  if (!sinifSnapshot.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  var ogrenciler = sinifSnapshot.data!.docs;

                                  ogrenciler.sort((a, b) {
                                    var dataA =
                                        a.data() as Map<String, dynamic>;
                                    var dataB =
                                        b.data() as Map<String, dynamic>;
                                    String adA =
                                        "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                                    String adB =
                                        "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
                                    return _turkceKarsilastir(adA, adB);
                                  });

                                  return Column(
                                    children: [
                                      Container(
                                        color: Colors.grey.shade100,
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                const Text(
                                                  "Toplu:",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _topluDurumYerelGuncelle(
                                                        ogrenciler,
                                                        tarihStr,
                                                        kIndex,
                                                        'yapildi',
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          70.0,
                                                          30.0,
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    "Yapıldı",
                                                    style: TextStyle(
                                                      fontSize: 10.0,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _topluDurumYerelGuncelle(
                                                        ogrenciler,
                                                        tarihStr,
                                                        kIndex,
                                                        'bekliyor',
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.orange,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          70.0,
                                                          30.0,
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    "Bekliyor",
                                                    style: TextStyle(
                                                      fontSize: 10.0,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _topluDurumYerelGuncelle(
                                                        ogrenciler,
                                                        tarihStr,
                                                        kIndex,
                                                        'ogretmen_reddi',
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          70.0,
                                                          30.0,
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    "Yapılmadı",
                                                    style: TextStyle(
                                                      fontSize: 10.0,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6.0),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                ChoiceChip(
                                                  label: const Text(
                                                    "Tümü",
                                                    style: TextStyle(
                                                      fontSize: 11.0,
                                                    ),
                                                  ),
                                                  selected:
                                                      mevcutFiltre == 'tumu',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _filtreler[anahtarKullanim] =
                                                          'tumu';
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 8.0),
                                                ChoiceChip(
                                                  label: const Text(
                                                    "Yapanlar",
                                                    style: TextStyle(
                                                      fontSize: 11.0,
                                                    ),
                                                  ),
                                                  selected:
                                                      mevcutFiltre ==
                                                      'yapanlar',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _filtreler[anahtarKullanim] =
                                                          'yapanlar';
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 8.0),
                                                ChoiceChip(
                                                  label: const Text(
                                                    "Yapmayanlar",
                                                    style: TextStyle(
                                                      fontSize: 11.0,
                                                    ),
                                                  ),
                                                  selected:
                                                      mevcutFiltre ==
                                                      'yapmayanlar',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _filtreler[anahtarKullanim] =
                                                          'yapmayanlar';
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        key: PageStorageKey<String>(
                                          'ogrenci_listesi_${widget.classId}_${tarihStr}_$kIndex',
                                        ),
                                        primary: false,
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: ogrenciler.length,
                                        itemBuilder: (context, oIdx) {
                                          var ogrDoc = ogrenciler[oIdx];
                                          var ogrData =
                                              ogrDoc.data()
                                                  as Map<String, dynamic>;
                                          String ogrAd =
                                              "${ogrData['firstName'] ?? ''} ${ogrData['lastName'] ?? ''}";
                                          String ogrId = ogrDoc.id;

                                          String yerelKey =
                                              "${ogrId}___${tarihStr}___$kIndex";

                                          return StreamBuilder<QuerySnapshot>(
                                            stream: ogrDoc.reference
                                                .collection('odevler')
                                                .where(
                                                  'tarihStr',
                                                  isEqualTo: tarihStr,
                                                )
                                                .snapshots(),
                                            builder: (context, ogrOdevSnap) {
                                              String veritabaniDurum =
                                                  'bekliyor';
                                              if (ogrOdevSnap.hasData &&
                                                  ogrOdevSnap
                                                      .data!
                                                      .docs
                                                      .isNotEmpty) {
                                                try {
                                                  var data =
                                                      ogrOdevSnap
                                                              .data!
                                                              .docs
                                                              .first
                                                              .data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  List kList =
                                                      data['kitaplar'] ?? [];
                                                  if (kList.length > kIndex) {
                                                    veritabaniDurum =
                                                        kList[kIndex]['durum'] ??
                                                        'bekliyor';
                                                  }
                                                } catch (_) {}
                                              }

                                              String mevcutDurum =
                                                  _yerelDegisiklikler[yerelKey] ??
                                                  veritabaniDurum;

                                              if (mevcutFiltre == 'yapanlar' &&
                                                  mevcutDurum != 'yapildi') {
                                                return const SizedBox.shrink();
                                              }
                                              if (mevcutFiltre ==
                                                      'yapmayanlar' &&
                                                  mevcutDurum == 'yapildi') {
                                                return const SizedBox.shrink();
                                              }

                                              Color durumRengi = Colors.orange;
                                              if (mevcutDurum == 'yapildi') {
                                                durumRengi = Colors.green;
                                              }
                                              if (mevcutDurum ==
                                                  'ogretmen_reddi') {
                                                durumRengi = Colors.red;
                                              }

                                              bool isModified =
                                                  _yerelDegisiklikler
                                                      .containsKey(yerelKey);

                                              return Container(
                                                color: isModified
                                                    ? Colors.amber.shade50
                                                    : Colors.transparent,
                                                child: ListTile(
                                                  dense: true,
                                                  title: Text(
                                                    ogrAd,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isModified
                                                          ? Colors
                                                                .indigo
                                                                .shade900
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  trailing: DropdownButton<String>(
                                                    value:
                                                        [
                                                          'yapildi',
                                                          'bekliyor',
                                                          'ogretmen_reddi',
                                                        ].contains(mevcutDurum)
                                                        ? mevcutDurum
                                                        : 'bekliyor',
                                                    dropdownColor: Colors.white,
                                                    style: TextStyle(
                                                      color: durumRengi,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 'yapildi',
                                                        child: Text(
                                                          "Yapıldı",
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'bekliyor',
                                                        child: Text(
                                                          "Bekliyor",
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'ogretmen_reddi',
                                                        child: Text(
                                                          "Yapılmadı",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (yeniDeger) {
                                                      if (yeniDeger != null) {
                                                        _tekilDurumYerelGuncelle(
                                                          ogrId,
                                                          tarihStr,
                                                          kIndex,
                                                          yeniDeger,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(12.0),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 50.0,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _tumDegisiklikleriKaydet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Değişiklikleri Kaydet (${_yerelDegisiklikler.length})",
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
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
}
