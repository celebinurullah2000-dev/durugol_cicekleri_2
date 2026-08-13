// ignore_for_file: use_super_parameters, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart'; // Bir sonraki adımda yazacağımız detay ekranı

class ChatListScreen extends StatelessWidget {
  final String currentUserId;
  final String
  currentUserName; // <--- Bu alanın burada tanımlı olduğundan emin ol!
  final bool isTeacher;
  final String classId;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName, // <--- Burada da olmalı
    required this.isTeacher,
    required this.classId,
  }) : super(key: key);

  // Bireysel sohbet ID'si üretme (Alfabetik sıralama ile benzersizlik)
  String _getBireyselChatId(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? "${id1}_$id2" : "${id2}_$id1";
  }

  // Grup Oluşturma Dialogu
  void _grupOlusturDialog(BuildContext context) {
    final TextEditingController groupNameController = TextEditingController();
    List<String> selectedMemberIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yeni Grup Sohbeti Kur 👥"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: "Grup Adı (Örn: Proje Ekibi)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Gruba Eklenecek Öğrenciler:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('classId', isEqualTo: classId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      var students = snapshot.data!.docs;
                      students.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;
                        String adA =
                            "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                        String adB =
                            "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
                        return _turkceKarsilastir(adA, adB);
                      });
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var student = students[index];
                          var data = student.data() as Map<String, dynamic>;
                          String studentId = student.id;
                          String studentName =
                              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

                          if (studentId == currentUserId)
                            return const SizedBox.shrink(); // Kendini listede geç

                          bool isSelected = selectedMemberIds.contains(
                            studentId,
                          );

                          return CheckboxListTile(
                            title: Text(studentName),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedMemberIds.add(studentId);
                                } else {
                                  selectedMemberIds.remove(studentId);
                                }
                              });
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
                if (groupNameController.text.trim().isEmpty ||
                    selectedMemberIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Lütfen grup adı yazın ve en az bir üye seçin!",
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Grubu oluşturan kişiyi de katılımcılara ekleyelim
                List<String> allParticipants = [
                  ...selectedMemberIds,
                  currentUserId,
                ];

                // Eğer oluşturan öğretmen değilse, öğretmenin de her şeyi görebilmesi için
                // öğretmeni katılımcılara otomatik dahil edebiliriz veya güvenlik kuralı kullanabiliriz.
                // En garanti yol: Tüm grup katılımcılarına eklemek.

                await FirebaseFirestore.instance.collection('chats').add({
                  'classId': classId,
                  'isGroup': true,
                  'groupName': groupNameController.text.trim(),
                  'groupAdminId': currentUserId,
                  'participants': allParticipants,
                  'lastMessage': "Grup kuruldu",
                  'lastMessageTime': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Grup başarıyla oluşturuldu! 🎉"),
                  ),
                );
              },
              child: const Text("Kur"),
            ),
          ],
        ),
      ),
    );
  }

  // Yeni Sohbet veya Grup Başlatma Dialogu
  void _yeniSohbetAcDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sohbet Başlat"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .where('classId', isEqualTo: classId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              var students = snapshot.data!.docs;

              // --- TÜRKÇE ALFABETİK SIRALAMA ---
              students.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                String adA =
                    "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                String adB =
                    "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";

                return _turkceKarsilastir(adA, adB);
              });

              return ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var student = students[index];
                  var data = student.data() as Map<String, dynamic>;
                  String studentId = student.id;
                  String studentName =
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

                  if (studentId == currentUserId)
                    return const SizedBox.shrink(); // Kendini listeleme

                  return ListTile(
                    title: Text(studentName),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    onTap: () async {
                      Navigator.pop(context);

                      String chatId = _getBireyselChatId(
                        currentUserId,
                        studentId,
                      );

                      var chatDoc = await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .get();
                      if (!chatDoc.exists) {
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .set({
                              'isGroup': false,
                              'participants': [currentUserId, studentId],
                              // Kimin hangi adı olduğunu kaydediyoruz:
                              'participantNames': {
                                currentUserId: currentUserName,
                                studentId: studentName,
                              },
                              'lastMessage': "Sohbet başladı",
                              'lastMessageTime': FieldValue.serverTimestamp(),
                            });
                      }

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatId: chatId,
                            chatTitle:
                                studentName, // Detay sayfasına da bu ad gönderiliyor
                            currentUserId: currentUserId,
                            currentUserName: currentUserName,
                            isTeacher: isTeacher,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sohbet Odaları 💬"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: isTeacher
            ? FirebaseFirestore.instance
                  .collection('chats')
                  .snapshots() // Öğretmen tüm sohbetleri görür
            : FirebaseFirestore.instance
                  .collection('chats')
                  .where(
                    'participants',
                    arrayContains: currentUserId,
                  ) // Öğrenci sadece katıldıklarını görür
                  .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz aktif bir sohbet yok. Yeni sohbet başlat! 😊"),
            );
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];
              var data = chat.data() as Map<String, dynamic>;
              String chatId = chat.id;
              bool isGroup = data['isGroup'] ?? false;

              // --- DİNAMİK BAŞLIK BELİRLEME MANTIĞI ---
              String title = 'Sohbet';

              if (isGroup) {
                title = data['groupName'] ?? 'Grup Sohbeti';
                List<dynamic> participants = data['participants'] ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .where(
                        FieldPath.documentId,
                        whereIn: participants.isEmpty
                            ? ['bos_id']
                            : participants,
                      )
                      .snapshots(),
                  builder: (context, studentSnapshot) {
                    String uyeListesi = "Üyeler yükleniyor...";
                    if (studentSnapshot.hasData) {
                      var studentDocs = studentSnapshot.data!.docs;
                      List<String> names = studentDocs.map((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        return "${d['firstName'] ?? ''} ${d['lastName'] ?? ''}"
                            .trim();
                      }).toList();
                      uyeListesi = names.join(', ');
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Üyeler: $uyeListesi\nSon: ${data['lastMessage'] ?? ''}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chatId,
                                chatTitle: title,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                isTeacher: isTeacher,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              } else {
                // Bireysel sohbetse, 'participantNames' haritasından diğer kişinin adını buluyoruz
                Map<String, dynamic> names = data['participantNames'] ?? {};
                List<dynamic> parts = data['participants'] ?? [];

                // Kendi ID'miz dışındaki diğer katılımcının ID'sini bul
                String otherUserId = parts.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                // Haritadan o kişinin adını al, yoksa varsayılan yaz
                title = names[otherUserId] ?? 'Bireysel Sohbet';
              }

              String lastMessage = data['lastMessage'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGroup ? Colors.orange : Colors.blue,
                    child: Icon(
                      isGroup ? Icons.group : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatId: chatId,
                          chatTitle: title,
                          currentUserId: currentUserId,
                          currentUserName: currentUserName,
                          isTeacher: isTeacher,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _sohbetEkleSecenekleri(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  // Sohbet Ekleme Seçenekleri Menüsü
  void _sohbetEkleSecenekleri(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Sohbet İşlemleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text("Bireysel Sohbet Başlat"),
              onTap: () {
                Navigator.pop(context);
                _yeniSohbetAcDialog(context); // Önceki bireysel açma dialogu
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.orange),
              title: const Text("Grup Sohbeti Kur"),
              onTap: () {
                Navigator.pop(context);
                _grupOlusturDialog(context); // Az önce yazdığımız grup dialogu
              },
            ),
          ],
        ),
      ),
    );
  }

  // Türkçe Alfabetik Sıralama Fonksiyonu
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
}
