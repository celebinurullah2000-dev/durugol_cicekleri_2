import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciYuklemeScreen extends StatefulWidget {
  const OgrenciYuklemeScreen({super.key});

  @override
  State<OgrenciYuklemeScreen> createState() => _OgrenciYuklemeScreenState();
}

class _OgrenciYuklemeScreenState extends State<OgrenciYuklemeScreen> {
  bool _isUploading = false;
  String _durumMesaji = "Yüklemeye hazır";

  // Doğrudan firstName, lastName ve password içeren liste
  final List<Map<String, String>> ogrenciListesi = [
    {
      "firstName": "ELİF ASYA",
      "lastName": "KURT",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "elifasya",
    },
    {
      "firstName": "EMİNE ELA",
      "lastName": "TEPELİ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "emineela",
    },
    {
      "firstName": "BERRA",
      "lastName": "YILMAZ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "berra",
    },
    {
      "firstName": "BEYZANUR",
      "lastName": "ŞAHİN",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "beyzanur",
    },
    {
      "firstName": "EYLÜL",
      "lastName": "ERZURUMLUOĞLU",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "eylül",
    },
    {
      "firstName": "ELANUR",
      "lastName": "KELEŞ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "elanur",
    },
    {
      "firstName": "BİLGENAZ",
      "lastName": "TURHAN",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "bilgenaz",
    },
    {
      "firstName": "DURU",
      "lastName": "DUMAN",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "duru",
    },
    {
      "firstName": "ELİZ",
      "lastName": "AKTAŞ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "eliz",
    },
    {
      "firstName": "İZEL",
      "lastName": "AKTAŞ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "izel",
    },
    {
      "firstName": "GÜLÇE NEHİR",
      "lastName": "ŞEHİTTEPE",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "gülçenehir",
    },
    {
      "firstName": "İKRA NUR",
      "lastName": "KAPLAN",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "ikranur",
    },
    {
      "firstName": "LİNA",
      "lastName": "KOÇ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "lina",
    },
    {
      "firstName": "MAHPERİ",
      "lastName": "GEM",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "mahperi",
    },
    {
      "firstName": "MELİKE UMAY",
      "lastName": "COŞKUN",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "melikeumay",
    },
    {
      "firstName": "SERRANUR",
      "lastName": "DEMİRBAŞ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "serranur",
    },
    {
      "firstName": "SUEDA",
      "lastName": "ALTMIŞDÖRTOĞLU",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "sueda",
    },
    {
      "firstName": "ZEYNEP NUR",
      "lastName": "DERELİ",
      "sinif": "4-D",
      "cinsiyet": "K",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "zeynepnur",
    },
    {
      "firstName": "YILDIRIM",
      "lastName": "BAYAZIDOĞLU",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yıldırım",
    },
    {
      "firstName": "SELİM",
      "lastName": "ERTÜRK",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "selim",
    },
    {
      "firstName": "ALPARSLAN YABGU",
      "lastName": "VARLIK",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "alparslanyabgu",
    },
    {
      "firstName": "YİĞİT",
      "lastName": "KURU",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yiğit",
    },
    {
      "firstName": "AHMET SEDAT",
      "lastName": "COŞKUN",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "ahmetsedat",
    },
    {
      "firstName": "ALİ TURAN",
      "lastName": "BURHAN",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "alituran",
    },
    {
      "firstName": "ALPEREN",
      "lastName": "KOCAKOÇ",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "alperen",
    },
    {
      "firstName": "ARAZ",
      "lastName": "AKKUZU",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "araz",
    },
    {
      "firstName": "AYHAN AYAZ",
      "lastName": "AYDOĞDU",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "ayhanayaz",
    },
    {
      "firstName": "ÖMER TOPRAK",
      "lastName": "ALTUNTAŞ",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "ömertoprak",
    },
    {
      "firstName": "BAHTİYAR ÇINAR",
      "lastName": "ÇAKIR",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "bahtiyarçınar",
    },
    {
      "firstName": "BARAN SALİM",
      "lastName": "ÖZTÜRK",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "baransalim",
    },
    {
      "firstName": "ÇINAR OLCAY",
      "lastName": "SENDAŞ",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "çınarolcay",
    },
    {
      "firstName": "FATİH",
      "lastName": "YÜKSEL",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "fatih",
    },
    {
      "firstName": "FIRAT",
      "lastName": "ÇABUK",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "fırat",
    },
    {
      "firstName": "YAVUZ SELİM",
      "lastName": "KIR",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yavuzselim",
    },
    {
      "firstName": "GÜNEY GURUR",
      "lastName": "GÜNDAY",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "güneygurur",
    },
    {
      "firstName": "MEHMET AKİF",
      "lastName": "BULUT",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "mehmetakif",
    },
    {
      "firstName": "YİĞİT EGE",
      "lastName": "AYDOĞAN",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yiğitege",
    },
    {
      "firstName": "YAMAN",
      "lastName": "AKBAL",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yaman",
    },
    {
      "firstName": "SEYYİD AHMED",
      "lastName": "ŞAHİN",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "seyyidahmed",
    },
    {
      "firstName": "YUSUF ARDA",
      "lastName": "ERCAN",
      "sinif": "4-D",
      "cinsiyet": "E",
      "classId": "mJhIkdf3VSezptHZeIj4",
      "password": "yusufarda",
    },
  ];

  Future<void> _ogrencileriTopluYukle() async {
    setState(() {
      _isUploading = true;
      _durumMesaji = "Öğrenciler Firestore'a yükleniyor...";
    });

    try {
      final firestore = FirebaseFirestore.instance;
      int sayac = 0;

      for (var ogrenci in ogrenciListesi) {
        String firstName = ogrenci["firstName"] ?? "";
        String lastName = ogrenci["lastName"] ?? "";
        String password = ogrenci["password"] ?? "";
        String hedefClassId = ogrenci["classId"] ?? "";
        String cinsiyet = ogrenci["cinsiyet"] ?? "K";

        // Doğrudan listedeki alanları kullanarak Firestore'a kayıt
        await firestore.collection('students').add({
          'classId': hedefClassId,
          'firstName': firstName,
          'lastName': lastName,
          'gender': cinsiyet,
          'password': password,
          'tc': '',
          'schoolNumber': '',
          'dogumTarihi': '',
          'anneAdi': '',
          'anneCep': '',
          'anneMeslegi': '',
          'babaAdi': '',
          'babaCep': '',
          'babaMeslegi': '',
          'kardesleri': '',
          'hasBeenOnDuty': false,
          'nobetMusait': true,
          'profileImageUrl': '',
          'resimBase64': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        sayac++;
      }

      setState(() {
        _durumMesaji = "Başarıyla $sayac öğrenci tüm alanlarıyla yüklendi!";
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _durumMesaji = "Hata oluştu: $e";
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("2, 3 ve 4. Sınıflar Toplu Yükleme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _durumMesaji,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ogrenciListesi.length,
                itemBuilder: (context, index) {
                  final o = ogrenciListesi[index];
                  String adSoyad = "${o["firstName"]} ${o["lastName"]}";
                  String sifre = o["password"] ?? "";
                  String sinif = o["sinif"] ?? "";

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: o["cinsiyet"] == "K"
                            ? Colors.pink[100]
                            : Colors.blue[100],
                        child: Text(sinif),
                      ),
                      title: Text(adSoyad),
                      subtitle: Text(
                        "Sınıf: $sinif | Cinsiyet: ${o["cinsiyet"]} | Şifre: $sifre",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isUploading ? null : _ogrencileriTopluYukle,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Tüm Öğrencileri Firestore'a Yükle",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
