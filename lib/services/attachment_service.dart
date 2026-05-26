import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AttachmentService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
    return null;
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
    return null;
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    List<File> images = [];
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      for (var file in pickedFiles) {
        images.add(File(file.path));
      }
    } catch (e) {
      print('Error picking multiple images: $e');
    }
    return images;
  }

  // Save image to app's local directory
  Future<String?> saveImageToAppDirectory(File image, String transactionId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      // Create attachments directory if it doesn't exist
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }
      
      // Create transaction-specific directory
      final transactionDir = Directory('${attachmentsDir.path}/$transactionId');
      if (!await transactionDir.exists()) {
        await transactionDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);
      final newPath = '${transactionDir.path}/img_$timestamp$extension';
      
      // Copy image to new location
      final savedImage = await image.copy(newPath);
      return savedImage.path;
      
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Delete image file
  Future<void> deleteImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Get all attachments for a transaction
  Future<List<File>> getAttachmentsForTransaction(String transactionId) async {
    List<File> attachments = [];
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final transactionDir = Directory('${appDir.path}/attachments/$transactionId');
      
      if (await transactionDir.exists()) {
        final files = transactionDir.listSync();
        for (var file in files) {
          if (file is File) {
            attachments.add(file);
          }
        }
      }
    } catch (e) {
      print('Error getting attachments: $e');
    }
    return attachments;
  }
}