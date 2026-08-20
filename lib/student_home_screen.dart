// ignore_for_file: use_build_context_synchronously

import 'package:durugol_cicekleri/Ogrenci_Davranis_Screen.dart';
import 'package:durugol_cicekleri/screens/chat_list_screen.dart';
import 'package:durugol_cicekleri/screens/class_feed_screen.dart';
//import 'package:durugol_cicekleri/veli_randevu_screen.dart';
import 'package:flutter/material.dart'; // Scaffold, AppBar, Text vb. temel widgetlar için
import 'package:shared_preferences/shared_preferences.dart'; // Çıkış yaparken oturumu silmek için
import 'login_screen.dart'; // Çıkış yapınca tekrar giriş ekranına dönmek için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'OkudugumKitaplarScreen.dart';
import 'odevlerim_screen.dart';
import 'cesitli_isler_screen.dart';
import 'oyunlar_menu_screen.dart';
import 'Dogum_Gunleri_Screen.dart';
import 'Ogrenci_Denemeler_Screen.dart';
import 'package:lottie/lottie.dart';
import 'istatistik_servisi.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'duyurular_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String studentId;
  const StudentHomeScreen({super.key, required this.studentId});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String studentName = "Öğrenci"; // Başlangıç değeri
  String classId = ""; // Sınıf ID'sini tutmak için değişken
  String className = "Sınıf"; // Sınıf adını tutmak için değişken
  String? ogrenciProfilResmiBase64;

  Future<void> _profilResmiDegistir() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/${widget.studentId}.jpg',
      );

      // Web و Mobil uyumlu yükleme yöntemi:
      if (kIsWeb) {
        // Web için byte olarak oku ve yükle
        var bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        // Mobil (Android / iOS) için dosya olarak yükle
        await ref.putFile(File(image.path));
      }

      // İndirme URL'sini alma
      final String downloadUrl = await ref.getDownloadURL();

      // Firestore'da ilgili öğrenci dokümanını güncelleme
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({'profileImageUrl': downloadUrl});

      // SharedPreferences ve State'i güncelleme
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageUrl_${widget.studentId}', downloadUrl);

      setState(() {
        ogrenciProfilResmiBase64 = downloadUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil resmi başarıyla güncellendi!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resim yüklenirken hata oluştu: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStudentData(); // Hem ismi hem de sınıf ID'sini yüklüyoruz
  }

  void _resmiTamBoyutGoster() {
    if (ogrenciProfilResmiBase64 == null || ogrenciProfilResmiBase64!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ogrenciProfilResmiBase64!, // URL kullanılıyor
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void dogumGunuKontrolEtVeBildir(BuildContext context, String classId) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: classId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String dogumTarihi = data['dogumTarihi'] ?? '';
        int kalanGun = dogumGununeKalanGunHesapla(dogumTarihi);

        // Doğum gününe 3 gün veya daha az kaldıysa (0 gün dahil)
        if (kalanGun >= 0 && kalanGun <= 3) {
          String adSoyad =
              data['adSoyad'] ??
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

          // Bildirimin ard arda patlamaması için veya her açılışta göstermek istiyorsanız:
          if (!context.mounted) return;

          _dogumGunuDialogGoster(context, adSoyad, kalanGun);
          break; // Birden fazla varsa önce yaklaşanı gösterip dönebiliriz
        }
      }
    } catch (e) {
      // Hata yönetimi sessiz geçilebilir
    }
  }

  int dogumGununeKalanGunHesapla(String dogumTarihiStr) {
    try {
      List<String> parcalar = dogumTarihiStr.split('.');
      if (parcalar.length != 3) return 999;
      int gun = int.parse(parcalar[0]);
      int ay = int.parse(parcalar[1]);

      DateTime simdi = DateTime.now();
      DateTime buYilDogumGunu = DateTime(simdi.year, ay, gun);

      if (buYilDogumGunu.isBefore(
        DateTime(simdi.year, simdi.month, simdi.day),
      )) {
        buYilDogumGunu = DateTime(simdi.year + 1, ay, gun);
      }

      return buYilDogumGunu
          .difference(DateTime(simdi.year, simdi.month, simdi.day))
          .inDays;
    } catch (e) {
      return 999;
    }
  }

  void _dogumGunuDialogGoster(
    BuildContext context,
    String ogrenciAdi,
    int kalanGun,
  ) {
    String mesaj = kalanGun == 0
        ? "Bugün $ogrenciAdi adlı arkadaşımızın doğum günü! 🎂 Birlikte nice mutlu yıllara dileyelim! 🎉"
        : "$ogrenciAdi adlı arkadaşımızın doğum gününe $kalanGun gün kaldı! 🎈 Şimdiden hazırlıklara başlayalım! 🎁";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.celebration, color: Colors.pink, size: 30),
            SizedBox(width: 10),
            Text("Doğum Günü Var!"),
          ],
        ),
        content: Text(mesaj, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Harika!"),
          ),
        ],
      ),
    );
  }

  // Öğrenci bilgilerini SharedPreferences ve Firestore'dan yükleme
  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();

    String isim = prefs.getString('studentName') ?? "Öğrenci";
    String cId = prefs.getString('classId') ?? "";

    // Önce telefonda kayıtlı resim URL'si var mı bakalım
    String? yerelResimUrl = prefs.getString(
      'profileImageUrl_${widget.studentId}',
    );

    if (cId.isEmpty || yerelResimUrl == null) {
      // Telefonda yoksa Firestore'dan çekelim
      var studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        var data = studentDoc.data() as Map<String, dynamic>;
        cId = data['classId'] ?? "";
        isim = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        String dbResimUrl = data['profileImageUrl'] ?? "";

        await prefs.setString('classId', cId);
        await prefs.setString('studentName', isim);

        if (dbResimUrl.isNotEmpty) {
          await prefs.setString(
            'profileImageUrl_${widget.studentId}',
            dbResimUrl,
          );
          yerelResimUrl = dbResimUrl;
        }
      }
    }

    if (cId.isNotEmpty) {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(cId)
          .get();
      if (classDoc.exists) {
        var classData = classDoc.data() as Map<String, dynamic>;
        className = classData['className'] ?? "Sınıf";
      }
    }

    setState(() {
      studentName = isim.isNotEmpty ? isim : "Öğrenci";
      classId = cId;
      ogrenciProfilResmiBase64 = yerelResimUrl;

      if (cId.isNotEmpty && mounted) {
        dogumGunuKontrolEtVeBildir(context, cId);
      }
    });

    await IstatistikServisi.islemKaydet(
      studentId: widget.studentId,
      islemTuru: 'giris',
    );
  }

  // Öğrencinin Kendi Şifresini Değiştirme Fonksiyonu
  void _ogrenciSifreDegistir(BuildContext context) {
    final TextEditingController yeniSifreController = TextEditingController();
    final TextEditingController yeniSifreTekrarController =
        TextEditingController();

    bool yeniSifreGizli = true;
    bool yeniSifreTekrarGizli = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Şifremi Değiştir"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Yeni Şifre Kutusu
                TextField(
                  controller: yeniSifreController,
                  obscureText: yeniSifreGizli,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        yeniSifreGizli
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          yeniSifreGizli = !yeniSifreGizli;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 2. Yeni Şifre (Tekrar) Kutusu
                TextField(
                  controller: yeniSifreTekrarController,
                  obscureText: yeniSifreTekrarGizli,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre (Tekrar)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        yeniSifreTekrarGizli
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          yeniSifreTekrarGizli = !yeniSifreTekrarGizli;
                        });
                      },
                    ),
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
              onPressed: () {
                String sifre1 = yeniSifreController.text.trim();
                String sifre2 = yeniSifreTekrarController.text.trim();

                if (sifre1.isEmpty || sifre2.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lütfen tüm alanları doldurun."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (sifre1 != sifre2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Girdiğiniz şifreler birbiriyle uyuşmuyor!",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                FirebaseFirestore.instance
                    .collection('students')
                    .doc(widget.studentId)
                    .update({'password': sifre1});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifreniz başarıyla güncellendi."),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Buton verileri (resim isimleri ve başlıklar)
    final List<Map<String, String>> menuItems = [
      {'title': 'Okuduğum Kitaplar', 'image': 'assets/images/kitaplarim.png'},
      {'title': 'Ödevlerim', 'image': 'assets/images/odevlerim.png'},
      /*{'title': 'Projelerim', 'image': 'assets/images/projelerim.png'},*/
      {'title': 'Davranışlarım', 'image': 'assets/images/davranislarim.png'},
      {'title': 'Denemelerim', 'image': 'assets/images/testlerim.png'},
      /*{'title': 'Kurslarım', 'image': 'assets/images/kurslarim.png'},*/
      {'title': 'Çeşitli İşler', 'image': 'assets/images/cesitli_isler.png'},
      {'title': 'Oyunlar', 'image': 'assets/images/oyunlar.png'},
      {'title': 'Duyurular', 'image': 'assets/images/duyurular.png'},
      //{'title': 'Randevular', 'image': 'assets/images/randevular.png'},
      {'title': 'Sohbet Odaları', 'image': 'assets/images/sohbet.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // --- PROFİL FOTOĞRAFI VE KAMERA İKONU ---
            GestureDetector(
              onTap: () {
                if (ogrenciProfilResmiBase64 != null &&
                    ogrenciProfilResmiBase64!.isNotEmpty) {
                  _resmiTamBoyutGoster();
                } else {
                  _profilResmiDegistir();
                }
              },
              onLongPress: _profilResmiDegistir,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        (ogrenciProfilResmiBase64 != null &&
                            ogrenciProfilResmiBase64!.isNotEmpty)
                        ? NetworkImage(ogrenciProfilResmiBase64!)
                        : null,
                    child:
                        (ogrenciProfilResmiBase64 == null ||
                            ogrenciProfilResmiBase64!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.indigo)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.indigoAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Merhaba, $studentName",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Resmi değiştirmek için basılı tut",
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cake,
              color: Color.fromARGB(255, 247, 151, 183),
              size: 40,
            ),
            tooltip: "Sınıf Doğum Günleri",
            onPressed: () {
              if (classId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DogumGunleriScreen(classId: classId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key, color: Colors.lightBlue, size: 40),
            tooltip: "Şifremi Değiştir",
            onPressed: () => _ogrenciSifreDegistir(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.deepOrange,
              size: 40,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
        child: Column(
          children: [
            // Üst kısım: Menü Kartları (Grid)
            GridView.builder(
              itemCount: menuItems.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio:
                    1.15, // Yazının alta sığması için oran güncellendi
              ),
              itemBuilder: (context, index) {
                String baslik = menuItems[index]['title']!;
                String imagePath = menuItems[index]['image']!;
                bool isOdevlerim = baslik == 'Ödevlerim';

                // Tıklama işlevini yöneten ana widget yapısı
                void tiklamaAksiyonu() async {
                  if (baslik == 'Okuduğum Kitaplar') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'okudugum_kitaplar',
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OkudugumKitaplarScreen(studentId: widget.studentId),
                      ),
                    );
                  } else if (baslik == 'Ödevlerim') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'odevlerim',
                    );

                    if (classId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sınıf bilgisi yükleniyor, lütfen tekrar deneyin.",
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OdevlerimScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (baslik == 'Çeşitli İşler') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'cesitli_isler',
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CesitliIslerScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (baslik == 'Davranışlarım') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'davranislarim',
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OgrenciDavranisScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (baslik == 'Denemelerim') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'denemelerim',
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OgrenciDenemelerScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (baslik == 'Oyunlar') {
                    await IstatistikServisi.islemKaydet(
                      studentId: widget.studentId,
                      islemTuru: 'oyunlar',
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OyunlarMenuScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (baslik == 'Duyurular') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DuyurularScreen(
                          userRole: 'student',
                          currentUserName: studentName,
                          currentUserId: widget
                              .studentId, // <--- EKSİK OLAN PARAMETRE EKLENDİ
                        ),
                      ),
                    );
                  } else if (baslik == 'Sohbet Odaları') {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (bottomSheetContext) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "İletişim Alanı Seçin",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.campaign,
                                color: Colors.pinkAccent,
                                size: 30,
                              ),
                              title: const Text("Sınıf Duvarı"),
                              subtitle: const Text(
                                "Ortak paylaşımlar ve duyurular",
                              ),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                IstatistikServisi.islemKaydet(
                                  studentId: widget.studentId,
                                  islemTuru: 'sinif_duvari',
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassFeedScreen(
                                      currentUserId: widget.studentId,
                                      currentUserName: studentName,
                                      isTeacher: false,
                                      classId: classId,
                                      className: className,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.forum,
                                color: Colors.indigo,
                                size: 30,
                              ),
                              title: const Text("Sohbet Odaları"),
                              subtitle: const Text(
                                "Bireysel ve grup mesajlaşmaları",
                              ),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                IstatistikServisi.islemKaydet(
                                  studentId: widget.studentId,
                                  islemTuru: 'sohbet_odalari',
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatListScreen(
                                      currentUserId: widget.studentId,
                                      classId: classId,
                                      currentUserName: studentName,
                                      isTeacher: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$baslik bölümü yapım aşamasında!"),
                      ),
                    );
                  }
                }

                // Kartın içindeki resmin kartı tam kaplaması için yapı
                Widget kartIcerigi = InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: tiklamaAksiyonu,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain, // Resim kartı tamamen doldurur
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );

                // Kartın kendisi ve hemen altında başlık yazısı
                return Column(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shadowColor: Colors.indigo.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: isOdevlerim && classId.isNotEmpty
                            ? StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('students')
                                    .doc(widget.studentId)
                                    .collection('odevler')
                                    .snapshots(),
                                builder: (context, odevSnap) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(classId)
                                        .collection('sinif_isleri')
                                        .snapshots(),
                                    builder: (context, sinifIsleriSnap) {
                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('students')
                                            .doc(widget.studentId)
                                            .collection('is_verileri')
                                            .snapshots(),
                                        builder: (context, ogrenciVeriSnap) {
                                          int toplamBildirim = 0;

                                          if (odevSnap.hasData) {
                                            for (var doc
                                                in odevSnap.data!.docs) {
                                              var data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              if (data['okundu'] != true) {
                                                toplamBildirim++;
                                              }
                                            }
                                          }

                                          if (sinifIsleriSnap.hasData &&
                                              ogrenciVeriSnap.hasData) {
                                            var tumIsler =
                                                sinifIsleriSnap.data!.docs;
                                            var ogrenciVerileri = {
                                              for (var d
                                                  in ogrenciVeriSnap.data!.docs)
                                                d.id: d.data(),
                                            };

                                            for (var isDoc in tumIsler) {
                                              String isId = isDoc.id;
                                              var veri =
                                                  ogrenciVerileri[isId]
                                                      as Map<String, dynamic>?;
                                              if (veri == null ||
                                                  veri['okundu'] == false) {
                                                toplamBildirim++;
                                              }
                                            }
                                          }

                                          return Stack(
                                            children: [
                                              Positioned.fill(
                                                child: kartIcerigi,
                                              ),
                                              if (toplamBildirim > 0)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(7),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Text(
                                                      "$toplamBildirim",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              )
                            : kartIcerigi,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Yazı artık kartın altında yer alıyor
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Kartların hemen altında ortalanmış Lottie Animasyonu
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Lottie.asset(
                  'assets/animations/Welcome_Animation.json',
                  height: 300,
                  width: 300,
                  fit: BoxFit.contain,
                  repeat: true,
                  reverse: true,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
