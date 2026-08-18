import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  void _sozcukDetayGoster(Map<String, dynamic> data) {
    String sozcuk = data['sozcuk'] ?? '';
    String anlam = data['anlam'] ?? '';
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        title: Text(
                          item['sozcuk'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
