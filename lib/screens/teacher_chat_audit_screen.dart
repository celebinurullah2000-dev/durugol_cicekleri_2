// ignore_for_file: use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class TeacherChatAuditScreen extends StatelessWidget {
  final String classId;
  final String currentUserId;
  final String currentUserName;

  const TeacherChatAuditScreen({
    Key? key,
    required this.classId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tüm Sınıf Sohbetleri (Denetim) 👁️"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sınıftaki tüm sohbetleri çekiyoruz (öğretmenin dahil olduğu veya tüm sınıf sohbetleri)
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('classId', isEqualTo: classId)
            //.orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Öğretmen bu sohbetin içine girip tüm mesajları okuyabilir ve silebilir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatId: chatId,
                          chatTitle: title,
                          currentUserId: currentUserId,
                          currentUserName: currentUserName,
                          isTeacher:
                              true, // Öğretmen yetkisiyle girer (istediği mesajı silebilir)
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
