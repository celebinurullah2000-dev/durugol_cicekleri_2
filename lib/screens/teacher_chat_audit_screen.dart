// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class TeacherChatAuditScreen extends StatelessWidget {
  final String classId;
  final String currentUserId;
  final String currentUserName;
  final String userRole;

  const TeacherChatAuditScreen({
    Key? key,
    required this.classId,
    required this.currentUserId,
    required this.currentUserName,
    this.userRole = 'admin',
  }) : super(key: key);

  void _deleteChat(BuildContext context, String chatId, String chatTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sohbeti Sil 🗑️"),
        content: Text(
          "'$chatTitle' sohbetini ve tüm mesajları herkes için silmek istediğinize emin misiniz?",
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

              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .delete();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sohbet herkes için silindi."),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tüm Sınıf Sohbetleri (Denetim) 👁️"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('classId', isEqualTo: classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "Bu sınıfa ait sohbet bulunamadı.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];
              var data = chat.data() as Map<String, dynamic>;
              String chatId = chat.id;
              bool isGroup = data['isGroup'] ?? false;
              String title = isGroup
                  ? (data['groupName'] ?? 'Grup Sohbeti')
                  : (data['chatTitle'] ?? 'Bireysel Sohbet');
              String lastMessage = data['lastMessage'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Sohbeti Herkes İçin Sil",
                        onPressed: () => _deleteChat(context, chatId, title),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
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
                          isTeacher: true,
                          userRole: userRole,
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
    );
  }
}
