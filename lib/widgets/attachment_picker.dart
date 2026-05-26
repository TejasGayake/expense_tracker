import 'package:flutter/material.dart';
import 'dart:io';
import '../services/attachment_service.dart';

class AttachmentPicker extends StatefulWidget {
  final Function(List<File>) onImagesPicked;
  final String transactionId;

  const AttachmentPicker({
    super.key,
    required this.onImagesPicked,
    required this.transactionId,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  final AttachmentService _attachmentService = AttachmentService();
  List<File> _selectedImages = [];

  Future<void> _pickFromCamera() async {
    final image = await _attachmentService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      widget.onImagesPicked(_selectedImages);
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _attachmentService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      widget.onImagesPicked(_selectedImages);
    }
  }

  Future<void> _pickMultiple() async {
    final images = await _attachmentService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
      widget.onImagesPicked(_selectedImages);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesPicked(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected images preview
        if (_selectedImages.isNotEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Add buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: _pickFromCamera,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickFromGallery,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.collections,
                label: 'Multiple',
                onTap: _pickMultiple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}