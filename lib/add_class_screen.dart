// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedGrade = 'Özel Eğitim Sınıfı';
  String _selectedBranch = 'A';
  String _selectedRole = 'special_education_teacher';

  final List<String> _grades = [
    'Özel Eğitim Sınıfı',
    'Anasınıfı',
    '1',
    '2',
    '3',
    '4',
  ];
  final List<String> _branches = ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'I', 'J'];

  final Map<String, String> _roleMap = {
    'Sınıf Öğretmeni': 'classroom_teacher',
    'Branş Öğretmeni': 'branch_teacher',
    'İngilizce Öğretmeni': 'english_teacher',
    'Din Kültürü Öğretmeni': 'religious_teacher',
    'İdareci': 'admin',
    'Rehber Öğretmen': 'guidance_teacher',
    'Özel Eğitim Öğretmeni': 'special_education_teacher',
    'Ana Sınıfı Öğretmeni': 'kindergarten_teacher',
  };

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

  void _saveClass() async {
    if (_formKey.currentState!.validate()) {
      String teacherName = _teacherController.text.trim();
      String password = _passwordController.text.trim();

      String className = "";
      if (_selectedRole == 'admin') {
        className = "İdareci: $teacherName";
      } else if (_selectedRole == 'guidance_teacher') {
        className = "Rehber Öğretmen: $teacherName";
      } else if (_selectedRole == 'special_education_teacher') {
        className = "Özel Eğitim: $teacherName";
      } else if (_selectedRole == 'kindergarten_teacher') {
        className = "Ana Sınıfı: $teacherName";
      } else if (_selectedGrade == 'Özel Eğitim Sınıfı') {
        className = "Özel Eğitim: $teacherName";
      } else if (_selectedGrade == 'Anasınıfı') {
        className = "Ana Sınıfı: $_selectedBranch";
      } else {
        className = "$_selectedGrade/$_selectedBranch";
      }

      try {
        await FirebaseFirestore.instance.collection('classes').add({
          'className': className,
          'grade': _selectedGrade,
          'branch':
              (_selectedGrade == 'Özel Eğitim Sınıfı' ||
                  _selectedRole == 'special_education_teacher')
              ? ''
              : _selectedBranch,
          'teacherName': teacherName,
          'password': password,
          'userRole': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt başarıyla eklendi!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOzelEgitim =
        _selectedGrade == 'Özel Eğitim Sınıfı' ||
        _selectedRole == 'special_education_teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf ve Yetkili Ekle"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Rol / Görev Türü Seçimi
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Görev / Kullanıcı Türü",
                  border: OutlineInputBorder(),
                ),
                items: _roleMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    if (_selectedRole == 'special_education_teacher') {
                      _selectedGrade = 'Özel Eğitim Sınıfı';
                    } else if (_selectedRole == 'kindergarten_teacher') {
                      _selectedGrade = 'Anasınıfı';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Sınıf Seviyesi Seçimi (İdareci ve Rehber değilse göster)
              if (_selectedRole != 'admin' &&
                  _selectedRole != 'guidance_teacher') ...[
                DropdownButtonFormField<String>(
                  initialValue: _grades.contains(_selectedGrade)
                      ? _selectedGrade
                      : _grades.first,
                  decoration: const InputDecoration(
                    labelText: "Sınıf Seviyesi",
                    border: OutlineInputBorder(),
                  ),
                  items: _grades.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(
                        grade == '1' ||
                                grade == '2' ||
                                grade == '3' ||
                                grade == '4'
                            ? "$grade. Sınıf"
                            : grade,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value!;
                      if (_selectedGrade == 'Özel Eğitim Sınıfı') {
                        _selectedRole = 'special_education_teacher';
                      } else if (_selectedGrade == 'Anasınıfı') {
                        _selectedRole = 'kindergarten_teacher';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Şube Seçimi (Özel Eğitim seçildiyse gizlenir, Anasınıfı ve diğerlerinde açık kalır)
              if (!isOzelEgitim &&
                  _selectedRole != 'admin' &&
                  _selectedRole != 'guidance_teacher') ...[
                DropdownButtonFormField<String>(
                  initialValue: _branches.contains(_selectedBranch)
                      ? _selectedBranch
                      : _branches.first,
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
                      _selectedBranch = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Ad Soyad Alanı
              TextFormField(
                controller: _teacherController,
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
                  labelText: "Adı Soyadı",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Lütfen ad soyad giriniz" : null,
              ),
              const SizedBox(height: 16),

              // Şifre Alanı
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Giriş Şifresi",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Lütfen şifre giriniz" : null,
              ),
              const SizedBox(height: 24),

              // Kaydet Butonu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveClass,
                child: const Text(
                  "Kaydet ve Oluştur",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
