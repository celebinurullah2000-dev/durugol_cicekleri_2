import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Galeriden resim seç
  Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  // Kameradan fotoğraf çek
  Future<XFile?> captureWithCamera() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }
}
