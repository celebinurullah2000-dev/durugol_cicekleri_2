import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class DevamsizlikScreen extends StatefulWidget {
  final String classId;
  final String userRole; // Kullanıcı rolünü alıyoruz

  const DevamsizlikScreen({
    super.key,
    required this.classId,
    this.userRole = 'classroom_teacher', // Varsayılan değer
  });

  @override
  State<DevamsizlikScreen> createState() => _DevamsizlikScreenState();
}

class _DevamsizlikScreenState extends State<DevamsizlikScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Sekme Değişkenleri
  DateTime _secilenTarih = DateTime.now();
  DateTime _odakTarih = DateTime.now();
  final Map<String, bool> _devamsizOgrenciler = {};
  bool _isLoading = true;

  // Sınıf öğretmeni mi kontrolü
  bool get _isClassroomTeacher {
    String role = widget.userRole.trim().toLowerCase();
    return role == 'classroom_teacher' ||
        role == 'sınıf öğretmeni' ||
        role == 'sinif_ogretmeni';
  }

  @override
  void initState() {
    super.initState();
    // Sınıf öğretmeniyse 3 sekme, değilse 2 sekme (Yoklama Al hariç)
    int tabLength = _isClassroomTeacher ? 3 : 2;
    _tabController = TabController(length: tabLength, vsync: this);

    if (_isClassroomTeacher) {
      _mevcutDevamsizliklariGetir();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _tarihKey {
    return "${_secilenTarih.year}-${_secilenTarih.month.toString().padLeft(2, '0')}-${_secilenTarih.day.toString().padLeft(2, '0')}";
  }

  Future<void> _mevcutDevamsizliklariGetir() async {
    if (!_isClassroomTeacher) return;
    setState(() => _isLoading = true);
    var snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('devamsizliklar')
        .doc(_tarihKey)
        .get();

    _devamsizOgrenciler.clear();
    if (snapshot.exists && snapshot.data() != null) {
      var data = snapshot.data()!['ogrenciler'] as Map<String, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          _devamsizOgrenciler[key] = value == true;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _devamsizliklariKaydet() async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('devamsizliklar')
        .doc(_tarihKey)
        .set({'tarih': _tarihKey, 'ogrenciler': _devamsizOgrenciler});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Devamsızlık kayıtları başarıyla güncellendi."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [];
    List<Widget> tabViews = [];

    // Sadece sınıf öğretmeniyse "Yoklama Al" sekmesini ve içeriğini ekliyoruz
    if (_isClassroomTeacher) {
      tabs.add(const Tab(icon: Icon(Icons.edit_calendar), text: "Yoklama Al"));
      tabViews.add(_buildYoklamaAlmaSekmesi());
    }

    // Geçmiş Raporu ve Öğrenci Bazlı Özet her zaman görünür
    tabs.add(const Tab(icon: Icon(Icons.history), text: "Geçmiş Raporu"));
    tabs.add(
      const Tab(icon: Icon(Icons.pie_chart), text: "Öğrenci Bazlı Özet"),
    );

    tabViews.add(_buildGecmisRaporuSekmesi());
    tabViews.add(_buildOgrenciBazliOzetSekmesi());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrenci Devamsızlık Takibi"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabs,
        ),
      ),
      body: TabBarView(controller: _tabController, children: tabViews),
    );
  }

  // ================= 1. SEKME: YOKLAMA ALMA WIDGET =================
  Widget _buildYoklamaAlmaSekmesi() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          elevation: 3,
          child: TableCalendar(
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _odakTarih,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.week,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextFormatter: (date, locale) {
                const months = [
                  'Ocak',
                  'Şubat',
                  'Mart',
                  'Nisan',
                  'Mayıs',
                  'Haziran',
                  'Temmuz',
                  'Ağustos',
                  'Eylül',
                  'Ekim',
                  'Kasım',
                  'Aralık',
                ];
                return '${months[date.month - 1]} ${date.year}';
              },
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) {
                const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                return days[date.weekday - 1];
              },
            ),
            selectedDayPredicate: (day) => isSameDay(_secilenTarih, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _secilenTarih = selectedDay;
                _odakTarih = focusedDay;
              });
              _mevcutDevamsizliklariGetir();
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_secilenTarih.day}.${_secilenTarih.month}.${_secilenTarih.year} Tarihli Yoklama",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _devamsizliklariKaydet,
                icon: const Icon(Icons.save, size: 18),
                label: const Text("Kaydet"),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .where('classId', isEqualTo: widget.classId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data!.docs;

                    docs.sort((a, b) {
                      var dataA = a.data() as Map<String, dynamic>;
                      var dataB = b.data() as Map<String, dynamic>;
                      String adA = (dataA['firstName'] ?? '').toString();
                      String adB = (dataB['firstName'] ?? '').toString();
                      return adA.compareTo(adB);
                    });

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("Bu sınıfta kayıtlı öğrenci bulunmuyor."),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var studentDoc = docs[index];
                        String studentId = studentDoc.id;
                        var studentData =
                            studentDoc.data() as Map<String, dynamic>;

                        String firstName = studentData['firstName'] ?? '';
                        String lastName = studentData['lastName'] ?? '';
                        String adSoyad = "$firstName $lastName".trim();
                        if (adSoyad.isEmpty) adSoyad = 'İsimsiz';

                        bool isGelmedi =
                            _devamsizOgrenciler[studentId] ?? false;

                        return CheckboxListTile(
                          title: Text(adSoyad),
                          subtitle: Text(
                            isGelmedi ? "Gelmedi (Devamsız)" : "Geldi",
                          ),
                          value: isGelmedi,
                          activeColor: Colors.red,
                          onChanged: (bool? value) {
                            setState(() {
                              _devamsizOgrenciler[studentId] = value ?? false;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ================= 2. SEKME: GEÇMİŞ DEVAMSIZLIK RAPORU =================
  Widget _buildGecmisRaporuSekmesi() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
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
              "Henüz kaydedilmiş bir devamsızlık geçmişi bulunmuyor.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          );
        }

        var devamsizlikDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: devamsizlikDocs.length,
          itemBuilder: (context, index) {
            var data = devamsizlikDocs[index].data() as Map<String, dynamic>;
            String tarihStr = data['tarih'] ?? '';
            var ogrencilerMap =
                data['ogrenciler'] as Map<String, dynamic>? ?? {};

            List<String> gelmeyenIdler = ogrencilerMap.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList();

            String formatliTarih = tarihStr;
            try {
              List<String> parts = tarihStr.split('-');
              if (parts.length == 3) {
                formatliTarih = "${parts[2]}.${parts[1]}.${parts[0]}";
              }
            } catch (_) {}

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ExpansionTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.event_busy, color: Colors.white, size: 20),
                ),
                title: Text(
                  "$formatliTarih Tarihi Yoklaması",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  gelmeyenIdler.isEmpty
                      ? "Tüm öğrenciler katıldı (Devamsız yok)"
                      : "${gelmeyenIdler.length} öğrenci gelmedi",
                  style: TextStyle(
                    color: gelmeyenIdler.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
                children: [
                  if (gelmeyenIdler.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("Bu tarihte devamsız öğrenci yok."),
                    )
                  else
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('students')
                          .where(
                            FieldPath.documentId,
                            whereIn: gelmeyenIdler.take(10).toList(),
                          )
                          .get(),
                      builder: (context, studentSnapshot) {
                        if (!studentSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }

                        var studentDocs = studentSnapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: studentDocs.length,
                          itemBuilder: (context, sIndex) {
                            var sData =
                                studentDocs[sIndex].data()
                                    as Map<String, dynamic>;
                            String fName = sData['firstName'] ?? '';
                            String lName = sData['lastName'] ?? '';
                            String tamAd = "$fName $lName".trim();

                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.person,
                                color: Colors.red,
                                size: 18,
                              ),
                              title: Text(
                                tamAd.isEmpty ? "İsimsiz Öğrenci" : tamAd,
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= 3. SEKME: ÖĞRENCİ BAZLI ÖZET =================
  Widget _buildOgrenciBazliOzetSekmesi() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Bu sınıfta öğrenci bulunmuyor."));
        }

        var studentDocs = snapshot.data!.docs;

        studentDocs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          String adA = (dataA['firstName'] ?? '').toString();
          String adB = (dataB['firstName'] ?? '').toString();
          return adA.compareTo(adB);
        });

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('devamsizliklar')
              .get(),
          builder: (context, devamsizlikSnapshot) {
            if (!devamsizlikSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, int> devamsizlikSayilari = {};
            for (var devDoc in devamsizlikSnapshot.data!.docs) {
              var devData = devDoc.data() as Map<String, dynamic>;
              var ogrencilerMap =
                  devData['ogrenciler'] as Map<String, dynamic>? ?? {};
              ogrencilerMap.forEach((sId, isDevamsiz) {
                if (isDevamsiz == true) {
                  devamsizlikSayilari[sId] =
                      (devamsizlikSayilari[sId] ?? 0) + 1;
                }
              });
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: studentDocs.length,
              itemBuilder: (context, index) {
                var studentDoc = studentDocs[index];
                String studentId = studentDoc.id;
                var sData = studentDoc.data() as Map<String, dynamic>;

                String fName = sData['firstName'] ?? '';
                String lName = sData['lastName'] ?? '';
                String tamAd = "$fName $lName".trim();
                if (tamAd.isEmpty) tamAd = 'İsimsiz Öğrenci';

                int toplamYoklama = devamsizlikSayilari[studentId] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: toplamYoklama > 0
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Text(
                        "$toplamYoklama",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: toplamYoklama > 0
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                    title: Text(
                      tamAd,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      toplamYoklama == 0
                          ? "Sorunsuz (0 Gün)"
                          : "$toplamYoklama Gün Gelmedi",
                      style: TextStyle(
                        color: toplamYoklama == 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
