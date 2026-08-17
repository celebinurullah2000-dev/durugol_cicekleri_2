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
  // Filtreleme türü: 0 = Varsayılan, 1 = Olumludan Olumsuza, 2 = Olumsuzdan Olumluya
  int _secilenFiltre = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Davranis Takip Modulu"),
        centerTitle: true,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Ogrencileri Filtrele / Sirala",
            onSelected: (deger) {
              setState(() {
                _secilenFiltre = deger;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text("Siralama Yok (Varsayilan)"),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text("1. Olumludan Olumsuza (Yuksekten Dusuge)"),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text("2. Olumsuzdan Olumluya (Dusukten Yuksege)"),
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
              child: Text("Bu sinifta kayitli ogrenci bulunamadi."),
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

              // Net puana göre sıralama mantığı
              students.sort((a, b) {
                var dataA = davranisMap[a.id] ?? {};
                var dataB = davranisMap[b.id] ?? {};

                int sariA = dataA['sariKart'] ?? 0;
                int yesilA = dataA['yesilKart'] ?? 0;
                int kirmiziA = sariA ~/ 3;
                int kalanSariA = sariA % 3;
                int altinA = yesilA ~/ 3;
                int kalanYesilA = yesilA % 3;
                int netPuanA =
                    ((altinA * 3) + kalanYesilA) -
                    ((kirmiziA * 3) + kalanSariA);

                int sariB = dataB['sariKart'] ?? 0;
                int yesilB = dataB['yesilKart'] ?? 0;
                int kirmiziB = sariB ~/ 3;
                int kalanSariB = sariB % 3;
                int altinB = yesilB ~/ 3;
                int kalanYesilB = yesilB % 3;
                int netPuanB =
                    ((altinB * 3) + kalanYesilB) -
                    ((kirmiziB * 3) + kalanSariB);

                if (_secilenFiltre == 1) {
                  // Olumludan Olumsuza (En yüksek puandan en düşük puana doğru)
                  return netPuanB.compareTo(netPuanA);
                } else if (_secilenFiltre == 2) {
                  // Olumsuzdan Olumluya (En düşük puandan en yüksek puana doğru)
                  return netPuanA.compareTo(netPuanB);
                }
                return 0;
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
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adSoyad,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDengeBari(
                            gosterilecekSari,
                            gosterilecekKirmizi,
                            gosterilecekYesil,
                            gosterilecekAltin,
                            netPuan,
                          ),
                          const SizedBox(height: 12),

                          // ORTA KISIM: Olumsuz Davranislar (Sari & Kirmizi)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      "Sari: $kalanSari | Kirmizi: $hamKirmizi",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // SADECE SINIF OGRETMENINE GORUNEN BUTONLAR
                                if (widget.isTeacher)
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(70, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => _kartGuncelle(
                                          widget.classId,
                                          studentId,
                                          hamSari + 1,
                                          hamYesil,
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          "Sari Ekle",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        tooltip: "Olumsuz Karti Azalt",
                                        onPressed: hamSari > 0
                                            ? () => _kartGuncelle(
                                                widget.classId,
                                                studentId,
                                                hamSari - 1,
                                                hamYesil,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // ALT KISIM: Olumlu Davranislar (Yesil & Altin)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      "Yesil: $kalanYesil | Altin: $hamAltin",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // SADECE SINIF OGRETMENINE GORUNEN BUTONLAR
                                if (widget.isTeacher)
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(70, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => _kartGuncelle(
                                          widget.classId,
                                          studentId,
                                          hamSari,
                                          hamYesil + 1,
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          "Yesil Ekle",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        tooltip: "Olumlu Karti Azalt",
                                        onPressed: hamYesil > 0
                                            ? () => _kartGuncelle(
                                                widget.classId,
                                                studentId,
                                                hamSari,
                                                hamYesil - 1,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  void _kartGuncelle(
    String classId,
    String studentId,
    int yeniSari,
    int yeniYesil,
  ) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('davranislar')
        .doc(studentId)
        .set({
          'sariKart': yeniSari < 0 ? 0 : yeniSari,
          'yesilKart': yeniYesil < 0 ? 0 : yeniYesil,
          'guncellemeTarihi': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
              "Davranis Denge Bari",
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
                      : (netPuan > 0 ? "Arti: +$netPuan" : "Eksi: $netPuan"),
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
