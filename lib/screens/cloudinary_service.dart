import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // ⚙️ إعدادات Cloudinary (يجب تعديلها)
  // 1. اذهب إلى https://cloudinary.com/console
  // 2. انسخ Cloud Name وضعه هنا
  static const String cloudName = 'dxmpn8l9f';

  // 3. اذهب إلى Settings -> Upload -> Upload presets
  // 4. أنشئ Preset جديد وتأكد أن الـ Signing Mode هو "Unsigned"
  // 5. انسخ اسم الـ Preset وضعه هنا
  static const String uploadPreset = 'app_upload';

  Future<String?> pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      // اختيار الصورة من المعرض
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      // الرفع إلى Cloudinary
      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;

      // استخدام bytes لدعم الويب والموبايل معاً
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // الرابط المباشر للصورة
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }
}
