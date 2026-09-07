// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_home_screen.dart';
import 'package:lottie/lottie.dart';
import 'ogrenci_yukleme_screen.dart';
import 'sinif_sec_ekle_screen.dart';

// Versiyon kontrolü için gerekli kütüphaneler:
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isRoleSelected = false;
  bool _sifreGizli = true;
  //bool _eulaOnaylandiMi = false;

  String? _selectedGradeLevel;
  String? _selectedBranch;
  String? _selectedClassId;
  String? _savedClassId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _classList = [];

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

  @override
  void initState() {
    super.initState();
    _uygulamaBaslat();
  }

  Future<void> _uygulamaBaslat() async {
    await _anonimGirisYapKontrol(); // 1. Önce kimlik doğrulama tamamlansın

    _checkSavedClass();
    _loadClasses();
    _versiyonKontrolEt();
    _eulaKontrolEt();
  }

  void _eulaDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Kullanım Koşulları ve EULA",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          content: const SizedBox(
            width: double.maxFinite,
            height: 250,
            child: SingleChildScrollView(
              child: Text(
                "Uygulamamızı kullandığınız için teşekkür ederiz.\n\n"
                "1. Bu uygulama içerisindeki Sohbet Odaları ve Sınıf Duvarı gibi alanlarda küfür, hakaret, zorbalık, rahatsız edici veya yasadışı içerik paylaşmak kesinlikle yasaktır.\n"
                "2. Kurallara uymayan kullanıcıların hesapları hiçbir uyarı yapılmaksızın engellenecektir.\n"
                "3. Paylaşılan tüm içeriklerin sorumluluğu kullanıcıya aittir.\n\n"
                "Uygulamayı kullanmaya devam etmek için lütfen Son Kullanıcı Lisans Sözleşmesi'ni (EULA) kabul ediniz.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('eula_accepted', true);

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Kabul Ediyorum"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eulaKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    bool onay = prefs.getBool('eula_accepted') ?? false;

    if (!onay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _eulaDialogGoster();
      });
    }
  }

  Future<void> _anonimGirisYapKontrol() async {
    try {
      // Eğer daha önce bu cihazda anonim oturum açılmadıysa giriş yap
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint("Firebase Anonim Oturum Başarıyla Açıldı.");
      }
    } catch (e) {
      debugPrint("Anonim giriş hatası: $e");
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedClass() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedClassId = prefs.getString('savedClassId');
    });
  }

  // =========================================================================
  // ZORUNLU GÜNCELLEME KONTROLÜ
  // =========================================================================
  Future<void> _versiyonKontrolEt() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int mevcutBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      var doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('version_control')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        var rawMinVersion = data['min_version_code'] ?? 1;
        int minVersionCode = rawMinVersion is int
            ? rawMinVersion
            : int.tryParse(rawMinVersion.toString()) ?? 1;

        String updateUrl = '';
        if (kIsWeb) {
          updateUrl = data['play_store_url'] ?? '';
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          updateUrl = data['play_store_url'] ?? '';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          updateUrl = data['app_store_url'] ?? '';
        }

        if (mevcutBuildNumber < minVersionCode) {
          if (!mounted) return;
          _zorunluGuncellemeDialoguGoster(updateUrl);
        }
      }
    } catch (e) {
      debugPrint("Versiyon kontrol hatası: $e");
    }
  }

  void _zorunluGuncellemeDialoguGoster(String urlStr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Güncelleme Gerekli 🚀"),
          content: const Text(
            "Uygulamaya yeni özellikler eklendi. Hadi güncelleyelim :)",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final Uri url = Uri.parse(urlStr);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text("Hemen Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
  // =========================================================================

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

                // Yöneticiyi online listesine kaydediyoruz
                await FirebaseFirestore.instance
                    .collection('online_users')
                    .doc('master_yonetici')
                    .set({
                      'name': 'Okul Yöneticisi (Master)',
                      'role': 'staff',
                      'sinifSube': '',
                      'lastActive': FieldValue.serverTimestamp(),
                    });

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', 'teacher');
                await prefs.setBool('isMaster', true);
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

  void _yoneticiSifresiIleOgrentiYuklemeyeGit() {
    TextEditingController masterController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Toplu Yükleme Yönetici Girişi"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OgrenciYuklemeScreen(),
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

    // Her oturum için benzersiz bir öğretmen ID'si oluşturup kaydediyoruz

    await prefs.setString('userRole', 'teacher');
    await prefs.setBool('isMaster', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const sinifseceklescreen(isTeacherMaster: false),
      ),
    );
  }

  Future<void> _loadClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

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

  void _updateSelectedClassId() {
    if (_selectedGradeLevel != null && _selectedBranch != null) {
      try {
        var matchedDoc = _classList.firstWhere((doc) {
          String cName = (doc.data()['className'] ?? '')
              .toString()
              .replaceAll(' ', '')
              .replaceAll('/', '')
              .replaceAll('-', '');
          String target1 = "$_selectedGradeLevel$_selectedBranch";
          return cName.toUpperCase() == target1.toUpperCase();
        }, orElse: () => _classList.first);

        if (matchedDoc.exists &&
            (_selectedGradeLevel != null && _selectedBranch != null)) {
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
    final ekranGenisligi = MediaQuery.of(context).size.width;

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
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Image.asset(
                        'assets/images/durugol_ilkokulu.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 200,
                          minHeight: 120,
                          maxHeight: 200,
                        ),
                        child: SizedBox(
                          width: ekranGenisligi * 0.35,
                          height: ekranGenisligi * 0.35,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Lottie.asset(
                                'assets/animations/logo_motion.json',
                                fit: BoxFit.cover,
                                repeat: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSinifGorseli(),
                    const SizedBox(height: 20),
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
                              "assets/images/veli.png",
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
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
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
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
                                _sifreGizli
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
                              image: AssetImage(
                                'assets/images/giris_butonu.png',
                              ),
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
                              image: AssetImage(
                                'assets/images/geri_butonu.png',
                              ),
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
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.cloud_upload,
                    color: Colors.indigo,
                    size: 28,
                  ),
                  onPressed: () => _yoneticiSifresiIleOgrentiYuklemeyeGit(),
                  tooltip: "Toplu Öğrenci Yükle",
                ),
              ),
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
    /*return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('genel_ayarlar')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrl = data['sinif_gorsel_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          return const SizedBox.shrink();
        }
        return Image.network(imageUrl, height: 100, fit: BoxFit.contain);
      },
    );*/ //DEAD CODE
  }

  Future<void> _login(BuildContext context) async {
    final password = _passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    // Önce hafızadaki veya seçilen ID'ye bakalım
    String? targetClassId = _savedClassId ?? _selectedClassId;

    // EMNİYET KİRİŞİ: Eğer _selectedClassId henüz dolmadıysa ama kullanıcı sınıf ve şube seçtiyse,
    // anlık olarak Firestore'dan o sınıfın ID'sini doğrudan buluyoruz:
    if (targetClassId == null &&
        _selectedGradeLevel != null &&
        _selectedBranch != null) {
      try {
        var snapshot = await FirebaseFirestore.instance
            .collection('classes')
            .get();
        for (var doc in snapshot.docs) {
          String cName = (doc.data()['className'] ?? '').toString();
          String grade = (doc.data()['grade'] ?? '').toString();
          String branch = (doc.data()['branch'] ?? '').toString();

          // Sınıf ve şube eşleşmesini yakala
          if ((grade == _selectedGradeLevel && branch == _selectedBranch) ||
              (cName.contains(_selectedGradeLevel!) &&
                  cName.contains(_selectedBranch!))) {
            targetClassId = doc.id;
            break;
          }
        }
      } catch (e) {
        debugPrint("Sınıf arama hatası: $e");
      }
    }

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
        String fullName =
            "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}"
                .trim();

        var classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(targetClassId)
            .get();
        String sinifSubeAdi = classDoc.exists
            ? (classDoc.data()?['className'] ?? '')
            : '';

        await FirebaseFirestore.instance
            .collection('online_users')
            .doc(matchedDoc.id)
            .set({
              'name': fullName,
              'role': 'student',
              'sinifSube': sinifSubeAdi,
              'lastActive': Timestamp.now(),
            });

        await prefs.setString('userRole', 'student');
        await prefs.setString('studentId', matchedDoc.id);
        await prefs.setString('savedClassId', targetClassId);
        await prefs.setString('studentName', fullName);

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
