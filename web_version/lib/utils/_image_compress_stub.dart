// Stub for flutter_image_compress on Flutter Web.
// The real package is only used on mobile (guarded by kIsWeb in ImageUploadHelper).

import 'package:flutter/services.dart' show Uint8List;

enum CompressFormat { jpeg, png, webp, heic }

class FlutterImageCompress {
  static Future<Uint8List> compressWithList(
    Uint8List list, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    return list;
  }
}
