// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgretmenDavranisScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;

  const OgretmenDavranisScreen({
    super.key,
    required this.classId,
    this.className = "",
    this.isTeacher = true,
  });

  @override
  State<OgretmenDavranisScreen> createState() => _OgretmenDavranisScreenState();
}

class _OgretmenDavranisScreenState extends State<OgretmenDavranisScreen> {
  int _secilenFiltre = 0;

  @override
  void initState() {
    super.initState();
    _varsayilanNedenleriKontrolEtVeYukle();
    _otomatikHaftalikYesilKartKontrolu();
  }

  // Varsayılan Sarı Kart Nedenlerini İlk Kurulumda Yükleme
  Future<void> _varsayilanNedenleriKontrolEtVeYukle() async {
    var ref = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('behavior_settings');

    var snapshot = await ref.get();
    if (snapshot.docs.isEmpty) {
      List<String> varsayilanSari = [
        "Derse geç gelme",
        "Derste konuşma",
        "Sırasını temiz kullanmama",
        "Arkadaşlarına kötü davranma",
        "Kötü söz kullanma",
        "Eksik ödev",
        "Eksik eşya",
      ];
      for (var neden in varsayilanSari) {
        await ref.add({'type': 'yellow', 'reason': neden});
      }
    }
  }

  // Otomatik Haftalık Yeşil Kart Kontrolü (Pazartesi 08:00 - Cuma 16:30)
  Future<void> _otomatikHaftalikYesilKartKontrolu() async {
    DateTime simdi = DateTime.now();
    // Cuma günü saat 16:30'dan sonra veya hafta sonu çalıştırılabilir / kontrol edilebilir
    // Öğretmen ekranı açıldığında bu hafta kontrol edilmiş mi diye bakılır.
    if (simdi.weekday == DateTime.friday &&
        (simdi.hour > 16 || (simdi.hour == 16 && simdi.minute >= 30))) {
      var sinifRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId);

      // Bu haftanın pazartesi başlangıcı
      DateTime pazartesi = simdi.subtract(Duration(days: simdi.weekday - 1));
      pazartesi = DateTime(
        pazartesi.year,
        pazartesi.month,
        pazartesi.day,
        8,
        0,
      );

      var studentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      for (var studentDoc in studentsSnap.docs) {
        String studentId = studentDoc.id;

        // Bu hafta içinde sarı kart almış mı kontrol et
        var historySnap = await sinifRef
            .collection('davranislar')
            .doc(studentId)
            .collection('history')
            .where('cardType', isEqualTo: 'yellow')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(pazartesi),
            )
            .get();

        if (historySnap.docs.isEmpty) {
          // Bu hafta hiç sarı kart almamış! Daha önce bu hafta otomatik yeşil verildi mi?
          var autoCheckDoc = await sinifRef
              .collection('davranislar')
              .doc(studentId)
              .collection('weekly_awards')
              .doc("${pazartesi.year}-${pazartesi.month}-${pazartesi.day}")
              .get();

          if (!autoCheckDoc.exists) {
            // Otomatik Yeşil Kart Ver
            var davranisRef = sinifRef.collection('davranislar').doc(studentId);
            var davDoc = await davranisRef.get();
            int mevcutYesil = 0;
            if (davDoc.exists) {
              mevcutYesil = (davDoc.data()?['yesilKart'] ?? 0);
            }

            await davranisRef.set({
              'yesilKart': mevcutYesil + 1,
              'guncellemeTarihi': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Geçmişe ekle
            await davranisRef.collection('history').add({
              'cardType': 'green',
              'reason': 'Haftalık Sarı Kartsız Başarı Ödülü',
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Bu hafta ödül verildi olarak işaretle
            await sinifRef
                .collection('davranislar')
                .doc(studentId)
                .collection('weekly_awards')
                .doc("${pazartesi.year}-${pazartesi.month}-${pazartesi.day}")
                .set({'awarded': true});
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Davranış Modülü"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications),
            tooltip: "Kart Nedenlerini Yönet",
            onPressed: () => _nedenleriYonetDialogGoster(context),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Öğrencileri Filtrele / Sırala",
            onSelected: (deger) {
              setState(() {
                _secilenFiltre = deger;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text("Alfabetik Sıralama (Varsayılan)"),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text("1. Olumludan Olumsuza (Puana Göre)"),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text("2. Olumsuzdan Olumluya (Puana Göre)"),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bu sınıfta kayıtlı öğrenci bulunamadı."),
            );
          }

          var students = studentSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('davranislar')
                .snapshots(),
            builder: (context, davranisSnapshot) {
              if (davranisSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, dynamic>> davranisMap = {};
              if (davranisSnapshot.hasData) {
                for (var doc in davranisSnapshot.data!.docs) {
                  davranisMap[doc.id] = doc.data() as Map<String, dynamic>;
                }
              }

              students.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                String adA =
                    "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                String adB =
                    "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";

                if (_secilenFiltre == 1 || _secilenFiltre == 2) {
                  var davranisA = davranisMap[a.id] ?? {};
                  var davranisB = davranisMap[b.id] ?? {};

                  int sariA = davranisA['sariKart'] ?? 0;
                  int yesilA = davranisA['yesilKart'] ?? 0;
                  int netPuanA =
                      ((yesilA ~/ 3 * 3) + (yesilA % 3)) -
                      ((sariA ~/ 3 * 3) + (sariA % 3));

                  int sariB = davranisB['sariKart'] ?? 0;
                  int yesilB = davranisB['yesilKart'] ?? 0;
                  int netPuanB =
                      ((yesilB ~/ 3 * 3) + (yesilB % 3)) -
                      ((sariB ~/ 3 * 3) + (sariB % 3));

                  if (_secilenFiltre == 1) {
                    return netPuanB.compareTo(netPuanA);
                  } else {
                    return netPuanA.compareTo(netPuanB);
                  }
                }
                return _turkceKarsilastir(adA, adB);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var studentDoc = students[index];
                  var studentData = studentDoc.data() as Map<String, dynamic>;
                  String studentId = studentDoc.id;
                  String adSoyad =
                      "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

                  var davranisData = davranisMap[studentId] ?? {};
                  int hamSari = davranisData['sariKart'] ?? 0;
                  int hamYesil = davranisData['yesilKart'] ?? 0;

                  int hamKirmizi = hamSari ~/ 3;
                  int kalanSari = hamSari % 3;

                  int hamAltin = hamYesil ~/ 3;
                  int kalanYesil = hamYesil % 3;

                  int toplamNegatifPuan = (hamKirmizi * 3) + kalanSari;
                  int toplamPozitifPuan = (hamAltin * 3) + kalanYesil;
                  int netPuan = toplamPozitifPuan - toplamNegatifPuan;

                  int gosterilecekSari = 0;
                  int gosterilecekKirmizi = 0;
                  int gosterilecekYesil = 0;
                  int gosterilecekAltin = 0;

                  if (netPuan < 0) {
                    int eksiKalan = -netPuan;
                    gosterilecekKirmizi = eksiKalan ~/ 3;
                    gosterilecekSari = eksiKalan % 3;
                  } else if (netPuan > 0) {
                    int artiKalan = netPuan;
                    gosterilecekAltin = artiKalan ~/ 3;
                    gosterilecekYesil = artiKalan % 3;
                  }

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        adSoyad,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: netPuan > 0
                            ? Colors.green.shade100
                            : (netPuan < 0
                                  ? Colors.red.shade100
                                  : Colors.grey.shade200),
                        child: Text(
                          netPuan == 0
                              ? "0"
                              : (netPuan > 0 ? "+$netPuan" : "$netPuan"),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: netPuan > 0
                                ? Colors.green.shade800
                                : (netPuan < 0
                                      ? Colors.red.shade800
                                      : Colors.grey.shade800),
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.history, color: Colors.blue),
                        tooltip: "Kart Geçmişi & Detaylar",
                        onPressed: () =>
                            _ogrenciGecmisiGoster(context, studentId, adSoyad),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDengeBari(
                                gosterilecekSari,
                                gosterilecekKirmizi,
                                gosterilecekYesil,
                                gosterilecekAltin,
                                netPuan,
                              ),
                              const SizedBox(height: 12),

                              // Sarı Kart Alanı
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade100,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Sarı: $kalanSari | Kırmızı: $hamKirmizi",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.isTeacher)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => _kartEkleSecimli(
                                          context,
                                          studentId,
                                          'yellow',
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          "Sarı Ekle",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Yeşil Kart Alanı
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade100,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Yeşil: $kalanYesil | Altın: $hamAltin",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.isTeacher)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => _kartEkleSecimli(
                                          context,
                                          studentId,
                                          'green',
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          "Yeşil Ekle",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Neden Seçerek Kart Ekleme Dialogu
  void _kartEkleSecimli(
    BuildContext context,
    String studentId,
    String cardType,
  ) async {
    // Nedenleri getir
    var querySnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('behavior_settings')
        .where('type', isEqualTo: cardType)
        .get();

    List<String> nedenler = querySnapshot.docs
        .map((doc) => doc.data()['reason'].toString())
        .toList();

    String? secilenNeden;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            cardType == 'yellow'
                ? "Sarı Kart Nedeni Seçin"
                : "Yeşil Kart Nedeni Seçin",
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: nedenler.isEmpty
                ? const Text(
                    "Tanımlı neden bulunamadı. Lütfen önce neden ekleyin.",
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: nedenler.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(nedenler[index]),
                        onTap: () {
                          secilenNeden = nedenler[index];
                          Navigator.pop(context);
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
          ],
        );
      },
    ).then((_) async {
      if (secilenNeden != null) {
        var docRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('davranislar')
            .doc(studentId);

        var snapshot = await docRef.get();
        int currentSari = 0;
        int currentYesil = 0;

        if (snapshot.exists) {
          currentSari = snapshot.data()?['sariKart'] ?? 0;
          currentYesil = snapshot.data()?['yesilKart'] ?? 0;
        }

        if (cardType == 'yellow') {
          currentSari += 1;
        } else {
          currentYesil += 1;
        }

        // Ana sayaçları güncelle
        await docRef.set({
          'sariKart': currentSari,
          'yesilKart': currentYesil,
          'guncellemeTarihi': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Geçmiş alt koleksiyonuna detay ekle
        await docRef.collection('history').add({
          'cardType': cardType,
          'reason': secilenNeden,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kart başarıyla eklendi: $secilenNeden")),
        );
      }
    });
  }

  // Öğrenci Kart Geçmişini ve Silme Özelliğini Gösteren Dialog / Sheet
  void _ogrenciGecmisiGoster(
    BuildContext context,
    String studentId,
    String adSoyad,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$adSoyad - Kart Geçmişi",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Geçmiş bir kartı silmek için yanındaki çöp kutusuna tıklayabilirsiniz.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('davranislar')
                      .doc(studentId)
                      .collection('history')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Bu öğrenciye ait kart geçmişi bulunmuyor.",
                        ),
                      );
                    }

                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        String historyId = doc.id;
                        String type = data['cardType'] ?? 'yellow';
                        String reason = data['reason'] ?? 'Neden yok';
                        Timestamp? t = data['timestamp'] as Timestamp?;
                        String tarihStr = t != null
                            ? "${t.toDate().day}.${t.toDate().month}.${t.toDate().year} - ${t.toDate().hour.toString().padLeft(2, '0')}:${t.toDate().minute.toString().padLeft(2, '0')}"
                            : "Tarih yok";

                        bool isYellow = type == 'yellow';

                        return Card(
                          color: isYellow
                              ? Colors.amber.shade50
                              : Colors.green.shade50,
                          child: ListTile(
                            leading: Icon(
                              isYellow ? Icons.warning : Icons.star,
                              color: isYellow ? Colors.orange : Colors.green,
                            ),
                            title: Text(
                              reason,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(tarihStr),
                            trailing: widget.isTeacher
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _gecmisKartSil(
                                      studentId,
                                      historyId,
                                      type,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Geçmişten Kart Silme ve Puanı Güncelleme Fonksiyonu
  void _gecmisKartSil(
    String studentId,
    String historyId,
    String cardType,
  ) async {
    var docRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('davranislar')
        .doc(studentId);

    var snapshot = await docRef.get();
    int currentSari = 0;
    int currentYesil = 0;

    if (snapshot.exists) {
      currentSari = snapshot.data()?['sariKart'] ?? 0;
      currentYesil = snapshot.data()?['yesilKart'] ?? 0;
    }

    if (cardType == 'yellow' && currentSari > 0) {
      currentSari -= 1;
    } else if (cardType == 'green' && currentYesil > 0) {
      currentYesil -= 1;
    }

    // Ana sayacı güncelle
    await docRef.set({
      'sariKart': currentSari,
      'yesilKart': currentYesil,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // History belgesini sil
    await docRef.collection('history').doc(historyId).delete();
  }

  // Nedenleri Yönetme (Ekleme ve Silme) Ekranı
  void _nedenleriYonetDialogGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String yeniNeden = "";
        String secilenTip = "yellow";

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Kart Nedenlerini Yönet"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: secilenTip,
                      items: const [
                        DropdownMenuItem(
                          value: 'yellow',
                          child: Text("Sarı Kart Nedenleri"),
                        ),
                        DropdownMenuItem(
                          value: 'green',
                          child: Text("Yeşil Kart Nedenleri"),
                        ),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          secilenTip = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Yeni Neden Yazın",
                      ),
                      onChanged: (val) => yeniNeden = val,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (yeniNeden.trim().isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.classId)
                              .collection('behavior_settings')
                              .add({
                                'type': secilenTip,
                                'reason': yeniNeden.trim(),
                              });
                          Navigator.pop(context);
                          _nedenleriYonetDialogGoster(context); // Yeniden aç
                        }
                      },
                      child: const Text("Neden Ekle"),
                    ),
                    const Divider(),
                    const Text(
                      "Mevcut Nedenler (Silmek için üzerine dokunun):",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: double.maxFinite,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.classId)
                              .collection('behavior_settings')
                              .where('type', isEqualTo: secilenTip)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            var docs = snapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                var d = docs[index];
                                var dat = d.data() as Map<String, dynamic>;
                                return ListTile(
                                  dense: true,
                                  title: Text(dat['reason'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      await d.reference.delete();
                                      setStateDialog(() {});
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildDengeBari(
    int sari,
    int kirmizi,
    int yesil,
    int altin,
    int netPuan,
  ) {
    String emojiDurum = "😐";
    Color durumRengi = Colors.grey;

    if (netPuan > 0) {
      durumRengi = Colors.green.shade700;
      if (netPuan <= 3) {
        emojiDurum = "😊";
      } else if (netPuan <= 6) {
        emojiDurum = "😁";
      } else if (netPuan <= 9) {
        emojiDurum = "😍";
      } else {
        emojiDurum = "👑💖";
      }
    } else if (netPuan < 0) {
      durumRengi = Colors.red.shade700;
      int eksiDeger = -netPuan;
      if (eksiDeger <= 3) {
        emojiDurum = "😕";
      } else if (eksiDeger <= 6) {
        emojiDurum = "😟";
      } else {
        emojiDurum = "😢";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Davranış Denge Barı",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(emojiDurum, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  netPuan == 0
                      ? "Denge (0)"
                      : (netPuan > 0 ? "Artı: +$netPuan" : "Eksi: $netPuan"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (kirmizi > 0)
                        Container(
                          height: 14,
                          width: (kirmizi * 12.0).clamp(0.0, 80.0),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      const SizedBox(width: 1),
                      if (sari > 0)
                        Container(
                          height: 14,
                          width: (sari * 10.0).clamp(0.0, 60.0),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: kirmizi == 0
                                ? const BorderRadius.horizontal(
                                    left: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(width: 2, color: Colors.black87),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (yesil > 0)
                        Container(
                          height: 14,
                          width: (yesil * 10.0).clamp(0.0, 60.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: altin == 0
                                ? const BorderRadius.horizontal(
                                    right: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                        ),
                      const SizedBox(width: 1),
                      if (altin > 0)
                        Container(
                          height: 14,
                          width: (altin * 12.0).clamp(0.0, 80.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
