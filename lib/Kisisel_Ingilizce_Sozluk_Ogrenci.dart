// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KisiselIngilizceSozlukOgrenci extends StatefulWidget {
  final String classId;

  const KisiselIngilizceSozlukOgrenci({super.key, required this.classId});

  @override
  State<KisiselIngilizceSozlukOgrenci> createState() =>
      _KisiselIngilizceSozlukOgrenciState();
}

class _KisiselIngilizceSozlukOgrenciState
    extends State<KisiselIngilizceSozlukOgrenci> {
  String _aramaMetni = "";

  late String _secilenSinifFiltre;
  String _secilenTemaFiltre = "Tüm Temalar";

  // Öğrencinin sınıf seviyesini classId'den tespit etme
  int get _ogrenciSinifSeviyesi {
    for (var char in widget.classId.split('')) {
      if (char == '2' || char == '3' || char == '4') {
        return int.parse(char);
      }
    }
    return 4; // Varsayılan
  }

  @override
  void initState() {
    super.initState();
    if (_ogrenciSinifSeviyesi == 2) {
      _secilenSinifFiltre = "2. Sınıf";
    } else {
      _secilenSinifFiltre = "Tüm Sınıflar";
    }
  }

  // Öğrenci seviyesine göre sınıf seçenekleri
  List<String> get _sinifSecenekleri {
    if (_ogrenciSinifSeviyesi == 4) {
      return ["Tüm Sınıflar", "2. Sınıf", "3. Sınıf", "4. Sınıf"];
    } else if (_ogrenciSinifSeviyesi == 3) {
      return ["Tüm Sınıflar", "2. Sınıf", "3. Sınıf"];
    } else {
      return ["2. Sınıf"];
    }
  }

  // Seçilen sınıfa göre dinamik tema listesi (4. sınıfta 10 tema, diğerlerinde 6 tema)
  List<String> get _aktifTemaSecenekleri {
    if (_secilenSinifFiltre == "4. Sınıf") {
      return [
        "Tüm Temalar",
        "Theme 1",
        "Theme 2",
        "Theme 3",
        "Theme 4",
        "Theme 5",
        "Theme 6",
        "Theme 7",
        "Theme 8",
        "Theme 9",
        "Theme 10",
      ];
    } else {
      return [
        "Tüm Temalar",
        "Theme 1",
        "Theme 2",
        "Theme 3",
        "Theme 4",
        "Theme 5",
        "Theme 6",
      ];
    }
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
        if (comp != 0) {
          return comp;
        }
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }
    return aKucuk.length.compareTo(bKucuk.length);
  }

  void _sozcukDetayGoster(Map<String, dynamic> data) {
    String sozcuk = data['sozcuk'] ?? '';
    String anlam = data['anlam'] ?? '';
    String gorselUrl = data['gorselUrl'] ?? '';
    String sinif = data['sinifSeviyesi'] ?? 'Belirtilmemiş';
    String tema = data['tema'] ?? 'Belirtilmemiş';
    List<dynamic> cumleler = data['cumleler'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          sozcuk,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(sinif, style: const TextStyle(fontSize: 11)),
                  ),
                  Chip(label: Text(tema, style: const TextStyle(fontSize: 11))),
                ],
              ),
              const SizedBox(height: 8),
              if (gorselUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: gorselUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 120,
                        width: 120,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                "Meaning (Anlamı):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                anlam,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Example Sentences (Örnek Cümleler):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (cumleler.isEmpty)
                const Text(
                  "Örnek cümle eklenmemiş.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                ...cumleler.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${entry.key + 1}. \"${entry.value}\"",
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İngilizce Sözlük"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- FİLTRELEME ALANI ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // 1. Sınıf Filtresi
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _secilenSinifFiltre,
                        isExpanded: true,
                        items: _sinifSecenekleri
                            .map(
                              (sinif) => DropdownMenuItem(
                                value: sinif,
                                child: Text(
                                  sinif,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (_ogrenciSinifSeviyesi == 2)
                            ? null // 2. sınıf öğrencisi sınıf değiştiremez
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _secilenSinifFiltre = val;
                                    if (!_aktifTemaSecenekleri.contains(
                                      _secilenTemaFiltre,
                                    )) {
                                      _secilenTemaFiltre = "Tüm Temalar";
                                    }
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 2. Tema Filtresi
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            _aktifTemaSecenekleri.contains(_secilenTemaFiltre)
                            ? _secilenTemaFiltre
                            : "Tüm Temalar",
                        isExpanded: true,
                        items: _aktifTemaSecenekleri
                            .map(
                              (tema) => DropdownMenuItem(
                                value: tema,
                                child: Text(
                                  tema,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _secilenTemaFiltre = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- ARAMA ÇUBUĞU ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (deger) => setState(() => _aramaMetni = deger.trim()),
              decoration: InputDecoration(
                labelText: "Search Word (Sözcük Ara)",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: _aramaMetni.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _aramaMetni = ""),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // --- LİSTELEME VE FİLTRELEME ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('genel_ingilizce_sozluk')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz İngilizce sözlüğe eklenmiş bir sözcük yok.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                List<Map<String, dynamic>> sozlukListesi = [];
                for (var doc in docs) {
                  sozlukListesi.add({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  });
                }

                // 1. Sınıf Filtresi Uygula
                if (_secilenSinifFiltre != "Tüm Sınıflar") {
                  sozlukListesi = sozlukListesi.where((item) {
                    return item['sinifSeviyesi'] == _secilenSinifFiltre;
                  }).toList();
                } else {
                  // "Tüm Sınıflar" seçiliyse öğrencinin sınıf seviyesine göre sınırla
                  if (_ogrenciSinifSeviyesi == 3) {
                    sozlukListesi = sozlukListesi.where((item) {
                      return item['sinifSeviyesi'] == "2. Sınıf" ||
                          item['sinifSeviyesi'] == "3. Sınıf";
                    }).toList();
                  } else if (_ogrenciSinifSeviyesi == 2) {
                    sozlukListesi = sozlukListesi.where((item) {
                      return item['sinifSeviyesi'] == "2. Sınıf";
                    }).toList();
                  }
                }

                // 2. Tema Filtresi Uygula
                if (_secilenTemaFiltre != "Tüm Temalar") {
                  sozlukListesi = sozlukListesi.where((item) {
                    return item['tema'] == _secilenTemaFiltre;
                  }).toList();
                }

                sozlukListesi.sort(
                  (a, b) =>
                      _turkceKarsilastir(a['sozcuk'] ?? '', b['sozcuk'] ?? ''),
                );

                if (_aramaMetni.isNotEmpty) {
                  sozlukListesi = sozlukListesi.where((item) {
                    return (item['sozcuk'] ?? '')
                        .toString()
                        .toLowerCase()
                        .startsWith(_aramaMetni.toLowerCase());
                  }).toList();
                }

                if (sozlukListesi.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aranan kritere uygun sözcük bulunamadı.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sozlukListesi.length,
                  itemBuilder: (context, index) {
                    var item = sozlukListesi[index];
                    String gorselUrl = item['gorselUrl'] ?? '';
                    String sinifEtiket = item['sinifSeviyesi'] ?? '';
                    String temaEtiket = item['tema'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: gorselUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  gorselUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      backgroundColor: Colors.indigo.shade100,
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                        title: Row(
                          children: [
                            Text(
                              item['sozcuk'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (sinifEtiket.isNotEmpty || temaEtiket.isNotEmpty)
                              Text(
                                "$sinifEtiket | $temaEtiket",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          item['anlam'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.indigo,
                        ),
                        onTap: () => _sozcukDetayGoster(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
