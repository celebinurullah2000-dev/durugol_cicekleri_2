// ignore_for_file: avoid_types_as_parameter_names, use_build_context_synchronously, camel_case_types

import 'dart:math';
import 'package:durugol_cicekleri/YetkiTanimlaScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_class_screen.dart';
import 'Ogretmen_Ana_Sayfasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'online_kullanicilar_screen.dart'; // Online kullanıcılar ekranının importu

class sinifseceklescreen extends StatefulWidget {
  final bool isTeacherMaster;

  const sinifseceklescreen({super.key, this.isTeacherMaster = false});

  @override
  State<sinifseceklescreen> createState() => _sinifseceklescreenState();
}

class _sinifseceklescreenState extends State<sinifseceklescreen> {
  final List<String> _branches = ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'I', 'J'];

  final List<String> _ataturkSozleri = [
    "Eğitimdir ki bir milleti; ya özgür, bağımsız, şanlı, yüksek bir topluluk halinde yaşatır; ya da esaret ve sefalete terk eder.",
    "Dünyada her şey için, medeniyet için, hayat için, başarı için en hakiki mürşit ilimdir, fendir.",
    "Milletleri kurtaranlar yalnız ve ancak öğretmenlerdir.",
    "Eğitim kültürünü doğrudan doğruya halka yaymak, halkı aydınlatmak en büyük görevimizdir.",
    "Öğretmenler! Yeni nesil sizin eseriniz olacaktır.",
    "Hayatta en hakiki mürşit ilimdir.",
    "Umutsuz durumlar yoktur, umutsuz insanlar vardır. Ben hiçbir zaman umudumu yitirmedim.",
    "Gençler! Cesaretimizi takviye eden ve idame eden sizsiniz.",
  ];

  late String _secilenSoz;

  @override
  void initState() {
    super.initState();
    _rastgeleSozSec();
  }

  void _rastgeleSozSec() {
    final random = Random();
    setState(() {
      _secilenSoz = _ataturkSozleri[random.nextInt(_ataturkSozleri.length)];
    });
  }

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

    String baslikMetni = "Sınıfı Düzenle";
    if (userRole == 'admin') baslikMetni = "İdareciyi Düzenle";
    if (userRole == 'guidance_teacher') {
      baslikMetni = "Rehber Öğretmeni Düzenle";
    }
    if (userRole == 'special_education_teacher') {
      baslikMetni = "Özel Eğitim Öğretmenini Düzenle";
    }
    if (userRole == 'kindergarten_teacher') {
      baslikMetni = "Ana Sınıfı Öğretmenini Düzenle";
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(baslikMetni),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userRole != 'admin' &&
                        userRole != 'guidance_teacher' &&
                        userRole != 'special_education_teacher' &&
                        userRole != 'kindergarten_teacher') ...[
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
                      decoration: const InputDecoration(
                        labelText: "Adı Soyadı",
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

                    String yeniClassName = userRole == 'admin'
                        ? "İdareci: $yeniTeacherName"
                        : (userRole == 'guidance_teacher'
                              ? "Rehber Öğretmen: $yeniTeacherName"
                              : userRole == 'special_education_teacher'
                              ? "Özel Eğitim: $yeniTeacherName"
                              : userRole == 'kindergarten_teacher'
                              ? "Ana Sınıfı: $yeniTeacherName"
                              : "$selectedGrade/$selectedBranch");

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
          // Sadece Master kullanıcı giriş yaptıysa "Online Kullanıcılar" butonu görünür
          if (widget.isTeacherMaster)
            IconButton(
              icon: const Icon(Icons.supervised_user_circle, size: 28),
              tooltip: "Online Kullanıcıları Gör",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlineKullanicilarScreen(),
                  ),
                );
              },
            ),
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
          List<QueryDocumentSnapshot> specialEducationTeachers = [];
          List<QueryDocumentSnapshot> kindergartenTeachers = [];

          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String userRole = data['userRole'] ?? 'classroom_teacher';

            if (userRole == 'admin') {
              admins.add(doc);
            } else if (userRole == 'guidance_teacher') {
              guidanceTeachers.add(doc);
            } else if (userRole == 'branch_teacher' ||
                userRole == 'english_teacher' ||
                userRole == 'religious_teacher') {
              branchTeachers.add(doc);
            } else if (userRole == 'special_education_teacher') {
              specialEducationTeachers.add(doc);
            } else if (userRole == 'kindergarten_teacher') {
              kindergartenTeachers.add(doc);
            } else {
              String grade = data['grade'] ?? '1';
              if (groupedClasses.containsKey(grade)) {
                groupedClasses[grade]!.add(doc);
              }
            }
          }

          // Sıralama fonksiyonları
          admins.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String isimA = dataA['teacherName'] ?? '';
            String isimB = dataB['teacherName'] ?? '';
            return isimA.toLowerCase().compareTo(isimB.toLowerCase());
          });

          guidanceTeachers.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String isimA = dataA['teacherName'] ?? '';
            String isimB = dataB['teacherName'] ?? '';
            return isimA.toLowerCase().compareTo(isimB.toLowerCase());
          });

          branchTeachers.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String isimA = dataA['teacherName'] ?? '';
            String isimB = dataB['teacherName'] ?? '';
            return isimA.toLowerCase().compareTo(isimB.toLowerCase());
          });

          specialEducationTeachers.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String isimA = dataA['teacherName'] ?? '';
            String isimB = dataB['teacherName'] ?? '';
            return isimA.toLowerCase().compareTo(isimB.toLowerCase());
          });

          kindergartenTeachers.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            String isimA = dataA['teacherName'] ?? '';
            String isimB = dataB['teacherName'] ?? '';
            return isimA.toLowerCase().compareTo(isimB.toLowerCase());
          });

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

          int adminCount = admins.isNotEmpty ? 1 : 0;
          int guidanceCount = guidanceTeachers.isNotEmpty ? 1 : 0;
          int branchCount = branchTeachers.isNotEmpty ? 1 : 0;
          int specialEduCount = specialEducationTeachers.isNotEmpty ? 1 : 0;
          int kindergartenCount = kindergartenTeachers.isNotEmpty ? 1 : 0;
          int classTeachersCardCount = 1;

          int totalItemCount =
              adminCount +
              guidanceCount +
              branchCount +
              specialEduCount +
              kindergartenCount +
              classTeachersCardCount +
              1; // Lottie

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: totalItemCount,
            itemBuilder: (context, index) {
              // 1. İdareciler Kartı
              if (admins.isNotEmpty && index == 0) {
                return _buildKartWidget(
                  context,
                  baslik: "Okul İdarecileri ve Yöneticiler",
                  ikon: Icons.admin_panel_settings,
                  renk: Colors.purple,
                  belgeListesi: admins,
                  altAciklama: "${admins.length} idareci kayıtlı",
                );
              }

              // 2. Rehber Öğretmenler Kartı
              int guidanceIndex = adminCount;
              if (guidanceTeachers.isNotEmpty && index == guidanceIndex) {
                return _buildKartWidget(
                  context,
                  baslik: "Rehber Öğretmenler",
                  ikon: Icons.support_agent,
                  renk: Colors.teal,
                  belgeListesi: guidanceTeachers,
                  altAciklama:
                      "${guidanceTeachers.length} rehber öğretmen kayıtlı",
                );
              }

              // 3. Branş Öğretmenleri Kartı
              int branchIndex = adminCount + guidanceCount;
              if (branchTeachers.isNotEmpty && index == branchIndex) {
                return _buildKartWidget(
                  context,
                  baslik: "Branş Öğretmenleri",
                  ikon: Icons.menu_book,
                  renk: Colors.orange,
                  belgeListesi: branchTeachers,
                  altAciklama:
                      "${branchTeachers.length} branş öğretmeni kayıtlı",
                );
              }

              // 4. Özel Eğitim Kartı
              int specialEduIndex = adminCount + guidanceCount + branchCount;
              if (specialEducationTeachers.isNotEmpty &&
                  index == specialEduIndex) {
                return _buildKartWidget(
                  context,
                  baslik: "Özel Eğitim",
                  ikon: Icons.accessibility_new,
                  renk: Colors.brown,
                  belgeListesi: specialEducationTeachers,
                  altAciklama:
                      "${specialEducationTeachers.length} özel eğitim kaydı var",
                );
              }

              // 5. Ana Sınıf Kartı
              int kindergartenIndex =
                  adminCount + guidanceCount + branchCount + specialEduCount;
              if (kindergartenTeachers.isNotEmpty &&
                  index == kindergartenIndex) {
                return _buildKartWidget(
                  context,
                  baslik: "Ana Sınıfı",
                  ikon: Icons.child_care,
                  renk: Colors.pink,
                  belgeListesi: kindergartenTeachers,
                  altAciklama:
                      "${kindergartenTeachers.length} ana sınıfı kaydı var",
                );
              }

              // 6. Sınıf Öğretmenleri Ana Kartı
              int classTeachersCardIndex =
                  adminCount +
                  guidanceCount +
                  branchCount +
                  specialEduCount +
                  kindergartenCount;
              if (index == classTeachersCardIndex) {
                int toplamSinifSayisi = groupedClasses.values.fold(
                  0,
                  (sum, list) => sum + list.length,
                );

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
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.school, color: Colors.indigo),
                    ),
                    title: const Text(
                      "Sınıf Öğretmenleri",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Text("$toplamSinifSayisi sınıf kayıtlı"),
                    children: seviyeler.map((gradeVal) {
                      List<QueryDocumentSnapshot> siniflar =
                          groupedClasses[gradeVal] ?? [];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade100),
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
                              fontSize: 15,
                              color: Colors.indigo,
                            ),
                          ),
                          subtitle: Text("${siniflar.length} şube kayıtlı"),
                          children: [
                            if (siniflar.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  "Bu seviyede henüz kayıt yok.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ...siniflar.map((doc) {
                                var classData =
                                    doc.data() as Map<String, dynamic>;
                                String classId = doc.id;
                                String className =
                                    classData['className'] ?? 'Sınıf';
                                String teacherName =
                                    classData['teacherName'] ?? 'Belirtilmemiş';
                                String correctPassword =
                                    classData['password'] ?? '';
                                String grade = classData['grade'] ?? '1';
                                String branch = classData['branch'] ?? 'A';
                                String userRole =
                                    classData['userRole'] ??
                                    'classroom_teacher';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      className,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text("Yetkili: $teacherName"),
                                    trailing: widget.isTeacherMaster
                                        ? Row(
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
                                                      _sinifSil(
                                                        context,
                                                        classId,
                                                        className,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        : null,
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
                            const SizedBox(height: 6),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }

              // 7. Atatürk Sözü ve Lottie
              if (index == totalItemCount - 1) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(4, 12, 4, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mustafa Kemal Atatürk",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\"$_secilenSoz\"",
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.refresh,
                                size: 20,
                                color: Colors.indigo,
                              ),
                              tooltip: "Başka Söz Getir",
                              onPressed: _rastgeleSozSec,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey.shade50,
                              child: Lottie.asset(
                                'assets/animations/ata_animasyon.json',
                                fit: BoxFit.cover,
                                repeat: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 30,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
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

  Widget _buildKartWidget(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required List<QueryDocumentSnapshot> belgeListesi,
    required String altAciklama,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: renk.withValues(alpha: 0.1),
          child: Icon(ikon, color: renk),
        ),
        title: Text(
          baslik,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: renk,
          ),
        ),
        subtitle: Text(altAciklama),
        children: belgeListesi.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String itemId = doc.id;
          String itemName = data['teacherName'] ?? 'Kayıt';
          String correctPassword = data['password'] ?? '';
          String userRole = data['userRole'] ?? '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: renk.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              title: Text(
                itemName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                baslik,
                style: TextStyle(
                  fontSize: 12,
                  color: renk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: widget.isTeacherMaster
                  ? Row(
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
                              itemName,
                              () {
                                _sinifDuzenleDialog(
                                  context,
                                  itemId,
                                  '',
                                  '',
                                  itemName,
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
                              itemName,
                              () {
                                _sinifSil(context, itemId, itemName);
                              },
                            );
                          },
                        ),
                      ],
                    )
                  : null,
              onTap: () {
                _sifreDogrulaVeIslemYardimcisi(
                  context,
                  correctPassword,
                  itemName,
                  itemId,
                  userRole,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _sifreDogrulaVeIslemYardimcisi(
    BuildContext context,
    String correctPassword,
    String className,
    String classId,
    String userRole,
  ) async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .get();

    List<String> assignedClasses = [];
    if (docSnapshot.exists && docSnapshot.data() != null) {
      var data = docSnapshot.data() as Map<String, dynamic>;
      assignedClasses = List<String>.from(data['assignedClassIds'] ?? []);
    }

    if (!context.mounted) return;

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

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OgretmenAnaSayfasi(
                      classId: classId,
                      className: className,
                      userRole: userRole,
                      assignedClassIds: assignedClasses,
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
