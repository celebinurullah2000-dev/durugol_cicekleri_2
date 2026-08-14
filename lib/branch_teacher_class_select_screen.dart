// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Ogretmen_Ana_Sayfasi.dart';

class BranchTeacherClassSelectScreen extends StatefulWidget {
  final String
  teacherId; // Kullanıcının (İdareci veya Branş Öğretmeni) Firestore ID'si
  final String teacherName;

  const BranchTeacherClassSelectScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<BranchTeacherClassSelectScreen> createState() =>
      _BranchTeacherClassSelectScreenState();
}

class _BranchTeacherClassSelectScreenState
    extends State<BranchTeacherClassSelectScreen> {
  List<String> _selectedClassIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedClasses();
  }

  Future<void> _loadAssignedClasses() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.teacherId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> assigned = data['assignedClassIds'] ?? [];
        setState(() {
          _selectedClassIds = assigned.map((e) => e.toString()).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Seçimleri kaydet ve ana panele yönlendir
  Future<void> _saveSelections() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.teacherId)
          .update({'assignedClassIds': _selectedClassIds});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sınıf seçimleriniz başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );

      // İŞTE BU KISMI BURAYA YAPIŞTIRIYORSUNUZ:
      // Kullanıcının rolünü (admin mi yoksa branch_teacher mı olduğunu) veritabanından okuyarak veya
      // doğrudan buraya ileterek yönlendirmeyi yapabilirsiniz:

      // Örnek olarak kullanıcının rolünü Firestore'dan çekip dinamik verebiliriz:
      var userDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.teacherId)
          .get();

      String role = userDoc.data()?['userRole'] ?? 'branch_teacher';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OgretmenAnaSayfasi(
            classId: widget.teacherId,
            className: widget.teacherName,
            userRole: role, // 'admin' veya 'branch_teacher'
            assignedClassIds: _selectedClassIds,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kayıt sırasında hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sınıf Seçimi - ${widget.teacherName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Sistemde kayıtlı sınıf bulunamadı."),
                  );
                }

                // Sadece gerçek sınıfları filtreliyoruz (İdarecileri ve Branş Öğretmenlerini listeden çıkarıyoruz)
                var classes = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String userRole = data['userRole'] ?? 'classroom_teacher';

                  // Sadece normal sınıf öğretmenlerinin sınıflarını listele (admin ve branch_teacher olanları ele)
                  return userRole != 'admin' &&
                      userRole != 'branch_teacher' &&
                      doc.id != widget.teacherId;
                }).toList();

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Lütfen takip etmek istediğiniz sınıf ve şubeleri işaretleyip kaydedin.",
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          var classDoc = classes[index];
                          String classId = classDoc.id;
                          var data = classDoc.data() as Map<String, dynamic>;
                          String className = data['className'] ?? 'Sınıf';
                          String teacherName =
                              data['teacherName'] ?? 'Sınıf Öğretmeni';

                          bool isSelected = _selectedClassIds.contains(classId);

                          return CheckboxListTile(
                            title: Text(
                              className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Sınıf Öğretmeni: $teacherName"),
                            value: isSelected,
                            activeColor: Colors.indigo,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedClassIds.add(classId);
                                } else {
                                  _selectedClassIds.remove(classId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saveSelections,
                          child: const Text(
                            "Seçimleri Kaydet ve İlerle",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
