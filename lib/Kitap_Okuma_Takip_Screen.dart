import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_kitap_odev_screen.dart';

class KitapOkumaTakipScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String userRole;

  const KitapOkumaTakipScreen({
    super.key,
    required this.classId,
    required this.className,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<KitapOkumaTakipScreen> createState() => _KitapOkumaTakipScreenState();
}

class _KitapOkumaTakipScreenState extends State<KitapOkumaTakipScreen> {
  bool _siralamayiAc = false;

  Future<List<Map<String, dynamic>>> _getOgrencilerVeVeriler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];

    for (var doc in studentsQuery.docs) {
      var studentData = doc.data();

      // Sadece okunan kitapları ve sayfa sayısını topluyoruz
      var kitaplarQuery = await doc.reference
          .collection('okunan_kitaplar')
          .get();

      int toplamSayfa = 0;
      for (var k in kitaplarQuery.docs) {
        var kData = k.data();
        if (kData.containsKey('sayfaSayisi')) {
          toplamSayfa += (kData['sayfaSayisi'] as num).toInt();
        }
      }

      ogrenciListesi.add({
        'id': doc.id,
        ...studentData,
        'toplamSayfa': toplamSayfa,
      });
    }

    if (_siralamayiAc) {
      ogrenciListesi.sort(
        (a, b) => (b['toplamSayfa'] as int).compareTo(a['toplamSayfa'] as int),
      );
    }

    return ogrenciListesi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Kitap Okuma Takibi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_siralamayiAc ? Icons.star : Icons.sort_by_alpha),
            tooltip: _siralamayiAc ? "Puan Sırası Açık" : "Alfabetik Sıra",
            onPressed: () {
              setState(() {
                _siralamayiAc = !_siralamayiAc;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOgrencilerVeVeriler(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Bu sınıfta henüz kayıtlı öğrenci yok."),
            );
          }

          final students = snapshot.data!;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final firstName = student['firstName'] ?? '';
              final lastName = student['lastName'] ?? '';
              final toplamSayfa = student['toplamSayfa'] ?? 0;

              final initials =
                  (firstName.isNotEmpty ? firstName[0] : '') +
                  (lastName.isNotEmpty ? lastName[0] : '');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentOdevTakipScreen(
                          studentData: student,
                          studentId: student['id'],
                          userRole: widget.userRole,
                          initialTabIndex: 0, // Sadece Kitaplar & Özet
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  leading: _siralamayiAc
                      ? CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                  title: Text(
                    "$firstName $lastName",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // Alt satır sadece sınıf numarası ve toplam sayfayı gösterecek şekilde sadeleştirildi
                  subtitle: Text(
                    "Sınıf No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}  •  Toplam: $toplamSayfa Sayfa",
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.indigo,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
