// ignore_for_file: use_build_context_synchronously

import 'package:durugol_cicekleri/Etkinlikler_Screen.dart';
import 'package:durugol_cicekleri/Sinif_Istatistik_Siralama_Screen.dart';
import 'package:durugol_cicekleri/ogretmen_randevu_screen.dart';
import 'package:durugol_cicekleri/screens/class_feed_screen.dart';
import 'package:durugol_cicekleri/screens/teacher_chat_audit_screen.dart';
import 'package:durugol_cicekleri/sinif_sifreleri_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Kisisel_Sozluk_Screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_screen.dart';
import 'TopluOdevScreen.dart';
import 'TarihBazliOdevYoneticisiScreen.dart';
import 'SinifIsTakipScreen.dart';
import 'nobetci_screen.dart';
import 'kitap_okuma_takip_screen.dart';
import 'student_detail_screen.dart';
import 'oturma_duzeni_screen.dart';
import 'Devamsizlik_Screen.dart';
import 'Sinif_Gorevleri_Screen.dart';
import 'Dogum_Gunleri_Screen.dart';
import 'Haftalik_Ders_Programi_Screen.dart';
import 'Kisisel_Deyimler_Screen.dart';
import 'Kisisel_Atasozleri_Screen.dart';
import 'Yarismalar_Screen.dart';
import 'Denemeler_Screen.dart';
import 'Ogretmen_Davranis_Screen.dart';
import 'etutler_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

Future<Map<String, dynamic>> ogrenciDevamsizlikRaporunuGetir(
  String classId,
  String studentId,
) async {
  var snapshot = await FirebaseFirestore.instance
      .collection('classes')
      .doc(classId)
      .collection('devamsizliklar')
      .get();

  int toplamDevamsizlik = 0;
  List<String> gelmedigiTarihler = [];

  for (var doc in snapshot.docs) {
    var data = doc.data();
    var ogrencilerMap = data['ogrenciler'] as Map<String, dynamic>?;

    if (ogrencilerMap != null && ogrencilerMap[studentId] == true) {
      toplamDevamsizlik++;
      gelmedigiTarihler.add(data['tarih'] ?? doc.id);
    }
  }

  gelmedigiTarihler.sort();

  return {'toplam': toplamDevamsizlik, 'tarihler': gelmedigiTarihler};
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void bildirimleriBaslat() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> bildirimGoster(String baslik, String aciklama) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'randevu_kanal_id',
        'Randevu Bildirimleri',
        channelDescription: 'Yeni randevu alındığında bilgilendirir',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    baslik,
    aciklama,
    platformChannelSpecifics,
  );
}

class OgretmenAnaSayfasi extends StatefulWidget {
  final String classId;
  final String className;
  final String userRole; // Rol ('classroom_teacher', 'branch_teacher', 'admin')
  final List<String> assignedClassIds; // Seçilen/Atanan sınıf ID'leri

  const OgretmenAnaSayfasi({
    super.key,
    required this.classId,
    required this.className,
    this.userRole = 'classroom_teacher',
    this.assignedClassIds = const [],
  });

  @override
  State<OgretmenAnaSayfasi> createState() => _OgretmenAnaSayfasiState();
}

