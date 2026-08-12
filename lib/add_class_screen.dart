import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

final TextEditingController _passwordController = TextEditingController();

class _AddClassScreenState extends State<AddClassScreen> {
  // Seçilen sınıf seviyesi (1 ile 4 arası)
  String? _selectedGrade = '1';

  // Seçilen şube (Ğ harfi hariç A-I arası)
  String? _selectedBranch = 'A';

  // Öğretmen adı için controller
  final TextEditingController _teacherNameController = TextEditingController();

  // Şube listesi (Ğ hariç A'dan I'ya toplam 10 şube)
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
      appBar: AppBar(title: const Text("Sınıf Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sınıf Seviyesi Dropdown (1'den 4'e)
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

            // 2. Şube Dropdown (A'dan I'ya, Ğ hariç)
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

            // 3. Öğretmen Adı Yazma Kutusu (Otomatik baş harf büyütme özellikli)
            TextField(
              controller: _teacherNameController,
              textCapitalization: TextCapitalization
                  .words, // Klavyede de kelime başlarını büyük yapar
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: _capitalizeWords(newValue.text),
                    selection: newValue.selection,
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: "Öğretmen Adı Soyadı",
                border: OutlineInputBorder(),
                hintText: "Örn: Ahmet Yılmaz",
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true, // Şifrenin görünmemesi için
              decoration: const InputDecoration(
                labelText: "Sınıf Şifresi",
                border: OutlineInputBorder(),
                hintText: "Sınıf için bir şifre belirleyin",
              ),
            ),
            const SizedBox(height: 24),

            // Kaydet Butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                // Sınıf adını otomatik birleştiriyoruz (Örn: "3/A")
                String finalClassName = "$_selectedGrade/$_selectedBranch";
                String teacherName = _teacherNameController.text.trim();

                if (teacherName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lütfen öğretmen adını giriniz."),
                    ),
                  );
                  return;
                }

                // 1. İşlem başlamadan önce referansı kaydet
                final navigator = Navigator.of(context);

                // 2. Firestore'a sınıfı ve öğretmen adını kaydet
                await FirebaseFirestore.instance.collection('classes').add({
                  'className': finalClassName, // Örn: "3/A"
                  'grade': _selectedGrade,
                  'branch': _selectedBranch,
                  'teacherName': teacherName,
                  'password': _passwordController.text.trim(),
                  'teacherId': 'current_teacher_id',
                });

                // 3. Kaydedilen referansı güvenle kullan
                navigator.pop();
              },
              child: const Text(
                "Sınıfı Kaydet",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
