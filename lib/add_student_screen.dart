// ignore_for_file: use_build_context_synchronously

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

  @override
  void initState() {
    super.initState();
    // Eğer sınıf öğretmeniyse, sınıf ID'sini doğrudan sabitleyelim
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
            // SINIF SEÇİMİ (Sınıf öğretmenine kilitli, idareciye seçilebilir)
            _isSinifOgretmeni
                ? FutureBuilder<DocumentSnapshot>(
                    future: widget.currentClassId.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.currentClassId)
                              .get()
                        : null,
                    builder: (context, snapshot) {
                      // Veri yüklenirken veya id boşsa geçici olarak yükleniyor veya boş gösterelim
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
                          fillColor: Colors
                              .grey, // Kilitli olduğunu belirten gri arka plan
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
                        return const CircularProgressIndicator();
                      }

                      var classList = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Sınıf Seçin",
                        ),
                        initialValue: _selectedClassId,
                        items: classList.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['className']),
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

            // CİNSİYET SEÇİMİ (Nöbetçi algoritması için şart)
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
