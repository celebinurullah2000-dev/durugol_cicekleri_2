// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class NobetciScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  final bool isTeacher;
  final String
  userRole; // Yeni eklenen rol parametresi ('classroom_teacher', 'branch_teacher', 'admin')

  const NobetciScreen({
    super.key,
    required this.studentId,
    required this.classId,
    this.isTeacher = false,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<NobetciScreen> createState() => _NobetciScreenState();
}

class _NobetciScreenState extends State<NobetciScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _nobetTakviminiAc(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime focusedDay = DateTime.now();
            DateTime? selectedDay = DateTime.now();

            return AlertDialog(
              title: const Text("Nöbet Tutulmayacak Günler"),
              content: SizedBox(
                width: 350,
                height: 420,
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('engellenen_tarihler')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    Set<String> engellenenTarihStrleri = {};
                    if (snapshot.hasData) {
                      engellenenTarihStrleri = snapshot.data!.docs
                          .map((doc) => doc.id)
                          .toSet();
                    }

                    String tarihKeyFormat(DateTime tarih) {
                      return "${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}";
                    }

                    return TableCalendar(
                      firstDay: DateTime(2026, 1, 1),
                      lastDay: DateTime(3000, 12, 31),
                      focusedDay: focusedDay,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      daysOfWeekStyle: DaysOfWeekStyle(
                        dowTextFormatter: (date, locale) {
                          const days = [
                            'Pzt',
                            'Sal',
                            'Çar',
                            'Per',
                            'Cum',
                            'Cmt',
                            'Paz',
                          ];
                          return days[date.weekday - 1];
                        },
                      ),
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
                      selectedDayPredicate: (day) =>
                          isSameDay(selectedDay, day),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          String key = tarihKeyFormat(day);
                          if (engellenenTarihStrleri.contains(key)) {
                            return Container(
                              margin: const EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      onDaySelected: (secilen, odaklanan) async {
                        String tarihStr = tarihKeyFormat(secilen);
                        var ref = FirebaseFirestore.instance
                            .collection('classes')
                            .doc(widget.classId)
                            .collection('engellenen_tarihler')
                            .doc(tarihStr);

                        var doc = await ref.get();
                        if (doc.exists) {
                          await ref.delete();
                        } else {
                          await ref.set({'engellendiMi': true});
                        }

                        setDialogState(() {
                          selectedDay = secilen;
                          focusedDay = odaklanan;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.indigoAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Kapat"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isLoading = true;
  String? _bugunKizNovetciAdi;
  String? _bugunErkekNovetciAdi;
  String? _bugunKizId;
  String? _bugunErkekId;
  bool _isWeekend = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAndAssignDuty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndAssignDuty() async {
    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    if (now.weekday == 6 || now.weekday == 7) {
      setState(() {
        _isWeekend = true;
        _isLoading = false;
      });
      return;
    }

    String dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    DocumentSnapshot engelDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('engellenen_tarihler')
        .doc(dateKey)
        .get();

    if (engelDoc.exists) {
      setState(() {
        _isWeekend = true;
        _isLoading = false;
      });
      return;
    }
    try {
      DocumentSnapshot aktifGorevDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('aktifGorevliler')
          .doc('mevcut')
          .get();

      Set<String> aktifGorevliStudentIds = {};
      if (aktifGorevDoc.exists) {
        var data = aktifGorevDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          var kizMap = data['kiz'] as Map<String, dynamic>?;
          var erkekMap = data['erkek'] as Map<String, dynamic>?;

          if (kizMap != null && kizMap['id'] != null) {
            aktifGorevliStudentIds.add(kizMap['id'].toString());
          }
          if (erkekMap != null && erkekMap['id'] != null) {
            aktifGorevliStudentIds.add(erkekMap['id'].toString());
          }
        }
      }

      DocumentReference dutyDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('duty_records')
          .doc(dateKey);

      DocumentSnapshot dutySnapshot = await dutyDocRef.get();

      if (dutySnapshot.exists) {
        var data = dutySnapshot.data() as Map<String, dynamic>;
        _bugunKizId = data['girlId'];
        _bugunErkekId = data['boyId'];
        _bugunKizNovetciAdi = data['girlName'];
        _bugunErkekNovetciAdi = data['boyName'];
      } else {
        QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .get();

        var students = studentSnapshot.docs;

        var girls = students.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool isGirl = data['gender'] == 'K';
          bool hasActiveDuty = aktifGorevliStudentIds.contains(doc.id);
          bool nobetMusait = data['nobetMusait'] ?? true;
          return isGirl && !hasActiveDuty && nobetMusait;
        }).toList();

        var boys = students.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool isBoy = data['gender'] == 'E';
          bool hasActiveDuty = aktifGorevliStudentIds.contains(doc.id);
          bool nobetMusait = data['nobetMusait'] ?? true;
          return isBoy && !hasActiveDuty && nobetMusait;
        }).toList();

        girls.sort((a, b) {
          var nameA =
              "${(a.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          var nameB =
              "${(b.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          return nameA.compareTo(nameB);
        });

        boys.sort((a, b) {
          var nameA =
              "${(a.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          var nameB =
              "${(b.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          return nameA.compareTo(nameB);
        });

        QueryDocumentSnapshot? nextGirl;
        for (var doc in girls) {
          var data = doc.data() as Map<String, dynamic>;
          if ((data['hasBeenOnDuty'] ?? false) == false) {
            nextGirl = doc;
            break;
          }
        }
        if (nextGirl == null && girls.isNotEmpty) {
          nextGirl = girls.first;
          for (var doc in girls) {
            await FirebaseFirestore.instance
                .collection('students')
                .doc(doc.id)
                .update({'hasBeenOnDuty': false});
          }
        }

        QueryDocumentSnapshot? nextBoy;
        for (var doc in boys) {
          var data = doc.data() as Map<String, dynamic>;
          if ((data['hasBeenOnDuty'] ?? false) == false) {
            nextBoy = doc;
            break;
          }
        }
        if (nextBoy == null && boys.isNotEmpty) {
          nextBoy = boys.first;
          for (var doc in boys) {
            await FirebaseFirestore.instance
                .collection('students')
                .doc(doc.id)
                .update({'hasBeenOnDuty': false});
          }
        }

        if (nextGirl == null || nextBoy == null) {
          setState(() => _isLoading = false);
          return;
        }

        _bugunKizId = nextGirl.id;
        _bugunErkekId = nextBoy.id;

        var girlData = nextGirl.data() as Map<String, dynamic>;
        var boyData = nextBoy.data() as Map<String, dynamic>;

        _bugunKizNovetciAdi =
            "${girlData['firstName']} ${girlData['lastName']}";
        _bugunErkekNovetciAdi =
            "${boyData['firstName']} ${boyData['lastName']}";

        await dutyDocRef.set({
          'date': dateKey,
          'girlId': _bugunKizId,
          'girlName': _bugunKizNovetciAdi,
          'boyId': _bugunErkekId,
          'boyName': _bugunErkekNovetciAdi,
        });

        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunKizId)
            .update({'hasBeenOnDuty': true});
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunErkekId)
            .update({'hasBeenOnDuty': true});
      }
    } catch (e) {
      debugPrint("Nöbet atama hatası: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String bugunTarihStr =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    // Sadece sınıf öğretmeni ise takvim düğmesi görünsün (İdareci ve Branş Öğretmeninde gizlenir)
    bool isSinifOgretmeni = widget.userRole == 'classroom_teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nöbetçi Öğrenci Takibi"),
        actions: [
          if (widget.isTeacher && isSinifOgretmeni)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: "Nöbet Tatil Takvimi",
              onPressed: () {
                _nobetTakviminiAc(context);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Güncel Nöbetçiler & Liste", icon: Icon(Icons.today)),
            Tab(text: "Geçmiş Nöbetler", icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: Güncel Durum ve Alfabetik Liste
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Tarih: $bugunTarihStr",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                        const Divider(height: 20),
                        _isWeekend
                            ? const Text(
                                "Bugün hafta sonu, nöbetçi öğrenci bulunmuyor.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : _isLoading
                            ? const CircularProgressIndicator()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        "Kız Nöbetçi",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bugunKizNovetciAdi ?? "Atanmadı",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const VerticalDivider(),
                                  Column(
                                    children: [
                                      const Text(
                                        "Erkek Nöbetçi",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bugunErkekNovetciAdi ?? "Atanmadı",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ALT KISIM: Tüm Öğrencilerin Alfabetik Listesi
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Sınıf Öğrenci Listesi ve Nöbet Durumları",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(widget.classId)
                                  .collection('aktifGorevliler')
                                  .doc('mevcut')
                                  .get(),
                              builder: (context, gorevSnap) {
                                Set<String> aktifGorevliStudentIds = {};
                                if (gorevSnap.hasData &&
                                    gorevSnap.data!.exists) {
                                  var data =
                                      gorevSnap.data!.data()
                                          as Map<String, dynamic>?;
                                  if (data != null) {
                                    var kizMap =
                                        data['kiz'] as Map<String, dynamic>?;
                                    var erkekMap =
                                        data['erkek'] as Map<String, dynamic>?;

                                    if (kizMap != null &&
                                        kizMap['id'] != null) {
                                      aktifGorevliStudentIds.add(
                                        kizMap['id'].toString(),
                                      );
                                    }
                                    if (erkekMap != null &&
                                        erkekMap['id'] != null) {
                                      aktifGorevliStudentIds.add(
                                        erkekMap['id'].toString(),
                                      );
                                    }
                                  }
                                }

                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('students')
                                      .where(
                                        'classId',
                                        isEqualTo: widget.classId,
                                      )
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        gorevSnap.connectionState ==
                                            ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "Bu sınıfta öğrenci bulunamadı.",
                                        ),
                                      );
                                    }

                                    int turkceKarsilastir(String a, String b) {
                                      const String turkceAlfabe =
                                          'aabcçdefgğhıijklmnoöprsştuüvyz';

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

                                      int minLength =
                                          aKucuk.length < bKucuk.length
                                          ? aKucuk.length
                                          : bKucuk.length;

                                      for (int i = 0; i < minLength; i++) {
                                        int indexA = turkceAlfabe.indexOf(
                                          aKucuk[i],
                                        );
                                        int indexB = turkceAlfabe.indexOf(
                                          bKucuk[i],
                                        );

                                        if (indexA == -1 || indexB == -1) {
                                          int comp = aKucuk
                                              .codeUnitAt(i)
                                              .compareTo(bKucuk.codeUnitAt(i));
                                          if (comp != 0) return comp;
                                        } else if (indexA != indexB) {
                                          return indexA.compareTo(indexB);
                                        }
                                      }

                                      return aKucuk.length.compareTo(
                                        bKucuk.length,
                                      );
                                    }

                                    var students = snapshot.data!.docs;

                                    students.sort((a, b) {
                                      var dataA =
                                          a.data() as Map<String, dynamic>;
                                      var dataB =
                                          b.data() as Map<String, dynamic>;
                                      String nameA =
                                          "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                                      String nameB =
                                          "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
                                      return turkceKarsilastir(nameA, nameB);
                                    });

                                    return ListView.builder(
                                      itemCount: students.length,
                                      itemBuilder: (context, index) {
                                        var studentDoc = students[index];
                                        var studentData =
                                            studentDoc.data()
                                                as Map<String, dynamic>;
                                        String studentId = studentDoc.id;
                                        String adSoyad =
                                            "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";
                                        bool hasBeenOnDuty =
                                            studentData['hasBeenOnDuty'] ??
                                            false;
                                        bool nobetMusait =
                                            studentData['nobetMusait'] ?? true;

                                        bool hasActiveDuty =
                                            aktifGorevliStudentIds.contains(
                                              studentId,
                                            );

                                        Color textColor = Colors.black87;
                                        String durumMetni = "Sıra Bekliyor";

                                        if (hasActiveDuty) {
                                          textColor = Colors.purple.shade700;
                                          durumMetni = "Görevli Öğrenci";
                                        } else if (!nobetMusait) {
                                          textColor = Colors.grey;
                                          durumMetni =
                                              "Nöbet İptal Edildi (Pasif)";
                                        } else if (studentId == _bugunKizId ||
                                            studentId == _bugunErkekId) {
                                          textColor = Colors.green.shade700;
                                          durumMetni = "Bugün Nöbetçi 🟢";
                                        } else if (hasBeenOnDuty) {
                                          textColor = Colors.red.shade300;
                                          durumMetni = "Nöbet Tuttu";
                                        }

                                        return ListTile(
                                          leading: widget.isTeacher
                                              ? Checkbox(
                                                  value: nobetMusait,
                                                  activeColor: Colors.indigo,
                                                  onChanged:
                                                      (bool? yeniDeger) async {
                                                        if (yeniDeger != null) {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'students',
                                                              )
                                                              .doc(studentId)
                                                              .update({
                                                                'nobetMusait':
                                                                    yeniDeger,
                                                              });
                                                        }
                                                      },
                                                )
                                              : CircleAvatar(
                                                  backgroundColor:
                                                      Colors.indigo.shade100,
                                                  child: Text(
                                                    (index + 1).toString(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                          title: Text(
                                            adSoyad,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              decoration: nobetMusait
                                                  ? TextDecoration.none
                                                  : TextDecoration.lineThrough,
                                            ),
                                          ),
                                          subtitle: Text(
                                            durumMetni,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textColor.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontWeight: hasActiveDuty
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SEKME: Geçmiş Nöbetler Arşivi
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('duty_records')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Henüz geçmiş nöbet kaydı bulunmuyor."),
                );
              }

              var records = snapshot.data!.docs;

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var record = records[index].data() as Map<String, dynamic>;
                  String tarih = record['date'] ?? '';
                  String kiz = record['girlName'] ?? '';
                  String erkek = record['boyName'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        "Tarih: $tarih",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Kız: $kiz\nErkek: $erkek"),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
