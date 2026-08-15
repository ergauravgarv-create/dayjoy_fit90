import 'dart:typed_data';

import 'ocr_service.dart';

/// Web (and any dart:io-less platform): OCR is unavailable, so return empty
/// text. The health screening then relies on the typed symptoms alone.
OcrService createOcrService() => _NoopOcrService();

class _NoopOcrService implements OcrService {
  @override
  Future<String> extractText(Uint8List imageBytes) async => '';
}
