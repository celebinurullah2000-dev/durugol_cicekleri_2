// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentScreen extends StatefulWidget {
  final String userRole;
  final String currentClassId;

  const AddStudentScreen({
    super.key,
    this.userRole = 'classroom_teacher',
    this.currentClassId = '',
  });

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  String? _selectedGender; // Seçilen cinsiyet ('K' veya 'E')

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  bool get _isAnasinifiOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'kindergarten_teacher';

  bool get _isOzelEgitimOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'special_education_teacher';

  @override
  void initState() {
    super.initState();
    if (_isSinifOgretmeni && widget.currentClassId.isNotEmpty) {
      _selectedClassId = widget.currentClassId;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Öğrenci Kaydı")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SINIF SEÇİMİ (Role göre kilitli veya filtrelenmiş)
            _isSinifOgretmeni
                ? FutureBuilder<DocumentSnapshot>(
                    future: widget.currentClassId.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.currentClassId)
                              .get()
                        : null,
                    builder: (context, snapshot) {
                      String className = "Yükleniyor...";
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          className =
                              data?['className'] ?? widget.currentClassId;
                        } else {
                          className = "Sınıf Bilgisi Bulunamadı";
                        }
                      }

                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Sınıf",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey,
                        ),
                        child: Text(
                          className,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var allDocs = snapshot.data!.docs;
                      var classList = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String className = (data['className'] ?? '')
                            .toLowerCase();
                        String grade = (data['grade'] ?? '').toLowerCase();
                        String role = (data['userRole'] ?? '').toLowerCase();

                        if (_isAnasinifiOgretmeni) {
                          // Ana sınıfı rolüne sahip veya adı ana sınıfı içeren kayıtlar
                          return role == 'kindergarten_teacher' ||
                              className.contains('ana sınıfı') ||
                              className.contains('anasınıfı') ||
                              grade.contains('ana sınıfı');
                        } else if (_isOzelEgitimOgretmeni) {
                          // Özel eğitim rolüne sahip veya adı özel eğitim içeren kayıtlar
                          return role == 'special_education_teacher' ||
                              className.contains('özel eğitim') ||
                              grade.contains('özel eğitim');
                        } else {
                          // Admin veya diğer yetkililer tüm sınıfları görebilir
                          return true;
                        }
                      }).toList();

                      if (classList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Kayıtlı uygun sınıf bulunamadı.",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Sınıf Seçin",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedClassId,
                        items: classList.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['className'] ?? 'Sınıf'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedClassId = val),
                        validator: (val) =>
                            val == null ? "Sınıf seçmelisiniz" : null,
                      );
                    },
                  ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "Öğrenci Adı"),
              validator: (val) => val!.isEmpty ? "Lütfen ad girin" : null,
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Öğrenci Soyadı"),
              validator: (val) => val!.isEmpty ? "Lütfen soyad girin" : null,
            ),

            // CİNSİYET SEÇİMİ
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Cinsiyet"),
              initialValue: _selectedGender,
              items: const [
                DropdownMenuItem(value: 'K', child: Text("Kız")),
                DropdownMenuItem(value: 'E', child: Text("Erkek")),
              ],
              onChanged: (val) => setState(() => _selectedGender = val),
              validator: (val) => val == null ? "Lütfen cinsiyet seçin" : null,
            ),

            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: "Okul Numarası"),
              validator: (val) =>
                  val!.isEmpty ? "Lütfen okul numarası girin" : null,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Öğrenci Şifresi"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _selectedClassId != null &&
                    _selectedGender != null) {
                  final navigator = Navigator.of(context);

                  await FirebaseFirestore.instance.collection('students').add({
                    'firstName': _firstNameController.text.trim(),
                    'lastName': _lastNameController.text.trim(),
                    'classId': _selectedClassId,
                    'gender': _selectedGender,
                    'schoolNumber': _numberController.text.trim(),
                    'password': _passwordController.text.trim(),
                    'createdAt': DateTime.now(),
                    'hasBeenOnDuty': false,
                  });

                  navigator.pop();
                }
              },
              child: const Text("Öğrenciyi Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
