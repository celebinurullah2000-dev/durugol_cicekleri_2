import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciDavranisScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciDavranisScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Davranış Durumum"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Kart Geçmişi Detayları",
            onPressed: () => _detayliGecmisGoster(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('davranislar')
            .doc(studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          int hamSari = 0;
          int hamYesil = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            hamSari = data['sariKart'] ?? 0;
            hamYesil = data['yesilKart'] ?? 0;
          }

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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Genel Davranış Denge Durumun",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Denge Barı Kartı
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDengeBari(
                      gosterilecekSari,
                      gosterilecekKirmizi,
                      gosterilecekYesil,
                      gosterilecekAltin,
                      netPuan,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Kart Detayların:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Olumlu Kartlar Özeti
                Card(
                  color: Colors.green.shade50,
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 30,
                    ),
                    title: const Text(
                      "Olumlu Kartların",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Yeşil Kart: $kalanYesil | Altın Kart: $hamAltin",
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Olumsuz Kartlar Özeti
                Card(
                  color: Colors.red.shade50,
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                    title: const Text(
                      "Geliştirilmesi Gerekenler",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Sarı Kart: $kalanSari | Kırmızı Kart: $hamKirmizi",
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _detayliGecmisGoster(context),
                    icon: const Icon(Icons.list_alt),
                    label: const Text("Tüm Kart Geçmişimi Görüntüle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _detayliGecmisGoster(BuildContext context) {
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
              const Text(
                "Kart Geçmişi ve Nedenleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
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
                        child: Text("Henüz kaydedilmiş bir kart geçmişi yok."),
                      );
                    }

                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        String type = data['cardType'] ?? 'yellow';
                        String reason = data['reason'] ?? 'Belirtilmemiş';
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
                            trailing: Chip(
                              label: Text(
                                isYellow ? "Sarı Kart" : "Yeşil Kart",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: isYellow
                                  ? Colors.orange
                                  : Colors.green,
                            ),
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
              "Denge Barı",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(emojiDurum, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  netPuan == 0
                      ? "Denge (0)"
                      : (netPuan > 0 ? "Artı: +$netPuan" : "Eksi: $netPuan"),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
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
                          height: 16,
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
                          height: 16,
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
                          height: 16,
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
                          height: 16,
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
