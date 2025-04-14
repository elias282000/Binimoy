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

  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images',
          publicId: userId, // Use userId as publicId for easy updates
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw 'Failed to upload profile image';
    }
  }
}