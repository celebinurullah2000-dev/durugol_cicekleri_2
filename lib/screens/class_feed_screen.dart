// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassFeedScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final bool isTeacher; // Öğretmen mi öğrenci mi olduğunu anlamak için
  final String classId; // Hangi sınıfın duvarı?
  final String className; // Başlıkta yazacak sınıf adı (Örn: 4/C)
  final String
  userRole; // Kullanıcının rolü (classroom_teacher, admin vb.)[cite: 5]

  const ClassFeedScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.isTeacher,
    required this.classId,
    required this.className,
    this.userRole = 'classroom_teacher', // Varsayılan değer[cite: 5]
  });

  @override
  State<ClassFeedScreen> createState() => _ClassFeedScreenState();
}

class _ClassFeedScreenState extends State<ClassFeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    // Eğer giren kişi öğrenci ise sınıf duvarı ban kontrolünü yap
    if (!widget.isTeacher) {
      _checkStudentBanStatus();
    }
  }

  // Öğrencinin sınıf duvarı ban kontrolü
  void _checkStudentBanStatus() async {
    var studentDoc = await _firestore
        .collection('students')
        .doc(widget.currentUserId)
        .get();
    if (!studentDoc.exists) return;

    var data = studentDoc.data() as Map<String, dynamic>;

    if (data.containsKey('chatBanUntil') && data['chatBanUntil'] != null) {
      Timestamp banTimestamp = data['chatBanUntil'];
      DateTime banDate = banTimestamp.toDate();

      if (DateTime.now().isBefore(banDate)) {
        List<String> months = [
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
        String formattedDate =
            "${banDate.day}-${months[banDate.month]}-${banDate.year}";
        String formattedTime =
            "${banDate.hour.toString().padLeft(2, '0')}:${banDate.minute.toString().padLeft(2, '0')}";

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Sınıf Duvarı Erişimi Kısıtlandı 🚫"),
              content: Text(
                "3 gün süreyle sohbet ve sınıf duvarı erişiminiz kapatıldı. Tekrar açılacağı tarih: $formattedDate, saat: $formattedTime",
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialogu kapat
                    Navigator.pop(context); // Sınıf duvarı ekranından çık
                  },
                  child: const Text("Tamam"),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  // Tarih ve Saat Oluşturucu Yardımcı Fonksiyonlar
  String _getFormattedDate() {
    DateTime now = DateTime.now();
    List<String> months = [
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
    return "${now.day}-${months[now.month]}-${now.year}";
  }

  String _getFormattedTime() {
    DateTime now = DateTime.now();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // Gönderi Paylaşma Fonksiyonu
  void _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    // Ekstra Güvenlik: Paylaş butonuna bastığı an ceza süresi bitmiş mi kontrol et
    if (!widget.isTeacher) {
      var studentDoc = await _firestore
          .collection('students')
          .doc(widget.currentUserId)
          .get();
      if (studentDoc.exists) {
        var data = studentDoc.data() as Map<String, dynamic>;
        if (data.containsKey('chatBanUntil') && data['chatBanUntil'] != null) {
          Timestamp banTimestamp = data['chatBanUntil'];
          if (DateTime.now().isBefore(banTimestamp.toDate())) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "3 günlük ceza süreniz devam ettiği için paylaşım yapamazsınız!",
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }
    }

    String text = _postController.text.trim();
    _postController.clear();

    await _firestore.collection('class_feed').add({
      'classId': widget.classId,
      'authorId': widget.currentUserId,
      'authorName': widget.currentUserName,
      'text': text,
      'createdAtField': FieldValue.serverTimestamp(),
      'formattedDate': _getFormattedDate(),
      'formattedTime': _getFormattedTime(),
    });
  }

  // Gönderi Silme ve Sarı Kart / Ban Mekanizması
  void _deletePost(String postId, String authorId, String authorName) async {
    var studentDoc = await _firestore
        .collection('students')
        .doc(authorId)
        .get();

    if (!studentDoc.exists) {
      await _firestore.collection('class_feed').doc(postId).delete();
      return;
    }

    var studentData = studentDoc.data() as Map<String, dynamic>;
    int currentCards = studentData['chatYellowCards'] ?? 0;

    String uyariMesaji = (currentCards == 2)
        ? "DİKKAT! Eğer bu gönderiyi silerseniz, öğrenci 3 gün süreyle sohbet modülüne giriş yapamayacak."
        : "Eğer bu gönderiyi silerseniz, öğrenciye 1 sarı kart verilecek.";

    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gönderiyi Sil ve Sarı Kart Ver ⚠️"),
        content: Text(uyariMesaji),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil ve Uygula"),
          ),
        ],
      ),
    );

    if (onay != true) return;

    int newCards = currentCards + 1;
    Map<String, dynamic> updateData = {
      'chatYellowCards': newCards,
      'hasUnseenPenalty': true,
    };

    if (newCards >= 3) {
      updateData['chatBanUntil'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      );
    }

    // 1. Öğrencinin sohbet/ban cezası verilerini güncelle
    await _firestore.collection('students').doc(authorId).update(updateData);

    // 2. DAVRANIŞ MODÜLÜNE Sarı Kartı İşle
    String classId = studentData['classId'] ?? '';
    if (classId.isNotEmpty) {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('davranislar')
          .doc(authorId)
          .set({'sariKart': FieldValue.increment(1)}, SetOptions(merge: true));
    }

    // 3. Gönderiyi sil
    await _firestore.collection('class_feed').doc(postId).delete();

    if (!context.mounted) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$authorName adlı öğrenciye 1 sarı kart eklendi."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} Sınıf Duvarı 🌸"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          // Yazı Yazma Alanı
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: "Sınıfa bir şeyler yaz...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                  ),
                  child: const Text(
                    "Paylaş",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Akış Listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('class_feed')
                  .where('classId', isEqualTo: widget.classId)
                  .orderBy('createdAtField', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Hata Oluştu: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz bir paylaşım yok. İlk yazıyı sen yaz! 😊",
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String postId = doc.id;
                    String authorId = data['authorId'] ?? '';
                    String authorName = data['authorName'] ?? 'İsimsiz';
                    String text = data['text'] ?? '';
                    String date = data['formattedDate'] ?? '';
                    String time = data['formattedTime'] ?? '';

                    List<String> authorizedRoles = [
                      'classroom_teacher',
                      'branch_teacher',
                      'english_teacher',
                      'religious_teacher',
                      'admin',
                      'guidance_teacher',
                      'special_education_teacher',
                      'kindergarten_teacher',
                    ];
                    bool canDelete = authorizedRoles.contains(
                      widget.userRole.trim().toLowerCase(),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _deletePost(
                                      postId,
                                      authorId,
                                      authorName,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(text, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "$date - $time",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
    );
  }
}
