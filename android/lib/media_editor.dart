import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class BinerMediaEditor {
  static Future<XFile?> pickMedia() async {
    final selected = await ImagePicker().pickMedia(imageQuality: 94);
    if (selected == null) return null;
    final mime = selected.mimeType ?? '';
    final name = selected.name.toLowerCase();
    final isImage = mime.startsWith('image/') ||
        name.endsWith('.jpg') || name.endsWith('.jpeg') ||
        name.endsWith('.png') || name.endsWith('.webp') ||
        name.endsWith('.heic');
    if (!isImage) return selected;
    final cropped = await ImageCropper().cropImage(
      sourcePath: selected.path,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit image',
          toolbarColor: const Color(0xFF54C8FF),
          activeControlsWidgetColor: const Color(0xFF54C8FF),
          statusBarColor: const Color(0xFF080B12),
          backgroundColor: const Color(0xFF080B12),
          lockAspectRatio: false,
        ),
      ],
    );
    if (cropped == null) return null;
    return XFile(cropped.path, name: selected.name, mimeType: mime.isEmpty ? null : mime);
  }
}
