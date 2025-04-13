import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  final cloudinary = CloudinaryPublic('dwdtzllyy', 'Binimoy_saree_image', cache: false);

  Future<String> uploadImage(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'saree_images',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw 'Failed to upload image';
    }
  }
}