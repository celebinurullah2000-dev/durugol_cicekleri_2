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
      "firstName": "ASEL HİRA",
      "lastName": "BEKTAŞ",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "aselhira",
    },
    {
      "firstName": "ALYA HİLAL",
      "lastName": "TOPGÜL",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "alyahilal",
    },
    {
      "firstName": "AYŞE BİLGE",
      "lastName": "MURATALDI",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "ayşebilge",
    },
    {
      "firstName": "AZRA MİNA",
      "lastName": "BEKTAŞ",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "azramina",
    },
    {
      "firstName": "BERİKA NUR",
      "lastName": "ÖZSOY",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "berikanur",
    },
    {
      "firstName": "BETÜL SARE",
      "lastName": "ÜSTÜN",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "betülsare",
    },
    {
      "firstName": "DEFNE",
      "lastName": "KAHVECİ",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "defne",
    },
    {
      "firstName": "ELİF ZÜMRA",
      "lastName": "TEMEL",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "elifzümra",
    },
    {
      "firstName": "EYLÜL",
      "lastName": "ÇAKMAK",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "eylül",
    },
    {
      "firstName": "LİNA",
      "lastName": "GÜNGÖR",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "lina",
    },
    {
      "firstName": "MİRAY",
      "lastName": "AKYÜREK",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "miray",
    },
    {
      "firstName": "NASMİNA",
      "lastName": "AKKURT",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "nasmina",
    },
    {
      "firstName": "NİDA BETÜL",
      "lastName": "AYGÜN",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "nidabetül",
    },
    {
      "firstName": "ŞEVVAL",
      "lastName": "ENGİNYURT",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "şevval",
    },
    {
      "firstName": "ZEYNEP ADA",
      "lastName": "TÜRKYILMAZ",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "zeynepada",
    },
    {
      "firstName": "ZEYNEP DURU",
      "lastName": "AKOVA",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "zeynepduru",
    },
    {
      "firstName": "ZEYNEP ELÇİN",
      "lastName": "KALİN",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "zeynepelçin",
    },
    {
      "firstName": "ZEYNEP GÜLCE",
      "lastName": "AYDIN",
      "sinif": "3-G",
      "cinsiyet": "K",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "zeynepgülce",
    },
    {
      "firstName": "SARP METE",
      "lastName": "ÇAKIROĞLU",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "sarpmete",
    },
    {
      "firstName": "ALİ ASIM",
      "lastName": "EKİCİ",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "aliasım",
    },
    {
      "firstName": "ALPER YAĞIZ",
      "lastName": "ÖZTÜRK",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "alperyağız",
    },
    {
      "firstName": "BEDİRHAN ASAF",
      "lastName": "YILMAZ",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "bedirhanasaf",
    },
    {
      "firstName": "EMİR",
      "lastName": "PERÇİN",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "emir",
    },
    {
      "firstName": "GÜNALP YENER",
      "lastName": "YILMAZ",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "günalpyener",
    },
    {
      "firstName": "MAHMUD ASAF",
      "lastName": "AYDINHAN",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "mahmudasaf",
    },
    {
      "firstName": "MERT",
      "lastName": "TEMİZ",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "mert",
    },
    {
      "firstName": "MUHAMMED YİĞİT",
      "lastName": "SAKA",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "muhammedyiğit",
    },
    {
      "firstName": "ÖMER SAMİ",
      "lastName": "POYRAZ",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "ömersami",
    },
    {
      "firstName": "RÜZGAR",
      "lastName": "TAŞTEMİR",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "rüzgar",
    },
    {
      "firstName": "EDİZ TUNA",
      "lastName": "KANDEMİR",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "ediztuna",
    },
    {
      "firstName": "KUZEY MERT",
      "lastName": "AKSOY",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "kuzeymert",
    },
    {
      "firstName": "TUĞRA",
      "lastName": "KURU",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "tuğra",
    },
    {
      "firstName": "YAĞIZ KAAN",
      "lastName": "BAYAZİT",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "yağızkaan",
    },
    {
      "firstName": "YAMAN ATA",
      "lastName": "TÜRKER",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "yamanata",
    },
    {
      "firstName": "YİĞİT",
      "lastName": "DEMİRBİLEK",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "yiğit",
    },
    {
      "firstName": "ARAL",
      "lastName": "OY",
      "sinif": "3-G",
      "cinsiyet": "E",
      "classId": "6JIbrVWVbwriXVzlEvRJ",
      "password": "aral",
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
