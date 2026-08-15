import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YetkiTanimlaScreen extends StatefulWidget {
  const YetkiTanimlaScreen({super.key});

  @override
  State<YetkiTanimlaScreen> createState() => _YetkiTanimlaScreenState();
}

class _YetkiTanimlaScreenState extends State<YetkiTanimlaScreen> {
  // Ana sayfada yer alan butonların benzersiz anahtarları ve görünen isimleri
  final List<Map<String, String>> _menuButonlari = [
    {'key': 'nobetci', 'label': 'Nöbetçi & Görevli'},
    {'key': 'is_takibi', 'label': 'İş Takibi'},
    {'key': 'odev_islemleri', 'label': 'Ödev İşlemleri'},
    {'key': 'dogum_gunleri', 'label': 'Doğum Günleri'},
    {'key': 'ders_programi', 'label': 'Ders Programı'},
    {'key': 'sohbet_duvar', 'label': 'Sohbet & Duvar'},
    {'key': 'etutler', 'label': 'Etütler'},
    {'key': 'denemeler', 'label': 'Denemeler'},
    {'key': 'kitap_odev', 'label': 'Kitap ve Ödev'},
    {'key': 'oturma_duzeni', 'label': 'Oturma Düzeni'},
    {'key': 'devamsizlik', 'label': 'Devamsızlık'},
    {'key': 'randevular', 'label': 'Randevular'},
    {'key': 'sozluk', 'label': 'Sözlük & Dil Araçları'},
    {'key': 'etkinlikler', 'label': 'Etkinlikler'},
    {'key': 'davranislar', 'label': 'Davranışlar'},
    {'key': 'yarismalar', 'label': 'Yarışmalar'},
    {'key': 'istatistikler', 'label': 'Kullanım İstatistikleri'},
    {'key': 'sinif_sifreleri', 'label': 'Sınıf Şifreleri'},
  ];

  final Map<String, List<String>> _rolePermissions = {
    'admin': [],
    'branch_teacher': [],
    'guidance_teacher': [], // Rehber Öğretmen eklendi[cite: 7]
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yetkileriGetir();
  }

  Future<void> _yetkileriGetir() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('role_permissions')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _rolePermissions['admin'] = List<String>.from(data['admin'] ?? []);
          _rolePermissions['branch_teacher'] = List<String>.from(
            data['branch_teacher'] ?? [],
          );
          _rolePermissions['guidance_teacher'] = List<String>.from(
            data['guidance_teacher'] ?? [],
          );
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

  Future<void> _yetkiyiKaydet() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('role_permissions')
          .set({
            'admin': _rolePermissions['admin'],
            'branch_teacher': _rolePermissions['branch_teacher'],
            'guidance_teacher': _rolePermissions['guidance_teacher'],
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yetkiler başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Toplu seçme/kaldırma yardımcısı
  bool _tumunuSecebilirMi(String roleKey) {
    return _rolePermissions[roleKey]!.length == _menuButonlari.length;
  }

  void _tumunuDegistir(String roleKey, bool? value) {
    setState(() {
      if (value == true) {
        _rolePermissions[roleKey] = _menuButonlari
            .map((m) => m['key']!)
            .toList();
      } else {
        _rolePermissions[roleKey] = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool adminTumuSecili = _tumunuSecebilirMi('admin');
    bool branchTumuSecili = _tumunuSecebilirMi('branch_teacher');
    bool guidanceTumuSecili = _tumunuSecebilirMi('guidance_teacher');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rol Bazlı Yetki Tanımla"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "İdareci, Branş ve Rehber öğretmenlerin ana sayfada hangi butonları görebileceğini buradan seçebilirsiniz.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                // --- TOPLU DEĞER ATAMA (HIZLI SEÇİM) KUTUSU ---
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tüm Menüler İçin\nToplu Seç / Kaldır",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.indigo,
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          // İdareci Toplu Checkbox
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "İdareci Tümü",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                activeColor: Colors.purple,
                                value: adminTumuSecili,
                                onChanged: (val) =>
                                    _tumunuDegistir('admin', val),
                              ),
                            ],
                          ),
                          // Branş Öğr. Toplu Checkbox
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Branş Tümü",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                activeColor: Colors.orange,
                                value: branchTumuSecili,
                                onChanged: (val) =>
                                    _tumunuDegistir('branch_teacher', val),
                              ),
                            ],
                          ),
                          // Rehber Öğr. Toplu Checkbox
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Rehber Tümü",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                activeColor: Colors.teal,
                                value: guidanceTumuSecili,
                                onChanged: (val) =>
                                    _tumunuDegistir('guidance_teacher', val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuButonlari.length,
                    itemBuilder: (context, index) {
                      var buton = _menuButonlari[index];
                      String key = buton['key']!;
                      String label = buton['label']!;

                      bool adminGorebilir = _rolePermissions['admin']!.contains(
                        key,
                      );
                      bool branchGorebilir = _rolePermissions['branch_teacher']!
                          .contains(key);
                      bool guidanceGorebilir =
                          _rolePermissions['guidance_teacher']!.contains(key);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Wrap(
                            spacing: 12,
                            children: [
                              // İdareci Checkbox
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "İdareci",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Checkbox(
                                    activeColor: Colors.purple,
                                    value: adminGorebilir,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _rolePermissions['admin']!.add(key);
                                        } else {
                                          _rolePermissions['admin']!.remove(
                                            key,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              // Branş Öğretmeni Checkbox
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Branş Öğr.",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Checkbox(
                                    activeColor: Colors.orange,
                                    value: branchGorebilir,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _rolePermissions['branch_teacher']!
                                              .add(key);
                                        } else {
                                          _rolePermissions['branch_teacher']!
                                              .remove(key);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              // Rehber Öğretmen Checkbox
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Rehber Öğr.",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  Checkbox(
                                    activeColor: Colors.teal,
                                    value: guidanceGorebilir,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _rolePermissions['guidance_teacher']!
                                              .add(key);
                                        } else {
                                          _rolePermissions['guidance_teacher']!
                                              .remove(key);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                      onPressed: _yetkiyiKaydet,
                      child: const Text(
                        "Yetkileri Kaydet",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
