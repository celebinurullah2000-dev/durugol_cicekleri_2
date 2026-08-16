// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  final String userRole;

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.studentId,
    this.userRole = 'classroom_teacher',
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final TextEditingController _tcController;
  late final TextEditingController _dogumTarihiController;
  late final TextEditingController _anneAdiController;
  late final TextEditingController _babaAdiController;
  late final TextEditingController _anneCepController;
  late final TextEditingController _babaCepController;
  late final TextEditingController _anneMeslegiController;
  late final TextEditingController _babaMeslegiController;
  late final TextEditingController _kardesleriController;

  String? ogrenciProfilResmiUrl;
  bool _isSaving = false;

  // Sadece sınıf öğretmeninin düzenleme ve kaydetme yetkisi vardır
  bool get _isSinifOgretmeni =>
      widget.userRole.trim().toLowerCase() == 'classroom_teacher';

  @override
  void initState() {
    super.initState();
    _tcController = TextEditingController(text: widget.studentData['tc'] ?? '');
    _dogumTarihiController = TextEditingController(
      text: widget.studentData['dogumTarihi'] ?? '',
    );
    _anneAdiController = TextEditingController(
      text: widget.studentData['anneAdi'] ?? '',
    );
    _babaAdiController = TextEditingController(
      text: widget.studentData['babaAdi'] ?? '',
    );
    _anneCepController = TextEditingController(
      text: widget.studentData['anneCep'] ?? '',
    );
    _babaCepController = TextEditingController(
      text: widget.studentData['babaCep'] ?? '',
    );
    _anneMeslegiController = TextEditingController(
      text: widget.studentData['anneMeslegi'] ?? '',
    );
    _babaMeslegiController = TextEditingController(
      text: widget.studentData['babaMeslegi'] ?? '',
    );
    _kardesleriController = TextEditingController(
      text: widget.studentData['kardesleri'] ?? '',
    );

    ogrenciProfilResmiUrl =
        widget.studentData['profileImageUrl'] ??
        widget.studentData['resimBase64'];
  }

  @override
  void dispose() {
    _tcController.dispose();
    _dogumTarihiController.dispose();
    _anneAdiController.dispose();
    _babaAdiController.dispose();
    _anneCepController.dispose();
    _babaCepController.dispose();
    _anneMeslegiController.dispose();
    _babaMeslegiController.dispose();
    _kardesleriController.dispose();
    super.dispose();
  }

  // --- ÖĞRENCİ BİLGİLERİNİ GÜNCELLEME VE KAYDETME FONKSİYONU ---
  Future<void> _bilgileriKaydet() async {
    if (!_isSinifOgretmeni) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({
            'tc': _tcController.text.trim(),
            'dogumTarihi': _dogumTarihiController.text.trim(),
            'anneAdi': _anneAdiController.text.trim(),
            'babaAdi': _babaAdiController.text.trim(),
            'anneCep': _anneCepController.text.trim(),
            'babaCep': _babaCepController.text.trim(),
            'anneMeslegi': _anneMeslegiController.text.trim(),
            'babaMeslegi': _babaMeslegiController.text.trim(),
            'kardesleri': _kardesleriController.text.trim(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Öğrenci bilgileri başarıyla güncellendi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Güncelleme sırasında hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resmiTamBoyutGoster() {
    if (ogrenciProfilResmiUrl == null || ogrenciProfilResmiUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ogrenciProfilResmiUrl!.startsWith('http')
                      ? Image.network(
                          ogrenciProfilResmiUrl!,
                          fit: BoxFit.contain,
                        )
                      : Image.memory(
                          base64Decode(ogrenciProfilResmiUrl!),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        "${widget.studentData['firstName'] ?? ''} ${widget.studentData['lastName'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: Text("$fullName - Öğrenci Bilgileri"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- PROFİL FOTOĞRAFI ALANI ---
            Center(
              child: GestureDetector(
                onTap: _resmiTamBoyutGoster,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo.shade100,
                  backgroundImage:
                      (ogrenciProfilResmiUrl != null &&
                          ogrenciProfilResmiUrl!.isNotEmpty)
                      ? (ogrenciProfilResmiUrl!.startsWith('http')
                            ? NetworkImage(ogrenciProfilResmiUrl!)
                                  as ImageProvider
                            : MemoryImage(base64Decode(ogrenciProfilResmiUrl!)))
                      : null,
                  child:
                      (ogrenciProfilResmiUrl == null ||
                          ogrenciProfilResmiUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.indigo)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- BİLGİ ALANLARI (Sınıf öğretmenine düzenlenebilir, diğerlerine readOnly) ---
            TextField(
              controller: _tcController,
              readOnly:
                  !_isSinifOgretmeni, // Sadece sınıf öğretmeni değiştirebilir
              decoration: const InputDecoration(labelText: "T.C. Kimlik No"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dogumTarihiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Doğum Tarihi"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneAdiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaAdiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneCepController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaCepController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneMeslegiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Anne Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaMeslegiController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Baba Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kardesleriController,
              readOnly: !_isSinifOgretmeni,
              decoration: const InputDecoration(labelText: "Kardeşleri"),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            // --- SADECE SINIF ÖĞRETMENLERİ İÇİN KAYDET BUTONU ---
            if (_isSinifOgretmeni)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _bilgileriKaydet,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Değişiklikleri Kaydet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
