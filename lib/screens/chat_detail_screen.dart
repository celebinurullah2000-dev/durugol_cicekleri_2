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

  @override
  void initState() {
    super.initState();
    // Eğer giren kişi öğrenci ise ban ve ceza kontrollerini yap
    if (!widget.isTeacher) {
      _checkStudentPenalties();
    }
  }

  // Öğrencinin ban ve sarı kart ceza kontrolleri
  void _checkStudentPenalties() async {
    var studentDoc = await _firestore
        .collection('students')
        .doc(widget.currentUserId)
        .get();
    if (!studentDoc.exists) return;

    var data = studentDoc.data() as Map<String, dynamic>;

    // 1. 3 Günlük Sohbet Banı Kontrolü
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
              title: const Text("Sohbet Erişimi Kısıtlandı 🚫"),
              content: Text(
                "3 gün süreyle sohbet erişiminiz kapatıldı. tekrar açılacağı tarih: $formattedDate, saat: $formattedTime",
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialogu kapat
                    Navigator.pop(context); // Sohbet detay ekranından çık
                  },
                  child: const Text("Tamam"),
                ),
              ],
            ),
          );
        });
        return;
      }
    }

    // 2. Yeni Sarı Kart Bildirim Kontrolü
    if (data['hasUnseenPenalty'] == true) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sarı Kart Bildirimi ⚠️"),
            content: const Text(
              "Öğretmen bir mesajını sildiği için, 1 sarı kart cezası aldın.",
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Uyarının tekrar gösterilmemesi için bayrağı false yap
                  await _firestore
                      .collection('students')
                      .doc(widget.currentUserId)
                      .update({'hasUnseenPenalty': false});
                },
                child: const Text("Tamam"),
              ),
            ],
          ),
        );
      });
    }
  }

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

  // Mesaj Silme ve Sarı Kart / Ban Mekanizması
  void _deleteMessage(
    String messageId,
    String senderId,
    String senderName,
  ) async {
    var studentDoc = await _firestore
        .collection('students')
        .doc(senderId)
        .get();

    if (!studentDoc.exists) {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return;
    }

    var studentData = studentDoc.data() as Map<String, dynamic>;
    int currentCards = studentData['chatYellowCards'] ?? 0;

    String uyariMesaji = (currentCards == 2)
        ? "DİKKAT! Eğer bu mesajı silerseniz, öğrenci 3 gün süreyle sohbet modülüne giriş yapamayacak."
        : "Eğer bu mesajı silerseniz, öğrenciye 1 sarı kart verilecek.";

    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mesajı Sil ve Sarı Kart Ver ⚠️"),
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
    await _firestore.collection('students').doc(senderId).update(updateData);

    // 2. DAVRANIŞ MODÜLÜNE (OgrenciDavranisScreen'e) Sarı Kartı İşle
    String classId = studentData['classId'] ?? '';
    if (classId.isNotEmpty) {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('davranislar')
          .doc(senderId)
          .set({'sariKart': FieldValue.increment(1)}, SetOptions(merge: true));
    }

    // 3. Mesajı sohbetten sil
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$senderName adlı öğrenciye 1 sarı kart eklendi."),
        backgroundColor: Colors.orange,
      ),
    );
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
              Navigator.pop(context);

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
                                        onTap: () => _deleteMessage(
                                          messageId,
                                          senderId,
                                          senderName,
                                        ),
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
