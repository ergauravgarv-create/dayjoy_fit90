import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

OcrService createOcrService() => _MlKitOcrService();

/// On-device OCR via Google ML Kit (Latin script). Runs entirely on the phone —
/// the medical report never leaves the device. All failures degrade to empty
/// text so the health screening still works from the typed symptoms.
class _MlKitOcrService implements OcrService {
  @override
  Future<String> extractText(Uint8List imageBytes) async {
    File? tmp;
    TextRecognizer? recognizer;
    try {
      // ML Kit reads from a file path; write the bytes to a short-lived temp
      // file, OCR it, then delete it.
      tmp = File(
          '${Directory.systemTemp.path}/dayjoy_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tmp.writeAsBytes(imageBytes, flush: true);

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(tmp.path));
      return result.text;
    } catch (_) {
      return '';
    } finally {
      try {
        await recognizer?.close();
      } catch (_) {}
      try {
        await tmp?.delete();
      } catch (_) {}
    }
  }
}
