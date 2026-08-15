// ignore_for_file: use_build_context_synchronously, camel_case_types

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  // Seçilen sınıf seviyesi (1 ile 4 arası)
  String? _selectedGrade = '1';

  // Seçilen şube (Ğ harfi hariç A-I arası)
  String? _selectedBranch = 'A';

  // Yeni eklenen: Kullanıcı / Öğretmen Rolü ('classroom_teacher', 'branch_teacher', 'admin')
  String _selectedRole = 'classroom_teacher';

  // Controller'lar
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Şube listesi (Ğ hariç A'dan J'ye kadar)
  final List<String> _branches = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
  ];

  @override
  void dispose() {
    _teacherNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Her kelimenin ilk harfini büyük, diğerlerini küçük yapan formatlayıcı
  String _capitalizeWords(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sınıf ve Yetkili Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. Yeni Eklenen: Kullanıcı / Öğretmen Türü Seçimi
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Kullanıcı / Görev Türü",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'classroom_teacher',
                  child: Text("Sınıf Öğretmeni (Tek Sınıf)"),
                ),
                DropdownMenuItem(
                  value: 'branch_teacher',
                  child: Text("Branş Öğretmeni (Çoklu Sınıf Seçebilir)"),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text("İdareci (Tüm Sınıfları Görür)"),
                ),
                DropdownMenuItem(
                  value: 'guidance_teacher',
                  child: Text('Rehber Öğretmen'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // SADECE SINIF ÖĞRETMENİ SEÇİLDİĞİNDE SINIF VE ŞUBE DROPDOWN'LARINI GÖSTER
            if (_selectedRole == 'classroom_teacher') ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: "Sınıf Seviyesi",
                  border: OutlineInputBorder(),
                ),
                items: ['1', '2', '3', '4'].map((grade) {
                  return DropdownMenuItem(
                    value: grade,
                    child: Text("$grade. Sınıf"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. Şube Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                decoration: const InputDecoration(
                  labelText: "Şube Seçimi",
                  border: OutlineInputBorder(),
                ),
                items: _branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch,
                    child: Text("$branch Şubesi"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBranch = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            // 3. Öğretmen / Kullanıcı Adı Yazma Kutusu
            TextField(
              controller: _teacherNameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: _capitalizeWords(newValue.text),
                    selection: newValue.selection,
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: "Öğretmen / Yetkili Adı Soyadı",
                border: OutlineInputBorder(),
                hintText: "Örn: Ahmet Yılmaz",
              ),
            ),
            const SizedBox(height: 16),

            // 4. Şifre Kutusu
            TextField(
              controller: _passwordController,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: "Giriş Şifresi",
                border: OutlineInputBorder(),
                hintText: "Kullanıcı için bir şifre belirleyin",
              ),
            ),
            const SizedBox(height: 24),

            // Kaydet Butonu
            SizedBox(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  String teacherName = _teacherNameController.text.trim();

                  if (teacherName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lütfen öğretmen/yetkili adını giriniz."),
                      ),
                    );
                    return;
                  }

                  String finalClassName;

                  // 1. İdareci, Branş Öğretmeni ve Rehber Öğretmen için sınıf çakışması aranmaz
                  if (_selectedRole == 'admin') {
                    finalClassName = "İdareci: $teacherName";
                  } else if (_selectedRole == 'branch_teacher') {
                    finalClassName = "Branş Öğretmeni: $teacherName";
                  } else if (_selectedRole == 'guidance_teacher') {
                    finalClassName = "Rehber Öğretmen: $teacherName";
                  } else {
                    // Sadece Sınıf Öğretmeni (classroom_teacher) için sınıf/şube çakışması kontrol edilir
                    finalClassName = "$_selectedGrade/$_selectedBranch";

                    var existingClassQuery = await FirebaseFirestore.instance
                        .collection('classes')
                        .where('className', isEqualTo: finalClassName)
                        .get();

                    if (!context.mounted) return;

                    if (existingClassQuery.docs.isNotEmpty) {
                      bool? devamEtsinMi = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Sınıf Zaten Mevcut"),
                          content: Text(
                            "$finalClassName sınıfı daha önce eklenmiş.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("İptal"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Eminiz / Ekle"),
                            ),
                          ],
                        ),
                      );
                      if (devamEtsinMi != true) return;
                    }
                  }

                  final navigator = Navigator.of(context);

                  await FirebaseFirestore.instance.collection('classes').add({
                    'className': finalClassName,
                    'grade': _selectedRole == 'classroom_teacher'
                        ? _selectedGrade
                        : '',
                    'branch': _selectedRole == 'classroom_teacher'
                        ? _selectedBranch
                        : '',
                    'teacherName': teacherName,
                    'password': _passwordController.text.trim(),
                    'userRole': _selectedRole,
                    'assignedClassIds': [],
                  });

                  navigator.pop();
                },
                child: const Text(
                  "Sınıfı ve Yetkiliyi Kaydet",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
