import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Centralized media selection with Android activity-recreation recovery.
///
/// On Android the OS may destroy the Flutter activity while the system photo
/// picker is open, especially on devices with limited memory. The result must
/// be recovered with retrieveLostData when the app is recreated.
class BinerMediaEditor {
  static final ImagePicker _picker = ImagePicker();
  static XFile? _recoveredFile;

  static Future<void> recoverLostData() async {
    if (!Platform.isAndroid) return;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        _recoveredFile = files.first;
      }
    } on PlatformException {
      // Some OEM gallery implementations do not support lost-data recovery.
      // Keep startup reliable; the user can retry selecting media.
    } on MissingPluginException {
      // Defensive fallback for partially initialized plugin registrants.
    }
  }

  static Future<XFile?> pickMedia() async {
    final recovered = _takeRecoveredFile();
    if (recovered != null) return recovered;

    try {
      return await _picker.pickMedia(imageQuality: 85);
    } on PlatformException catch (error) {
      if (_isCancellation(error)) return null;
      rethrow;
    } on MissingPluginException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static Future<XFile?> pickImage() async {
    final recovered = _takeRecoveredFile();
    if (recovered != null) return recovered;

    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } on PlatformException catch (error) {
      if (_isCancellation(error)) return null;
      rethrow;
    } on MissingPluginException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static XFile? _takeRecoveredFile() {
    final file = _recoveredFile;
    _recoveredFile = null;
    return file;
  }

  static bool _isCancellation(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('cancel') || code == 'photo_access_denied';
  }
}