class _OgretmenAnaSayfasiState extends State<OgretmenAnaSayfasi> {
  StreamSubscription<QuerySnapshot>? _randevuSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  // Filtreleme için durum değişkenleri (İdareci ve Branş Öğretmenleri için)
  String? _filtreliGrade = '1';
  String? _filtreliBranch = 'A';
  final List<String> _branchListesi = [
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

  Future<String?> _getAktifHedefClassId() async {
    if (widget.userRole == 'classroom_teacher') {
      return widget.classId;
    }

    String arananClassName = "$_filtreliGrade/$_filtreliBranch";
    var classQuery = await FirebaseFirestore.instance
        .collection('classes')
        .where('className', isEqualTo: arananClassName)
        .get();

    if (classQuery.docs.isNotEmpty) {
      return classQuery.docs.first.id;
    }
    return widget.classId;
  }

  // Yetkilendirme için değişkenler
  List<String> _izinliButonlar = [];
  bool _yetkilerYukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kullaniciYetkileriniGetir();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dogumGunuKontrolEtVeBildir(context, widget.classId);
      ogretmenBildirimTokeniniKaydet(widget.classId);
    });
    bildirimleriBaslat();
    _randevuDinle();
  }

  Future<void> _kullaniciYetkileriniGetir() async {
    // Sınıf öğretmenleri tüm butonları görür
    if (widget.userRole == 'classroom_teacher') {
      setState(() {
        _yetkilerYukleniyor = false;
      });
      return;
    }

    try {
      var doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('role_permissions')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> izinler = data[widget.userRole] ?? [];
        setState(() {
          _izinliButonlar = izinler.map((e) => e.toString()).toList();
          _yetkilerYukleniyor = false;
        });
      } else {
        setState(() {
          _yetkilerYukleniyor = false;
        });
      }
    } catch (e) {
      setState(() {
        _yetkilerYukleniyor = false;
      });
    }
  }

  void _randevuDinle() {
    _randevuSubscription = FirebaseFirestore.instance
        .collection('randevular')
        .where('classId', isEqualTo: widget.classId)
        .where('durum', isEqualTo: 'aktif')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data() as Map<String, dynamic>;
              String ogrenciAdi = data['ogrenciAdi'] ?? 'Bir öğrenci';
              String tarih = data['tarih'] ?? '';
              String saat = data['saat'] ?? '';

              bildirimGoster(
                "Yeni Randevu Alındı! 📌",
                "$ogrenciAdi, $tarih tarihinde saat $saat için randevu aldı.",
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _randevuSubscription?.cancel();
    super.dispose();
  }

  Future<void> ogretmenBildirimTokeniniKaydet(String classId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('teacher_tokens')
            .doc(classId)
            .set({
              'token': token,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
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

        if (kalanGun >= 0 && kalanGun <= 3) {
          String adSoyad =
              data['adSoyad'] ??
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

          if (!context.mounted) return;

          _dogumGunuDialogGoster(context, adSoyad, kalanGun);
          break;
        }
      }
    } catch (e) {
      // Hata yönetimi
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
        : "$ogrenciAdi adlı arkadaşımızın doğum gününe $kalanGun kaldı! 🎈 Şimdiden hazırlıklara başlayalım! 🎁";

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

  // --- ŞİFRE DEĞİŞTİRME DİYALOĞU ---
  void _sifreDegistirDialogGoster(BuildContext context) {
    final TextEditingController mevcutSifreController = TextEditingController();
    final TextEditingController yeniSifreController = TextEditingController();
    final TextEditingController yeniSifreTekrarController =
        TextEditingController();

    final String aktifSinifId = widget.classId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Şifreyi Değiştir"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Lütfen mevcut şifrenizi ve yeni şifrenizi giriniz.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: mevcutSifreController,
                decoration: const InputDecoration(
                  labelText: "Mevcut Şifre",
                  border: OutlineInputBorder(),
                ),
                obscureText: false,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yeniSifreController,
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre",
                  border: OutlineInputBorder(),
                ),
                obscureText: false,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yeniSifreTekrarController,
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre (Tekrar)",
                  border: OutlineInputBorder(),
                ),
                obscureText: false,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String mevcutSifre = mevcutSifreController.text.trim();
              String yeniSifre = yeniSifreController.text.trim();
              String yeniSifreTekrar = yeniSifreTekrarController.text.trim();

              if (mevcutSifre.isEmpty ||
                  yeniSifre.isEmpty ||
                  yeniSifreTekrar.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Lütfen tüm alanları doldurun!"),
                  ),
                );
                return;
              }

              if (yeniSifre != yeniSifreTekrar) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Yeni şifreler birbiriyle uyuşmuyor!"),
                  ),
                );
                return;
              }

              try {
                var classDoc = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(aktifSinifId)
                    .get();

                if (!classDoc.exists) return;

                String veritabanindakiSifre =
                    classDoc.data()?['password'] ?? '';

                if (veritabanindakiSifre != mevcutSifre) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mevcut şifrenizi yanlış girdiniz!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(aktifSinifId)
                    .update({'password': yeniSifre});

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifreniz başarıyla güncellendi!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Hata oluştu: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  void _sil(BuildContext context, String studentId) {
    FirebaseFirestore.instance.collection('students').doc(studentId).delete();
    setState(() {});
  }

  void _showSozlukSecenekleri(BuildContext context) async {
    String? hedefClassId = await _getAktifHedefClassId();
    if (hedefClassId == null) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sözlük ve Dil Araçları",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.library_books,
                  color: Colors.deepOrange,
                ),
                title: const Text("1: Sözlük"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KisiselSozlukScreen(
                        classId: hedefClassId,
                        isTeacher: true,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_edu, color: Colors.teal),
                title: const Text("2: Atasözleri"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KisiselAtasozleriScreen(
                        classId: hedefClassId,
                        isTeacher: true,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.auto_stories,
                  color: Colors.deepOrange,
                ),
                title: const Text("3: Deyimler"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KisiselDeyimlerScreen(
                        classId: hedefClassId,
                        isTeacher: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNobetciVeGorevliSecenekleri(BuildContext context) async {
    String? hedefClassId = await _getAktifHedefClassId();
    if (hedefClassId == null) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nöbetçi & Görevli İşlemleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.assignment_ind,
                  color: Colors.green.shade700,
                ),
                title: const Text("Nöbetçi Öğrenci"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NobetciScreen(
                        studentId: "",
                        classId: hedefClassId,
                        isTeacher: true,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.how_to_vote, color: Colors.indigo),
                title: const Text("Sınıf Görevlileri (Seçim & Takip)"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SinifGorevleriScreen(
                        classId: hedefClassId,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOdevIslemleriSecenekleri(BuildContext context) async {
    String? hedefClassId = await _getAktifHedefClassId();
    if (hedefClassId == null) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ödev İşlemleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.date_range, color: Colors.indigo),
                  title: const Text("Hızlı Ödev Durumu Ekle"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TarihBazliOdevYoneticisiScreen(
                          classId: hedefClassId,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.checklist_rtl, color: Colors.blue),
                  title: const Text("Toplu Ödev"),
                  onTap: () async {
                    String? currentHedefClassId = await _getAktifHedefClassId();
                    if (currentHedefClassId == null) return;

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopluOdevScreen(
                          classId: currentHedefClassId,
                          userRole: widget.userRole,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(
                    Icons.assignment_add,
                    color: Colors.orange.shade800,
                  ),
                  title: const Text("Ödev Ver"),
                  onTap: () {
                    Navigator.pop(context);
                    _odevVerDialog(context, hedefClassId);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _duzenle(
    BuildContext context,
    String studentId,
    Map<String, dynamic> studentData,
  ) {
    final TextEditingController adController = TextEditingController(
      text: studentData['firstName'],
    );
    final TextEditingController soyadController = TextEditingController(
      text: studentData['lastName'],
    );
    final TextEditingController sifreController = TextEditingController(
      text: studentData['password'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Öğrenci Bilgilerini Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: const InputDecoration(labelText: "Ad"),
              ),
              TextField(
                controller: soyadController,
                decoration: const InputDecoration(labelText: "Soyad"),
              ),
              TextField(
                controller: sifreController,
                decoration: const InputDecoration(labelText: "Yeni Şifre"),
                obscureText: false,
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
              FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .update({
                    'firstName': adController.text,
                    'lastName': soyadController.text,
                    'password': sifreController.text,
                  });
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bilgiler başarıyla güncellendi."),
                ),
              );
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  void _odevVerDialog(BuildContext context, String hedefClassId) {
    DateTime secilenTarih = DateTime.now();

    final List<String> aylar = [
      '',
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

    final List<String> gunler = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    String tarihFormatla(DateTime tarih) {
      String gunAdi = gunler[tarih.weekday - 1];
      String ayAdi = aylar[tarih.month];
      return "${tarih.day} $ayAdi ${tarih.year}, $gunAdi";
    }

    final TextEditingController tarihStrController = TextEditingController(
      text: tarihFormatla(secilenTarih),
    );

    final TextEditingController kitapAdiController = TextEditingController();
    final TextEditingController sayfaController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sınıfa Ödev Ver"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tarihStrController,
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: secilenTarih,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Colors.indigo,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    secilenTarih = picked;
                    tarihStrController.text = tarihFormatla(picked);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Ödev Tarihi",
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kitapAdiController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: "Kitap Adı"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sayfaController,
                decoration: const InputDecoration(
                  labelText: "Sayfa Aralığı (Örn: 10-15)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: aciklamaController,
                decoration: const InputDecoration(
                  labelText: "Bu Kitap İçin Açıklama / Yönerge",
                ),
                maxLines: 2,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String secilenTarihStr = tarihStrController.text.trim();
              String kitapAdi = kitapAdiController.text.trim();
              String sayfaAraligi = sayfaController.text.trim();
              String aciklama = aciklamaController.text.trim();

              if (kitapAdi.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Lütfen kitap adı giriniz!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              BuildContext? dialogContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext ctx) {
                  dialogContext = ctx;
                  return const PopScope(
                    canPop: false,
                    child: AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(color: Colors.indigo),
                          SizedBox(width: 20),
                          Text(
                            "Ödev tüm öğrencilere gönderiliyor...",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

              var studentsSnapshot = await FirebaseFirestore.instance
                  .collection('students')
                  .where('classId', isEqualTo: hedefClassId)
                  .get();

              for (var studentDoc in studentsSnapshot.docs) {
                var odevlerRef = studentDoc.reference.collection('odevler');

                var existingOdev = await odevlerRef
                    .where('tarihStr', isEqualTo: secilenTarihStr)
                    .get();

                if (existingOdev.docs.isNotEmpty) {
                  var docId = existingOdev.docs.first.id;
                  var mevcutVeri = existingOdev.docs.first.data();
                  List mevcutKitaplar = List.from(mevcutVeri['kitaplar'] ?? []);

                  mevcutKitaplar.add({
                    'kitapAdi': kitapAdi,
                    'sayfaAraligi': sayfaAraligi,
                    'aciklama': aciklama,
                    'durum': 'bekliyor',
                  });

                  await odevlerRef.doc(docId).update({
                    'kitaplar': mevcutKitaplar,
                  });
                } else {
                  await odevlerRef.add({
                    'tarihStr': secilenTarihStr,
                    'kitaplar': [
                      {
                        'kitapAdi': kitapAdi,
                        'sayfaAraligi': sayfaAraligi,
                        'aciklama': aciklama,
                        'durum': 'bekliyor',
                      },
                    ],
                  });
                }
              }

              if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                Navigator.pop(dialogContext!);
              }

              if (!context.mounted) return;

              setState(() {});
              _scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text(
                    "Ödevler başarıyla gönderildi! ✅",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              );
            },
            child: const Text("Ödevi Gönder"),
          ),
        ],
      ),
    );
  }

  int _turkceKarsilastir(String a, String b) {
    const String turkceAlfabe = 'aabcçdefgğhıijklmnoöprsştuüvyz';

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

    int minLength = aKucuk.length < bKucuk.length
        ? aKucuk.length
        : bKucuk.length;

    for (int i = 0; i < minLength; i++) {
      int indexA = turkceAlfabe.indexOf(aKucuk[i]);
      int indexB = turkceAlfabe.indexOf(bKucuk[i]);

      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  Future<List<Map<String, dynamic>>> _getOgrenciler() async {
    List<Map<String, dynamic>> ogrenciListesi = [];

    if (widget.userRole == 'admin' ||
        widget.userRole == 'branch_teacher' ||
        widget.userRole == 'guidance_teacher') {
      String arananClassName = "$_filtreliGrade/$_filtreliBranch";

      var classQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('className', isEqualTo: arananClassName)
          .get();

      if (classQuery.docs.isEmpty) {
        return [];
      }

      String hedefClassId = classQuery.docs.first.id;

      var studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: hedefClassId)
          .get();

      for (var doc in studentsQuery.docs) {
        ogrenciListesi.add({'id': doc.id, ...doc.data()});
      }
    } else {
      var studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      for (var doc in studentsQuery.docs) {
        ogrenciListesi.add({'id': doc.id, ...doc.data()});
      }
    }

    ogrenciListesi.sort((a, b) {
      String adA = a['firstName'] ?? '';
      String adB = b['firstName'] ?? '';
      int adKarsilastir = _turkceKarsilastir(adA, adB);

      if (adKarsilastir != 0) {
        return adKarsilastir;
      }

      String soyadA = a['lastName'] ?? '';
      String soyadB = b['lastName'] ?? '';
      return _turkceKarsilastir(soyadA, soyadB);
    });

    return ogrenciListesi;
  }

  // Yetki kontrolü yaparak buton oluşturan yardımcı metot
  Widget? _buildYetkiliHizliIslemButonu({
    required String key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool gosterilsinMi =
        widget.userRole == 'classroom_teacher' || _izinliButonlar.contains(key);

    if (!gosterilsinMi) return null;

    return _buildHizliIslemButonu(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSinifOgretmeni = widget.userRole == 'classroom_teacher';
    bool isYetkili =
        widget.userRole == 'admin' ||
        widget.userRole == 'branch_teacher' ||
        widget.userRole == 'guidance_teacher';

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Text("${widget.className} Paneli"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: "Şifre Değiştir",
            onPressed: () {
              _sifreDegistirDialogGoster(context);
            },
          ),
        ],
      ),
      body: _yetkilerYukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isYetkili)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.indigo.shade100,
                    child: Row(
                      children: [
                        const Text(
                          "Sınıf Filtrele: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtreliGrade,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: ['1', '2', '3', '4'].map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text("$grade. Sınıf"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _filtreliGrade = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtreliBranch,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _branchListesi.map((branch) {
                              return DropdownMenuItem(
                                value: branch,
                                child: Text("$branch Şubesi"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _filtreliBranch = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  color: Colors.indigo.shade50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildYetkiliHizliIslemButonu(
                              key: 'nobetci',
                              icon: Icons.group_work,
                              label: "Nöbetçi & Görevli",
                              color: Colors.green.shade700,
                              onTap: () =>
                                  _showNobetciVeGorevliSecenekleri(context),
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'is_takibi',
                              icon: Icons.fact_check,
                              label: "İş Takibi",
                              color: Colors.teal,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SinifIsTakipScreen(
                                      classId: hedefClassId,
                                      userRole: widget.userRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'odev_islemleri',
                              icon: Icons.assignment,
                              label: "Ödev İşlemleri",
                              color: Colors.indigo,
                              // --- BURASI GÜNCELLENDİ ---
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;

                                // Eğer kullanıcı yönetici/idareci (admin) ise doğrudan Toplu Ödev sayfasına git
                                if (widget.userRole == 'admin') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TopluOdevScreen(
                                        classId: hedefClassId,
                                        userRole: widget.userRole,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Sınıf veya branş öğretmeniyse 3 seçenekli alt menüyü aç
                                  _showOdevIslemleriSecenekleri(context);
                                }
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'dogum_gunleri',
                              icon: Icons.cake,
                              label: "Doğum Günleri",
                              color: Colors.pink,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DogumGunleriScreen(
                                      classId: hedefClassId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'ders_programi',
                              icon: Icons.schedule,
                              label: "Ders Programı",
                              color: Colors.lightBlue,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;

                                // 1. DURUM: Sınıf Öğretmeni ise doğrudan 2 sekmeli sınıf programına git
                                if (widget.userRole == 'classroom_teacher') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HaftalikDersProgramiScreen(
                                            classId: hedefClassId,
                                            isTeacher: true,
                                            userRole: widget.userRole,
                                            scheduleDocId: 'haftalik',
                                            sayfaBasligi: "Sınıf Ders Programı",
                                            canEdit: true,
                                            isBranchSchedule:
                                                false, // Sınıf programı ders listesi kullanır
                                          ),
                                    ),
                                  );
                                }
                                // 2. DURUM: Branş Öğretmeni ise 2 seçenekli alt menü aç
                                else if (widget.userRole == 'branch_teacher') {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Ders Programı Seçimi",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Divider(),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.class_,
                                              color: Colors.indigo,
                                            ),
                                            title: const Text(
                                              "Seçili Sınıfın Ders Programını Gör",
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      HaftalikDersProgramiScreen(
                                                        classId: hedefClassId,
                                                        isTeacher: true,
                                                        userRole:
                                                            widget.userRole,
                                                        scheduleDocId:
                                                            'haftalik',
                                                        sayfaBasligi:
                                                            "Seçili Sınıf Programı",
                                                        canEdit: false,
                                                        isBranchSchedule:
                                                            false, // Sınıf programı
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.person,
                                              color: Colors.teal,
                                            ),
                                            title: const Text(
                                              "Kendi Programını Gör / Düzenle",
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);

                                              // BURASI DÜZELTİLDİ: Her branş öğretmeninin kendi unique classId'si onun program anahtarı olur
                                              String ogretmenProgramKey =
                                                  widget.classId;

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      HaftalikDersProgramiScreen(
                                                        classId: hedefClassId,
                                                        isTeacher: true,
                                                        userRole:
                                                            widget.userRole,
                                                        scheduleDocId:
                                                            ogretmenProgramKey, // Artık her öğretmenin kendi ID'si olacak
                                                        sayfaBasligi:
                                                            "Kişisel Branş Programım",
                                                        canEdit: true,
                                                        isBranchSchedule: true,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                // 3. DURUM: İdareci (Admin) ise 3 seçenekli alt menü aç
                                else if (widget.userRole == 'admin' ||
                                    widget.userRole == 'guidance_teacher') {
                                  // Yükleniyor göstergesi ile modal açalım
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.userRole == 'admin'
                                                ? "İdareci Ders Programı Görüntüleme"
                                                : "Rehberlik Ders Programı Görüntüleme",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Divider(),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.class_,
                                              color: Colors.indigo,
                                            ),
                                            title: const Text(
                                              "Seçili Sınıfın Programı",
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      HaftalikDersProgramiScreen(
                                                        classId: hedefClassId,
                                                        isTeacher: true,
                                                        userRole:
                                                            widget.userRole,
                                                        scheduleDocId:
                                                            'haftalik',
                                                        sayfaBasligi:
                                                            "Seçili Sınıf Programı",
                                                        canEdit: false,
                                                        isBranchSchedule: false,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Branş Öğretmenleri Programları:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          // Firestore'dan branch_teacher olanları dinamik çekelim
                                          Expanded(
                                            child: FutureBuilder<QuerySnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('classes')
                                                  .where(
                                                    'userRole',
                                                    isEqualTo: 'branch_teacher',
                                                  )
                                                  .get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }

                                                if (!snapshot.hasData ||
                                                    snapshot
                                                        .data!
                                                        .docs
                                                        .isEmpty) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child: Text(
                                                      "Kayıtlı branş öğretmeni bulunamadı.",
                                                    ),
                                                  );
                                                }

                                                var ogretmenDocs =
                                                    snapshot.data!.docs;

                                                return ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      ogretmenDocs.length,
                                                  itemBuilder: (context, index) {
                                                    var doc =
                                                        ogretmenDocs[index];
                                                    var data =
                                                        doc.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    String ogretmenAdi =
                                                        data['teacherName'] ??
                                                        data['className'] ??
                                                        'Branş Öğretmeni';
                                                    String docId = doc
                                                        .id; // Bu öğretmenin programının kaydedileceği doküman ID'si

                                                    return ListTile(
                                                      leading: const Icon(
                                                        Icons.person,
                                                        color: Colors.teal,
                                                      ),
                                                      title: Text(ogretmenAdi),
                                                      subtitle: const Text(
                                                        "Programı Görüntüle",
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => HaftalikDersProgramiScreen(
                                                              classId:
                                                                  hedefClassId,
                                                              isTeacher: true,
                                                              userRole: widget
                                                                  .userRole,
                                                              scheduleDocId:
                                                                  docId, // Öğretmene özel doküman ID'si
                                                              sayfaBasligi:
                                                                  "$ogretmenAdi Programı",
                                                              canEdit:
                                                                  false, // İdareci sadece görür
                                                              isBranchSchedule:
                                                                  true, // Şube seçmeli liste açılır
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
                                  );
                                }
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'sohbet_duvar',
                              icon: Icons.chat,
                              label: "Sohbet & Duvar",
                              color: Colors.lightGreenAccent,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;

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
                                          "Öğretmen İletişim & Denetim",
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
                                            "Öğrencilerle ortak akış ve paylaşımlar",
                                          ),
                                          onTap: () {
                                            Navigator.pop(bottomSheetContext);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ClassFeedScreen(
                                                      currentUserId:
                                                          FirebaseAuth
                                                              .instance
                                                              .currentUser
                                                              ?.uid ??
                                                          "ogretmen_id",
                                                      currentUserName:
                                                          "Öğretmen",
                                                      isTeacher: true,
                                                      classId: hedefClassId,
                                                      className:
                                                          widget.className,
                                                      userRole: widget.userRole,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.security,
                                            color: Colors.indigo,
                                            size: 30,
                                          ),
                                          title: const Text(
                                            "Tüm Sınıf Sohbetleri (Denetim)",
                                          ),
                                          subtitle: const Text(
                                            "Öğrenci aralarındaki bireysel ve grup sohbetleri",
                                          ),
                                          onTap: () {
                                            Navigator.pop(bottomSheetContext);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TeacherChatAuditScreen(
                                                      classId: hedefClassId,
                                                      currentUserId:
                                                          FirebaseAuth
                                                              .instance
                                                              .currentUser
                                                              ?.uid ??
                                                          "ogretmen_id",
                                                      currentUserName:
                                                          "Öğretmen",
                                                      userRole: widget
                                                          .userRole, // <--- Rolü buraya da ekleyin
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ].whereType<Widget>().toList(),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildYetkiliHizliIslemButonu(
                              key: 'etutler',
                              icon: Icons.event_available,
                              label: "Etütler",
                              color: Colors.deepPurple,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => etutlerscreen(
                                      classId: hedefClassId,
                                      className: widget.className,
                                      userRole: widget.userRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'denemeler',
                              icon: Icons.edit_note,
                              label: "Denemeler",
                              color: Colors.indigo,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;

                                // Sınıf adından seviyeyi ayıkla (Örn: "2/D" -> "2")
                                String sinifSeviyesi =
                                    widget.className.contains('/')
                                    ? widget.className.split('/')[0]
                                    : '2';

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DenemelerScreen(
                                      classId: hedefClassId,
                                      className: widget.className,
                                      userRole: widget.userRole,
                                      grade:
                                          sinifSeviyesi, // <--- Sınıf seviyesi buraya aktarılıyor
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'kitap_odev',
                              icon: Icons.menu_book,
                              label: "Kitap Okuma",
                              color: Colors.brown,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => KitapOkumaTakipScreen(
                                      classId: hedefClassId,
                                      className: widget.className,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'oturma_duzeni',
                              icon: Icons.grid_view,
                              label: "Oturma Düzeni",
                              color: Colors.indigo.shade700,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OturmaDuzeniScreen(
                                      classId: hedefClassId,
                                      isTeacher: true,
                                      userRole: widget
                                          .userRole, // <--- BURAYI EKLEYİN
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'devamsizlik',
                              icon: Icons.fact_check,
                              label: "Devamsızlık",
                              color: Colors.teal,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DevamsizlikScreen(
                                      classId: hedefClassId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'randevular',
                              icon: Icons.access_time,
                              label: "Randevular",
                              color: Colors.orange,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OgretmenRandevuScreen(
                                      classId: hedefClassId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ].whereType<Widget>().toList(),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildYetkiliHizliIslemButonu(
                              key: 'sozluk',
                              icon: Icons.library_books,
                              label: "Sözlük",
                              color: Colors.deepOrange,
                              onTap: () => _showSozlukSecenekleri(context),
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'etkinlikler',
                              icon: Icons.auto_stories,
                              label: "Etkinlikler",
                              color: Colors.pinkAccent,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EtkinliklerScreen(
                                      classId: hedefClassId,
                                      isTeacher: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'davranislar',
                              icon: Icons.auto_stories,
                              label: "Davranışlar",
                              color: const Color.fromARGB(255, 139, 175, 238),
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OgretmenDavranisScreen(
                                          classId: hedefClassId,
                                          isTeacher: true,
                                        ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'yarismalar',
                              icon: Icons.auto_stories,
                              label: "Yarışmalar",
                              color: Colors.purpleAccent,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => YarismalarScreen(
                                      classId: hedefClassId,
                                      isTeacher: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'istatistikler',
                              icon: Icons.auto_stories,
                              label: "Kullanım İstatistikleri",
                              color: Colors.yellow.shade700,
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SinifIstatistikSiralamaScreen(
                                          classId: hedefClassId,
                                        ),
                                  ),
                                );
                              },
                            ),
                            _buildYetkiliHizliIslemButonu(
                              key: 'sinif_sifreleri',
                              icon: Icons.auto_stories,
                              label: "Sınıf Şifreleri",
                              color: const Color.fromARGB(255, 69, 9, 80),
                              onTap: () async {
                                String? hedefClassId =
                                    await _getAktifHedefClassId();
                                if (hedefClassId == null) return;
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SinifSifreleriScreen(
                                      classId: hedefClassId,
                                      className: widget.className,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ].whereType<Widget>().toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getOgrenciler(),
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
                          final initials =
                              (firstName.isNotEmpty ? firstName[0] : '') +
                              (lastName.isNotEmpty ? lastName[0] : '');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailScreen(
                                      studentData: student,
                                      studentId: student['id'],
                                      userRole: widget.userRole,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              leading: CircleAvatar(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSinifOgretmeni) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _duzenle(
                                        context,
                                        student['id'],
                                        student,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _sil(context, student['id']),
                                    ),
                                  ],
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.indigo,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: isSinifOgretmeni
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStudentScreen(
                      userRole: widget.userRole,
                      currentClassId: widget.classId,
                    ),
                  ),
                );
                setState(() {});
              },
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildHizliIslemButonu({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 95,
          height: 75,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
