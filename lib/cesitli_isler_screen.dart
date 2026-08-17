// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:durugol_cicekleri/Dogum_Gunleri_Screen.dart';
import 'package:durugol_cicekleri/Kisisel_Atasozleri_Screen.dart';
import 'package:durugol_cicekleri/Kisisel_Deyimler_Screen.dart';
import 'package:durugol_cicekleri/Kisisel_Ingilizce_Sozluk.dart'; // İngilizce Sözlük eklendi
import 'package:durugol_cicekleri/Kisisel_Sozluk_Screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'nobetci_screen.dart';
import 'Ogrenci_Oturma_Duzeni_Screen.dart';
import 'Ogrenci_Gorevli_Goruntuleme_Screen.dart';
import 'Ogrenci_Haftalik_Ders_Programi_Screen.dart';
import 'Ogrenci_Etkinlikler_Screen.dart';
import 'Ogrenci_Yarismalar_Screen.dart';
import 'istatistik_servisi.dart'; //[cite: 2]

class OgrenciDevamsizlikScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciDevamsizlikScreen({
    super.key,
    required this.classId,
    this.studentId = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devamsızlık Bilgilerim"),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('devamsizliklar')
            .orderBy('tarih', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz devamsızlık kaydı bulunmuyor.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var devamsizlikDocs = snapshot.data!.docs;
          List<String> gelmedigiTarihler = [];

          for (var doc in devamsizlikDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String tarihStr = data['tarih'] ?? '';
            var ogrencilerMap =
                data['ogrenciler'] as Map<String, dynamic>? ?? {};

            if (ogrencilerMap[studentId] == true) {
              String formatliTarih = tarihStr;
              try {
                List<String> parts = tarihStr.split('-');
                if (parts.length == 3) {
                  formatliTarih = "${parts[2]}.${parts[1]}.${parts[0]}";
                }
              } catch (_) {}

              gelmedigiTarihler.add(formatliTarih);
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: gelmedigiTarihler.isEmpty
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gelmedigiTarihler.isEmpty
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Toplam Devamsızlık",
                      style: TextStyle(
                        fontSize: 16,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${gelmedigiTarihler.length} Gün",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gelmedigiTarihler.isEmpty
                          ? "Harika! Hiç devamsızlığınız yok."
                          : "Aşağıdaki tarihlerde okula gelmediğiniz kaydedilmiştir.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Gelmediğiniz Tarihler",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: gelmedigiTarihler.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: gelmedigiTarihler.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(
                                  Icons.event_busy,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                gelmedigiTarihler[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Text(
                                "Gelmedi",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CesitliIslerScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const CesitliIslerScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<CesitliIslerScreen> createState() => _CesitliIslerScreenState();
}

class _CesitliIslerScreenState extends State<CesitliIslerScreen> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      "title": "Nöbetçi",
      "icon": Icons.group_work,
      "color": Colors.green.shade700,
    },
    {"title": "Görevli", "icon": Icons.how_to_vote, "color": Colors.indigo},
    {
      "title": "Oturma Düzeni",
      "icon": Icons.grid_view,
      "color": Colors.indigo.shade700,
    },
    {"title": "Doğum Günleri", "icon": Icons.cake, "color": Colors.pink},
    {"title": "Devamsızlık", "icon": Icons.fact_check, "color": Colors.teal},
    {
      "title": "Ders Programı",
      "icon": Icons.schedule,
      "color": Colors.deepPurple,
    },
    {"title": "Etkinlikler", "icon": Icons.event, "color": Colors.orange},
    {
      "title": "Yarışmalar",
      "icon": Icons.emoji_events,
      "color": Colors.amber.shade800,
    },
    {"title": "Sözlük", "icon": Icons.menu_book, "color": Colors.brown},
    {
      "title": "İngilizce Sözlük",
      "icon": Icons.translate,
      "color": Colors.indigoAccent,
    },
    {
      "title": "Atasözleri",
      "icon": Icons.history_edu,
      "color": Colors.blueGrey,
    },
    {
      "title": "Deyimler",
      "icon": Icons.library_books,
      "color": Colors.deepOrange,
    },
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çeşitli İşler")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: Colors.indigo.shade50,
            child: SizedBox(
              height: 245,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.72,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final String title = item['title'];
                  final IconData icon = item['icon'];
                  final Color color = item['color'];
                  final bool isSelected = _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedIndex = index;
                        });

                        String islemTuruKey = 'cesitli_$title'; //[cite: 2]
                        await IstatistikServisi.islemKaydet(
                          studentId: widget.studentId,
                          islemTuru: islemTuruKey,
                        );

                        if (!context.mounted) return;

                        if (title == "Nöbetçi") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NobetciScreen(
                                studentId: widget.studentId,
                                classId: widget.classId,
                                isTeacher: false,
                              ),
                            ),
                          );
                        } else if (title == "Oturma Düzeni") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciOturmaDuzeniScreen(
                                classId: widget.classId,
                              ),
                            ),
                          );
                        } else if (title == "Deyimler") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiselDeyimlerScreen(
                                classId: widget.classId,
                                isTeacher: false,
                              ),
                            ),
                          );
                        } else if (title == "Atasözleri") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiselAtasozleriScreen(
                                classId: widget.classId,
                                isTeacher: false,
                              ),
                            ),
                          );
                        } else if (title == "İngilizce Sözlük") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiselIngilizceSozluk(
                                classId: widget.classId,
                                userRole: 'student',
                                isTeacher: true,
                              ),
                            ),
                          );
                        } else if (title == "Doğum Günleri") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DogumGunleriScreen(classId: widget.classId),
                            ),
                          );
                        } else if (title == "Devamsızlık") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciDevamsizlikScreen(
                                classId: widget.classId,
                                studentId: widget.studentId,
                              ),
                            ),
                          );
                        } else if (title == "Görevli") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OgrenciGorevliGoruntulemeScreen(
                                    classId: widget.classId,
                                    studentId: widget.studentId,
                                  ),
                            ),
                          );
                        } else if (title == "Ders Programı") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OgrenciHaftalikDersProgramiScreen(
                                    classId: widget.classId,
                                  ),
                            ),
                          );
                        } else if (title == "Sözlük") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiselSozlukScreen(
                                classId: widget.classId,
                                isTeacher: false,
                              ),
                            ),
                          );
                        } else if (title == "Etkinlikler") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciEtkinliklerScreen(
                                classId: widget.classId,
                                studentId: widget.studentId,
                              ),
                            ),
                          );
                        } else if (title == "Yarışmalar") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciYarismalarScreen(
                                classId: widget.classId,
                                studentId: widget.studentId,
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 95,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.indigo
                                : color.withValues(alpha: 0.3),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: color, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.indigo.shade50, Colors.white],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        "Yukarıdaki menüden işlemlerinizi seçebilirsiniz.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        height: 300,
                        child: Lottie.asset(
                          'assets/animations/Summer Camp Animations - School Bus.json',
                          fit: BoxFit.fill,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                "Animasyon yüklenemedi:\n$error",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
