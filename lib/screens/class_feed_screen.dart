// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassFeedScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final bool isTeacher; // Öğretmen mi öğrenci mi olduğunu anlamak için
  final String classId; // Hangi sınıfın duvarı?
  final String className; // Başlıkta yazacak sınıf adı (Örn: 4/C)

  const ClassFeedScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.isTeacher,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassFeedScreen> createState() => _ClassFeedScreenState();
}

class _ClassFeedScreenState extends State<ClassFeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Gönderi Silme (Öğretmen veya Kendi Gönderisi)
  void _deletePost(String postId) async {
    await _firestore.collection('class_feed').doc(postId).delete();
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

                    // Silme yetkisi: Öğretmense veya kendi postuysa silebilir
                    bool canDelete =
                        widget.isTeacher || (widget.currentUserId == authorId);

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
                                    onPressed: () => _deletePost(postId),
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
