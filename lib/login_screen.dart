// ignore_for_file: dead_code, use_build_context_synchronously

import 'package:durugol_cicekleri/sinif_sec_ekle_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isRoleSelected = false;
  bool _sifreGizli = true;

  String? _selectedGradeLevel; // Seçilen sınıf seviyesi (1, 2, 3, 4)
  String? _selectedBranch; // Seçilen şube harfi (A, B, C, D, E, F, G, H, I, J)
  String? _selectedClassId; // Oluşan veya eşleşen Firestore sınıf ID'si
  String? _savedClassId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _classList = [];

  // İstenen şube listesi (Ç ve Ğ hariç)
  final List<String> _branchList = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
  ];
  final List<String> _gradeLevels = ['1', '2', '3', '4'];

  void _masterSifreSor() {
    TextEditingController masterController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yönetici Girişi"),
        content: TextField(
          controller: masterController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Yönetici Şifrenizi Girin",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (masterController.text.trim() == "19781980") {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', 'teacher');
                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const sinifseceklescreen(isTeacherMaster: true),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hatalı sabit şifre!"),
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

  Future<void> _normalOgretmenGiris() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', 'teacher');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const sinifseceklescreen(isTeacherMaster: false),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkSavedClass();
    _loadClasses();
  }

  Future<void> _checkSavedClass() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedClassId = prefs.getString('savedClassId');
    });
  }

  Future<void> _loadClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      // Sınıfları alfabetik olarak (className değerine göre) sıralama
      List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedDocs = List.from(
        snapshot.docs,
      );
      sortedDocs.sort((a, b) {
        var nameA = (a.data()['className'] ?? '').toString();
        var nameB = (b.data()['className'] ?? '').toString();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _classList = sortedDocs;
      });
    } catch (e) {
      // Hata yönetimi
    }
  }

  // Seçilen sınıf seviyesi ve şubeye göre Firestore'daki sınıfın doküman ID'sini bulur
  void _updateSelectedClassId() {
    if (_selectedGradeLevel != null && _selectedBranch != null) {
      "$_selectedGradeLevel-İ$_selectedBranch" // Projenizdeki isimlendirme formatına göre uyarlanabilir, örn: "1/A" veya doğrudan birleştirme
          .replaceAll(
            'İ',
            '',
          ); // Eğer format farklıysa burayı düzenleyebilirsiniz

      // Alternatif olarak standart adlandırma kontrolü (Örn: "1 A", "1-A" vb. veritabanı yapınıza göre)
      // Burada doğrudan "className" alanının "1 A" veya "1/A" gibi geldiğini varsayarak eşleştiriyoruz:
      try {
        // Kullanıcının seçtiği kombinasyonu içeren sınıfı bulmaya çalışalım (Örn: "1" ve "A" -> "1 A" veya "1-A")
        var matchedDoc = _classList.firstWhere(
          (doc) {
            String cName = (doc.data()['className'] ?? '')
                .toString()
                .replaceAll(' ', '')
                .replaceAll('/', '')
                .replaceAll('-', '');
            String target1 = "$_selectedGradeLevel$_selectedBranch";
            return cName.toUpperCase() == target1.toUpperCase();
          },
          orElse: () => _classList.first,
        ); // Bulamazsa ilkini veya null bırakır

        if (matchedDoc.exists &&
            (_selectedGradeLevel != null && _selectedBranch != null)) {
          // Gerçek eşleşmeyi kontrol et
          for (var doc in _classList) {
            String cName = (doc.data()['className'] ?? '').toString();
            if (cName.contains(_selectedGradeLevel!) &&
                cName.contains(_selectedBranch!)) {
              setState(() {
                _selectedClassId = doc.id;
              });
              return;
            }
          }
        }
      } catch (e) {
        _selectedClassId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: Image.asset(
                  'assets/images/durugol_ilkokulu.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              _buildSinifGorseli(),
              const SizedBox(height: 40),
              if (!_isRoleSelected) ...[
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildRoleButton(
                        "",
                        "assets/images/ogretmen2.png",
                        () => _normalOgretmenGiris(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildRoleButton(
                        "",
                        "assets/images/ogrenci.png",
                        () => setState(() => _isRoleSelected = true),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ] else ...[
                const Text(
                  "Öğrenci Girişi",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),

                if (_savedClassId == null) ...[
                  // Yan yana 2 adet Dropdown (Sınıf Seviyesi ve Şube)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // 1'den 4'e Sınıf Seçimi
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGradeLevel,
                                hint: const Text("Sınıf"),
                                isExpanded: true,
                                items: _gradeLevels.map((level) {
                                  return DropdownMenuItem<String>(
                                    value: level,
                                    child: Text("$level. Sınıf"),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedGradeLevel = val;
                                    _updateSelectedClassId();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // A'dan J'ye Şube Seçimi
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranch,
                                hint: const Text("Şube"),
                                isExpanded: true,
                                items: _branchList.map((branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch,
                                    child: Text("$branch Şubesi"),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBranch = val;
                                    _updateSelectedClassId();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _sifreGizli,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Şifrenizi yazın",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGizli ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _sifreGizli = !_sifreGizli;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                InkWell(
                  onTap: () => _login(context),
                  child: Container(
                    width: 250,
                    height: 100,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/giris_butonu.png'),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () => setState(() {
                    _isRoleSelected = false;
                    _passwordController.clear();
                    _sifreGizli = true;
                  }),
                  child: Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/geri_butonu.png'),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    String title,
    String imagePath,
    VoidCallback onPressed,
  ) {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            onLongPress: () => _masterSifreSor(),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinifGorseli() {
    bool gorseliGoster = false;
    if (!gorseliGoster) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('genel_ayarlar')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Text("Bir hata oluştu");
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Text("Veri bulunamadı");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrl = data['sinif_gorsel_url'] as String?;

        if (imageUrl == null || imageUrl.isEmpty) {
          return const Text("Görsel adresi boş");
        }

        return Image.network(
          imageUrl,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text("HATA: ${error.toString()}");
          },
        );
      },
    );
  }

  Future<void> _login(BuildContext context) async {
    final password = _passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final targetClassId = _savedClassId ?? _selectedClassId;

    if (targetClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen önce sınıf seviyesi ve şube seçiniz!"),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? matchedDoc;
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String dbPassword = (data['password'] ?? '').toString().trim();
        String dbClassId = (data['classId'] ?? '').toString().trim();

        if (dbPassword == password && dbClassId == targetClassId) {
          matchedDoc = doc;
          break;
        }
      }

      if (matchedDoc != null) {
        var studentData = matchedDoc.data();

        await prefs.setString('userRole', 'student');
        await prefs.setString('studentId', matchedDoc.id);
        await prefs.setString('savedClassId', targetClassId);
        await prefs.setString(
          'studentName',
          "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}"
              .trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentHomeScreen(studentId: matchedDoc!.id),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Hatalı Şifre veya Bu Sınıfta Böyle Bir Öğrenci Yok!",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Giriş hatası: $e")));
    }
  }
}
