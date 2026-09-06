import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineKullanicilarScreen extends StatelessWidget {
  const OnlineKullanicilarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Şu andan 2 dakika öncesini hesaplıyoruz
    DateTime ikiDakikaOnce = DateTime.now().subtract(
      const Duration(minutes: 2),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Anlık Online Kullanıcılar"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sadece son 2 dakika içinde 'lastActive' güncellenmiş olanları getiriyoruz
        stream: FirebaseFirestore.instance
            .collection('online_users')
            .where(
              'lastActive',
              isGreaterThan: Timestamp.fromDate(ikiDakikaOnce),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Şu an aktif online kullanıcı bulunmuyor.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String role = data['role'] ?? 'staff';
              String name = data['name'] ?? 'Bilinmeyen Kullanıcı';
              String sinifSube = data['sinifSube'] ?? '';

              bool isOgrenci = role == 'student';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOgrenci
                        ? Colors.blue.shade100
                        : Colors.indigo,
                    child: Icon(
                      isOgrenci ? Icons.person : Icons.school,
                      color: isOgrenci ? Colors.indigo : Colors.white,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isOgrenci
                        ? "Sınıf / Şube: $sinifSube"
                        : "Okul Personeli / Yetkili",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Aktif",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
