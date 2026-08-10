import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';

// flutter_image_compress is not supported on web — conditional import
import 'package:flutter_image_compress/flutter_image_compress.dart'
    if (dart.library.html) '../utils/_image_compress_stub.dart';

/// Centralized image upload helper that enforces:
/// - Supported formats: JPG, JPEG, PNG, WEBP
/// - Maximum file size: 2 MB (after compression)
/// - Automatic compression before upload
class ImageUploadHelper {
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Validates extension and returns the mime type string.
  /// Returns null if the format is not supported.
  static String? getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  /// Returns true if the file extension is allowed.
  static bool isFormatAllowed(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Validates format, reads bytes, compresses if needed, and enforces 2 MB limit.
  ///
  /// Returns [ImageValidationResult] with either the processed bytes or an error message.
  static Future<ImageValidationResult> validateAndCompress(XFile image) async {
    // 1. Format check
    if (!isFormatAllowed(image.name)) {
      return ImageValidationResult.error(
        'Unsupported format. Please use JPG, PNG, or WEBP images.',
      );
    }

    // 2. Read raw bytes
    final rawBytes = await image.readAsBytes();

    // 3. Compress
    final compressedBytes = await _compress(rawBytes, image.name);

    // 4. Size check after compression
    if (compressedBytes.length > _maxFileSizeBytes) {
      final sizeMb = (compressedBytes.length / (1024 * 1024)).toStringAsFixed(
        1,
      );
      return ImageValidationResult.error(
        'Image is too large ($sizeMb MB). Maximum allowed size is 2 MB.',
      );
    }

    final mimeType = getMimeType(image.name) ?? 'image/jpeg';
    return ImageValidationResult.success(compressedBytes, mimeType);
  }

  /// Compresses image bytes. On web, returns original bytes (web doesn't support native compression).
  static Future<Uint8List> _compress(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // flutter_image_compress native compression not available on web;
      // image_picker already applies imageQuality on web, so return as-is.
      return bytes;
    }

    final ext = fileName.split('.').last.toLowerCase();
    final format = ext == 'png'
        ? CompressFormat.png
        : ext == 'webp'
        ? CompressFormat.webp
        : CompressFormat.jpeg;

    // First pass: quality 80, max 1200px
    Uint8List result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1200,
      minHeight: 1200,
      quality: 80,
      format: format,
    );

    // Second pass if still > 2 MB: reduce quality further
    if (result.length > _maxFileSizeBytes) {
      result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 60,
        format: format,
      );
    }

    return result;
  }
}

/// Result object returned by [ImageUploadHelper.validateAndCompress].
class ImageValidationResult {
  final bool isValid;
  final Uint8List? bytes;
  final String? mimeType;
  final String? errorMessage;

  const ImageValidationResult._({
    required this.isValid,
    this.bytes,
    this.mimeType,
    this.errorMessage,
  });

  factory ImageValidationResult.success(Uint8List bytes, String mimeType) {
    return ImageValidationResult._(
      isValid: true,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  factory ImageValidationResult.error(String message) {
    return ImageValidationResult._(isValid: false, errorMessage: message);
  }
}