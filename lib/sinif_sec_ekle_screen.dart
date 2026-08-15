// ignore_for_file: use_build_context_synchronously, camel_case_types

import 'package:durugol_cicekleri/YetkiTanimlaScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_class_screen.dart';
import 'Ogretmen_Ana_Sayfasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class sinifseceklescreen extends StatefulWidget {
  final bool isTeacherMaster;

  const sinifseceklescreen({super.key, this.isTeacherMaster = false});

  @override
  State<sinifseceklescreen> createState() => _sinifseceklescreenState();
}

class _sinifseceklescreenState extends State<sinifseceklescreen> {
  final List<String> _branches = ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'I', 'J'];

  String _capitalizeWords(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  void _sifreDogrulaVaIslemYap(
    BuildContext context,
    String correctPassword,
    String className,
    VoidCallback onAuthorized,
  ) {
    TextEditingController passwordInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$className - Şifre Doğrulama"),
        content: TextField(
          controller: passwordInputController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Şifreyi Girin",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordInputController.text.trim() == correctPassword) {
                Navigator.pop(context);
                onAuthorized();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hatalı şifre! İşlem iptal edildi."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Doğrula"),
          ),
        ],
      ),
    );
  }

  void _sinifDuzenleDialog(
    BuildContext context,
    String classId,
    String mevcutGrade,
    String mevcutBranch,
    String mevcutTeacherName,
    String userRole,
  ) {
    String? selectedGrade = mevcutGrade;
    String? selectedBranch = mevcutBranch;
    final TextEditingController teacherController = TextEditingController(
      text: mevcutTeacherName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                userRole == 'admin' ? "İdareciyi Düzenle" : "Sınıfı Düzenle",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userRole != 'admin') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedGrade,
                        decoration: const InputDecoration(
                          labelText: "Sınıf Seviyesi",
                          border: OutlineInputBorder(),
                        ),
                        items: ['1', '2', '3', '4'].map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text("$grade. Sınıf"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedGrade = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBranch,
                        decoration: const InputDecoration(
                          labelText: "Şube Seçimi",
                          border: OutlineInputBorder(),
                        ),
                        items: _branches.map((branch) {
                          return DropdownMenuItem(
                            value: branch,
                            child: Text("$branch Şubesi"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedBranch = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: teacherController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return TextEditingValue(
                            text: _capitalizeWords(newValue.text),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        labelText: userRole == 'admin'
                            ? "İdareci Adı Soyadı"
                            : "Öğretmen Adı Soyadı",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String yeniTeacherName = teacherController.text.trim();
                    if (yeniTeacherName.isEmpty) return;

                    String yeniClassName = userRole == 'admin'
                        ? "İdareci: $yeniTeacherName"
                        : "$selectedGrade/$selectedBranch";

                    bool? onay = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Onay Verin"),
                        content: Text(
                          "Bilgiler '$yeniClassName' olarak güncellenecektir. Onaylıyor musunuz?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Vazgeç"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Güncelle"),
                          ),
                        ],
                      ),
                    );

                    if (onay == true) {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .update({
                            'className': yeniClassName,
                            'grade': userRole == 'admin' ? '' : selectedGrade,
                            'branch': userRole == 'admin' ? '' : selectedBranch,
                            'teacherName': yeniTeacherName,
                          });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bilgiler başarıyla güncellendi!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sinifSil(BuildContext context, String classId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$itemName Sil"),
        content: const Text(
          "Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .delete();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Kayıt başarıyla silindi."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Girişi"),
        actions: [
          // SÜPER ADMIN (MASTER) İSENİZ GÖRÜNEN "YETKİ TANIMLA" DÜĞMESİ
          if (widget.isTeacherMaster)
            IconButton(
              icon: const Icon(Icons.security, color: Colors.amberAccent),
              tooltip: "Yetki Tanımla",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const YetkiTanimlaScreen()),
                );
              },
            ),

          // Çıkış Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole');

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kayıt eklenmemiş."));
          }

          var allDocs = snapshot.data!.docs;

          Map<String, List<QueryDocumentSnapshot>> groupedClasses = {
            '1': [],
            '2': [],
            '3': [],
            '4': [],
          };
          List<QueryDocumentSnapshot> admins = [];
          List<QueryDocumentSnapshot> branchTeachers = [];
          List<QueryDocumentSnapshot> guidanceTeachers = [];

          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String userRole = data['userRole'] ?? 'classroom_teacher';

            if (userRole == 'admin') {
              admins.add(doc);
            } else if (userRole == 'branch_teacher') {
              branchTeachers.add(doc);
            } else if (userRole == 'guidance_teacher') {
              guidanceTeachers.add(doc);
            } else {
              String grade = data['grade'] ?? '1';
              if (groupedClasses.containsKey(grade)) {
                groupedClasses[grade]!.add(doc);
              }
            }
          }

          for (var gradeKey in groupedClasses.keys) {
            groupedClasses[gradeKey]!.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              return (dataA['className'] ?? '').compareTo(
                dataB['className'] ?? '',
              );
            });
          }

          List<String> seviyeler = ['1', '2', '3', '4'];
          int totalItemCount =
              seviyeler.length +
              (admins.isNotEmpty ? 1 : 0) +
              (branchTeachers.isNotEmpty ? 1 : 0);
          (guidanceTeachers.isNotEmpty ? 1 : 0);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: totalItemCount,
            itemBuilder: (context, index) {
              // 1. İdareciler Kartı
              if (admins.isNotEmpty && index == 0) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.purple,
                      ),
                    ),
                    title: const Text(
                      "Okul İdarecileri ve Yöneticiler",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    subtitle: Text("${admins.length} idareci kayıtlı"),
                    children: admins.map((doc) {
                      var adminData = doc.data() as Map<String, dynamic>;
                      String adminId = doc.id;
                      String adminName = adminData['teacherName'] ?? 'İdareci';
                      String correctPassword = adminData['password'] ?? '';
                      String userRole = adminData['userRole'] ?? 'admin';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                adminName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                " (İdareci)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text("Sistem Yöneticisi"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    adminName,
                                    () {
                                      _sinifDuzenleDialog(
                                        context,
                                        adminId,
                                        '',
                                        '',
                                        adminName,
                                        userRole,
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    adminName,
                                    () {
                                      _sinifSil(context, adminId, adminName);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _sifreDogrulaVeIslemYardimcisi(
                              context,
                              correctPassword,
                              adminName,
                              adminId,
                              userRole,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }

              // 2. Branş Öğretmenleri Kartı
              int branchTeacherCardIndex = admins.isNotEmpty ? 1 : 0;
              if (branchTeachers.isNotEmpty &&
                  index == branchTeacherCardIndex) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: const Icon(Icons.menu_book, color: Colors.orange),
                    ),
                    title: const Text(
                      "Branş Öğretmenleri",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    subtitle: Text(
                      "${branchTeachers.length} branş öğretmeni kayıtlı",
                    ),
                    children: branchTeachers.map((doc) {
                      var teacherData = doc.data() as Map<String, dynamic>;
                      String teacherId = doc.id;
                      String teacherName =
                          teacherData['teacherName'] ?? 'Branş Öğretmeni';
                      String correctPassword = teacherData['password'] ?? '';
                      String userRole =
                          teacherData['userRole'] ?? 'branch_teacher';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                " (Branş Öğretmeni)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text("Branş / Alan Öğretmeni"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    teacherName,
                                    () {
                                      _sinifDuzenleDialog(
                                        context,
                                        teacherId,
                                        '',
                                        '',
                                        teacherName,
                                        userRole,
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    teacherName,
                                    () {
                                      _sinifSil(
                                        context,
                                        teacherId,
                                        teacherName,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _sifreDogrulaVeIslemYardimcisi(
                              context,
                              correctPassword,
                              teacherName,
                              teacherId,
                              userRole,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }

              // 3. Rehber Öğretmenler Kartı
              int guidanceCardIndex =
                  (admins.isNotEmpty ? 1 : 0) +
                  (branchTeachers.isNotEmpty ? 1 : 0);
              if (guidanceTeachers.isNotEmpty && index == guidanceCardIndex) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.teal,
                      ),
                    ),
                    title: const Text(
                      "Rehber Öğretmenler",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal,
                      ),
                    ),
                    subtitle: Text(
                      "${guidanceTeachers.length} rehber öğretmen kayıtlı",
                    ),
                    children: guidanceTeachers.map((doc) {
                      var guidanceData = doc.data() as Map<String, dynamic>;
                      String guidanceId = doc.id;
                      String guidanceName =
                          guidanceData['teacherName'] ?? 'Rehber Öğretmen';
                      String correctPassword = guidanceData['password'] ?? '';
                      String userRole =
                          guidanceData['userRole'] ?? 'guidance_teacher';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                guidanceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                " (Rehber Öğretmen)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text("Rehberlik Servisi"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    guidanceName,
                                    () {
                                      _sinifDuzenleDialog(
                                        context,
                                        guidanceId,
                                        '',
                                        '',
                                        guidanceName,
                                        userRole,
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _sifreDogrulaVaIslemYap(
                                    context,
                                    correctPassword,
                                    guidanceName,
                                    () {
                                      _sinifSil(
                                        context,
                                        guidanceId,
                                        guidanceName,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _sifreDogrulaVeIslemYardimcisi(
                              context,
                              correctPassword,
                              guidanceName,
                              guidanceId,
                              userRole,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }

              // 4. Normal Sınıf Seviyeleri (1, 2, 3, 4)
              int offset =
                  (admins.isNotEmpty ? 1 : 0) +
                  (branchTeachers.isNotEmpty ? 1 : 0) +
                  (guidanceTeachers.isNotEmpty ? 1 : 0);
              int gradeIndex = index - offset;
              String gradeVal = seviyeler[gradeIndex];
              List<QueryDocumentSnapshot> siniflar = groupedClasses[gradeVal]!;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      "$gradeVal.",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  title: Text(
                    "$gradeVal. Sınıflar",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                  subtitle: Text("${siniflar.length} kayıtlı öğe"),
                  children: [
                    if (siniflar.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Bu seviyede henüz kayıt yok.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...siniflar.map((doc) {
                        var classData = doc.data() as Map<String, dynamic>;
                        String classId = doc.id;
                        String className = classData['className'] ?? 'Sınıf';
                        String teacherName =
                            classData['teacherName'] ?? 'Belirtilmemiş';
                        String correctPassword = classData['password'] ?? '';
                        String grade = classData['grade'] ?? '1';
                        String branch = classData['branch'] ?? 'A';
                        String userRole =
                            classData['userRole'] ?? 'classroom_teacher';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Yetkili: $teacherName"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _sifreDogrulaVaIslemYap(
                                      context,
                                      correctPassword,
                                      className,
                                      () {
                                        _sinifDuzenleDialog(
                                          context,
                                          classId,
                                          grade,
                                          branch,
                                          teacherName,
                                          userRole,
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _sifreDogrulaVaIslemYap(
                                      context,
                                      correctPassword,
                                      className,
                                      () {
                                        _sinifSil(context, classId, className);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _sifreDogrulaVeIslemYardimcisi(
                                context,
                                correctPassword,
                                className,
                                classId,
                                userRole,
                              );
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isTeacherMaster
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClassScreen()),
                );
              },
            )
          : null,
    );
  }

  void _sifreDogrulaVeIslemYardimcisi(
    BuildContext context,
    String correctPassword,
    String className,
    String classId,
    String userRole,
  ) {
    TextEditingController passwordInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$className Giriş Şifresi"),
        content: TextField(
          controller: passwordInputController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Şifreyi Girin",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordInputController.text.trim() == correctPassword) {
                Navigator.pop(context);

                if (userRole == 'branch_teacher' ||
                    userRole == 'admin' ||
                    userRole == 'guidance_teacher') {
                  // İdareci ve branş öğretmeni direkt ana sayfaya girer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OgretmenAnaSayfasi(
                        classId: classId,
                        className: className,
                        userRole: userRole,
                        assignedClassIds:
                            [], // İlk girişte boş gelebilir, ana sayfada Firestore'dan okunur
                      ),
                    ),
                  );
                } else {
                  // Klasik Sınıf Öğretmeni
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OgretmenAnaSayfasi(
                        classId: classId,
                        className: className,
                        userRole: userRole,
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hatalı şifre! Lütfen tekrar deneyin."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Giriş Yap"),
          ),
        ],
      ),
    );
  }
}
