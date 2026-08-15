import 'dart:typed_data';

// Web/desktop use a no-op; mobile (dart:io) uses on-device ML Kit OCR. Because
// only the io variant imports google_mlkit_text_recognition, the web build
// never compiles the plugin and dart2js stays clean.
export 'ocr_service_stub.dart'
    if (dart.library.io) 'ocr_service_io.dart';

/// Extracts printed text from an image (e.g. a photographed medical report).
/// On-device on mobile; a no-op elsewhere.
abstract class OcrService {
  /// Returns the recognised text, or an empty string if nothing was read /
  /// OCR is unavailable. Never throws.
  Future<String> extractText(Uint8List imageBytes);
}
