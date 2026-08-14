// ignore_for_file: use_build_context_synchronously, camel_case_types

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
            labelText: "Sınıf Şifresini Girin",
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
              title: const Text("Sınıfı Düzenle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      decoration: const InputDecoration(
                        labelText: "Öğretmen Adı Soyadı",
                        border: OutlineInputBorder(),
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

                    String yeniClassName = "$selectedGrade/$selectedBranch";

                    bool? onay = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Onay Verin"),
                        content: Text(
                          "Sınıf bilgileri '$yeniClassName' olarak güncellenecektir. Onaylıyor musunuz?",
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
                            'grade': selectedGrade,
                            'branch': selectedBranch,
                            'teacherName': yeniTeacherName,
                          });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sınıf bilgileri başarıyla güncellendi!",
                          ),
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

  void _sinifSil(BuildContext context, String classId, String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$className Sınıfını Sil"),
        content: const Text(
          "Bu sınıfı ve içerisindeki tüm verileri silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
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
                  content: Text("Sınıf başarıyla silindi."),
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
        title: const Text("Sınıflarım"),
        actions: [
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
            return const Center(child: Text("Henüz sınıf eklenmemiş."));
          }

          var allDocs = snapshot.data!.docs;

          // Sınıfları seviyelerine göre (1, 2, 3, 4) grupluyoruz
          Map<String, List<QueryDocumentSnapshot>> groupedClasses = {
            '1': [],
            '2': [],
            '3': [],
            '4': [],
          };

          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String grade = data['grade'] ?? '1';
            if (groupedClasses.containsKey(grade)) {
              groupedClasses[grade]!.add(doc);
            }
          }

          // Her seviye içindeki şubeleri kendi arasında alfabetik sıralıyoruz
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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: seviyeler.length,
            itemBuilder: (context, index) {
              String gradeVal = seviyeler[index];
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
                  subtitle: Text("${siniflar.length} şube kayıtlı"),
                  children: [
                    if (siniflar.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Bu seviyede henüz sınıf eklenmemiş.",
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
                            subtitle: Text("Öğretmen: $teacherName"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  tooltip: "Sınıfı Düzenle",
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
                                  tooltip: "Sınıfı Sil",
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
  ) {
    TextEditingController passwordInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$className Sınıfı Şifresi"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OgretmenAnaSayfasi(
                      classId: classId,
                      className: className,
                    ),
                  ),
                );
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
