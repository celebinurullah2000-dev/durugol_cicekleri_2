// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final String currentUserId;
  final String currentUserName;
  final bool isTeacher;
  final String userRole;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.chatTitle,
    required this.currentUserId,
    required this.currentUserName,
    required this.isTeacher,
    this.userRole = 'classroom_teacher',
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text.trim();
    _messageController.clear();

    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'senderId': widget.currentUserId,
          'senderName': widget.currentUserName,
          'text': text,
          'createdAtField': FieldValue.serverTimestamp(),
          'formattedDate': _getFormattedDate(),
          'formattedTime': _getFormattedTime(),
        });

    await _firestore.collection('chats').doc(widget.chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  void _deleteMessage(String messageId) async {
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // GRUPTAN AYRILMA FONKSİYONU
  void _gruptanAyril(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gruptan Ayrıl"),
        content: const Text(
          "Bu gruptan ayrılmak istediğinize emin misiniz? Artık bu gruptaki mesajları göremeyeceksiniz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Dialogu kapat

              // Firestore'da participants dizisinden mevcut kullanıcıyı çıkar
              await _firestore.collection('chats').doc(widget.chatId).update({
                'participants': FieldValue.arrayRemove([widget.currentUserId]),
              });

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Gruptan başarıyla ayrıldınız."),
                  backgroundColor: Colors.orange,
                ),
              );

              // Sohbet detay ekranından çıkıp ana sohbet listesine dön
              Navigator.pop(context);
            },
            child: const Text("Ayrıl"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(widget.chatId).snapshots(),
      builder: (context, chatSnapshot) {
        bool isGroup = false;
        if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
          var data = chatSnapshot.data!.data() as Map<String, dynamic>;
          isGroup = data['isGroup'] ?? false;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.chatTitle),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              // Eğer bu bir grup sohbetiyse ve kullanıcı öğrenci ise gruptan ayrıl butonu göster
              if (isGroup && !widget.isTeacher)
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  tooltip: "Gruptan Ayrıl",
                  onPressed: () => _gruptanAyril(context),
                ),
            ],
          ),
          body: Column(
            children: [
              // --- GRUP ÜYELERİ BİLGİ ÇUBUĞU ---
              if (chatSnapshot.hasData && chatSnapshot.data!.exists)
                (() {
                  var chatData =
                      chatSnapshot.data!.data() as Map<String, dynamic>;
                  if (!(chatData['isGroup'] ?? false)) {
                    return const SizedBox.shrink();
                  }

                  List<dynamic> participants = chatData['participants'] ?? [];

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
                      if (!studentSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      var studentDocs = studentSnapshot.data!.docs;
                      List<String> names = studentDocs.map((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        return "${d['firstName'] ?? ''} ${d['lastName'] ?? ''}"
                            .trim();
                      }).toList();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.orange.shade50,
                        child: Text(
                          "Grup Üyeleri: ${names.join(', ')}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  );
                })(),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('createdAtField', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("Henüz mesaj yok. İlk mesajı sen yaz! 🌸"),
                      );
                    }

                    var docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        String messageId = doc.id;
                        String senderId = data['senderId'] ?? '';
                        String senderName = data['senderName'] ?? 'Biri';
                        String text = data['text'] ?? '';
                        String date = data['formattedDate'] ?? '';
                        String time = data['formattedTime'] ?? '';

                        bool isMe = senderId == widget.currentUserId;
                        bool canDelete =
                            (widget.userRole == 'classroom_teacher');

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.indigo.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      senderName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (canDelete) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _deleteMessage(messageId),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$date - $time",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
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
              ),

              // Alt Mesaj Yazma Çubuğu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Mesaj yaz...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.indigo),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
