// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_class_screen.dart';
import 'Ogretmen_Ana_Sayfasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class sinifseceklescreen extends StatefulWidget {
  const sinifseceklescreen({super.key});

  @override
  State<sinifseceklescreen> createState() => _sinifseceklescreenState();
}

class _sinifseceklescreenState extends State<sinifseceklescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıflarım"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole'); // Oturumu sil

              if (!mounted) return;
              // Giriş ekranına dön
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz sınıf eklenmemiş."));
          }

          var classes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var classData = classes[index].data() as Map<String, dynamic>;
              String className = classData['className'] ?? 'Sınıf';
              String teacherName = classData['teacherName'] ?? 'Belirtilmemiş';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 30, // Daireyi biraz genişletebiliriz
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      className, // Doğrudan "4/C" yazar
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 14, // Yazı sığması için 14-16 arası idealdir
                      ),
                    ),
                  ),
                  title: Text(
                    className,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text("Öğretmen: $teacherName"),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    var classId = classes[index].id;
                    var classData =
                        classes[index].data() as Map<String, dynamic>;
                    String correctPassword = classData['password'] ?? '';
                    String className = classData['className'] ?? 'Sınıf';

                    // Şifre sorma dialogunu aç
                    TextEditingController passwordInputController =
                        TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("$className Sınıfı Şifresi"),
                        content: TextField(
                          controller: passwordInputController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Şifreyi Girin",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context), // İptal
                            child: const Text("İptal"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              String enteredPassword = passwordInputController
                                  .text
                                  .trim();

                              if (enteredPassword == correctPassword) {
                                Navigator.pop(
                                  context,
                                ); // Şifre penceresini kapat

                                // Doğruysa sınıfa giriş yap
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OgretmenAnaSayfasi(
                                      classId: classId,
                                      className: className,
                                    ),
                                  ),
                                );
                              } else {
                                // Yanlışsa hata göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Hatalı şifre! Lütfen tekrar deneyin.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text("Giriş Yap"),
                          ),
                        ],
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
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddClassScreen()),
          );
        },
      ),
    );
  }
}
