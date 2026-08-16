// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafik paketi

class OgrenciDenemelerScreen extends StatefulWidget {
  final String classId;
  final String studentId;

  const OgrenciDenemelerScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  State<OgrenciDenemelerScreen> createState() => _OgrenciDenemelerScreenState();
}

class _OgrenciDenemelerScreenState extends State<OgrenciDenemelerScreen> {
  List<FlSpot> _grafikNoktalari = [];
  List<String> _sinavIsimleri = [];
  bool _grafikYukleniyor = true;

  final List<String> dersler = [
    "Türkçe",
    "Matematik",
    "Hayat Bilgisi",
    "Fen Bilimleri",
    "İngilizce",
    "Sosyal Bilgiler",
  ];

  @override
  void initState() {
    super.initState();
    _gecmisSinavVerileriniGetir();
  }

  // Öğrencinin geçmiş tüm sınavlarındaki başarı yüzdelerini hesaplayan fonksiyon
  Future<void> _gecmisSinavVerileriniGetir() async {
    try {
      var denemelerSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('denemeler')
          .orderBy('tarih', descending: false)
          .get();

      List<FlSpot> spots = [];
      List<String> sinavlar = [];
      int index = 0;

      for (var denemeDoc in denemelerSnap.docs) {
        String sId = denemeDoc.id;
        var sData = denemeDoc.data();
        String sAdi = sData['sinavAdi'] ?? 'Deneme';

        var sonucDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('denemeler')
            .doc(sId)
            .collection('sonuclar')
            .doc(widget.studentId)
            .get();

        if (sonucDoc.exists) {
          var sonucData = sonucDoc.data() as Map<String, dynamic>;
          int sinavToplamDogru = 0;
          int sinavToplamSoru = 0;

          for (var ders in dersler) {
            if (sonucData.containsKey(ders)) {
              var dersData = sonucData[ders] as Map<String, dynamic>? ?? {};
              int d = (dersData['d'] ?? 0) as int;
              int y = (dersData['y'] ?? 0) as int;
              int b = (dersData['b'] ?? 0) as int;

              sinavToplamDogru += d;
              sinavToplamSoru += (d + y + b);
            }
          }

          double basariYuzdesi = 0.0;
          if (sinavToplamSoru > 0) {
            basariYuzdesi = (sinavToplamDogru / sinavToplamSoru) * 100;
          }

          spots.add(FlSpot(index.toDouble(), basariYuzdesi));
          sinavlar.add(sAdi);
          index++;
        }
      }

      setState(() {
        _grafikNoktalari = spots;
        _sinavIsimleri = sinavlar;
        _grafikYukleniyor = false;
      });
    } catch (e) {
      setState(() => _grafikYukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deneme Sınavı Sonuçlarım"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('denemeler')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz eklenmiş deneme sınavı bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // --- GEÇMİŞ DENEME BAŞARI GRAFİĞİ ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Text(
                  "Genel Başarı Gelişim Grafiği (%)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _grafikYukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : _grafikNoktalari.isEmpty
                    ? const Center(
                        child: Text(
                          "Grafik için yeterli sınav sonucu bulunmuyor.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: _grafikNoktalari.isNotEmpty
                              ? (_grafikNoktalari.length - 1).toDouble()
                              : 0,
                          minY: 0,
                          maxY: 100,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    "%${spot.y.toInt()}",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    "${value.toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx >= 0 && idx < _sinavIsimleri.length) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8.0,
                                      child: Transform.rotate(
                                        angle: -0.25,
                                        child: Text(
                                          _sinavIsimleri[idx],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _grafikNoktalari,
                              isCurved: true,
                              color: Colors.indigo,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.indigo.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Text(
                  "Sınav Listesi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              // --- SINAVLARIN LİSTESİ ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String sinavAdi = data['sinavAdi'] ?? '';
                  Timestamp? tarih = data['tarih'] as Timestamp?;
                  String tarihStr = tarih != null
                      ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
                      : "";

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('classes')
                        .doc(widget.classId)
                        .collection('denemeler')
                        .doc(doc.id)
                        .collection('sonuclar')
                        .doc(widget.studentId)
                        .get(),
                    builder: (context, sonucSnap) {
                      bool girildiMi =
                          sonucSnap.hasData && sonucSnap.data!.exists;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            sinavAdi,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Tarih: $tarihStr\nDurum: ${girildiMi ? 'Sonuçlar Açıklandı ✅' : 'Sonuçlar Henüz Girilmedi ⏳'}",
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OgrenciDenemeDetayScreen(
                                  classId: widget.classId,
                                  sinavId: doc.id,
                                  sinavAdi: sinavAdi,
                                  studentId: widget.studentId,
                                ),
                              ),
                            );
                          },
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
    );
  }
}

// ------------------------------------------------------------------
// ÖĞRENCİ İÇİN SALT OKUNUR DENEME DETAY VE SONUÇ EKRANI
// ------------------------------------------------------------------
class OgrenciDenemeDetayScreen extends StatelessWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final String studentId;

  const OgrenciDenemeDetayScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> dersler = [
      "Türkçe",
      "Matematik",
      "Hayat Bilgisi",
      "Fen Bilimleri",
      "İngilizce",
      "Sosyal Bilgiler",
    ];

    return Scaffold(
      appBar: AppBar(title: Text(sinavAdi), centerTitle: true),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('denemeler')
            .doc(sinavId)
            .collection('sonuclar')
            .doc(studentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Bu sınav için henüz sonuçlarınız girilmemiş.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          int toplamDogru = 0;
          int toplamYanlis = 0;
          int toplamBos = 0;

          for (var ders in dersler) {
            if (data.containsKey(ders)) {
              var dersData = data[ders] as Map<String, dynamic>? ?? {};
              toplamDogru += (dersData['d'] ?? 0) as int;
              toplamYanlis += (dersData['y'] ?? 0) as int;
              toplamBos += (dersData['b'] ?? 0) as int;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Toplam Doğru",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "$toplamDogru",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Toplam Yanlış",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            "$toplamYanlis",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Toplam Boş",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "$toplamBos",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ders Bazlı Sonuçlarınız:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: dersler.length,
                    itemBuilder: (context, index) {
                      String ders = dersler[index];
                      var dersData = data[ders] as Map<String, dynamic>? ?? {};
                      int d = dersData['d'] ?? 0;
                      int y = dersData['y'] ?? 0;
                      int b = dersData['b'] ?? 0;

                      // Eğer öğrenci o derse ait hiç veri girmemişse listede boş yer kaplamaması için atlayabiliriz
                      if (d == 0 && y == 0 && b == 0) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ders,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Doğru: $d",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Yanlış: $y",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Boş: $b",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
