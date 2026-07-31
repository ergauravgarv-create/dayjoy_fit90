import 'dart:typed_data';

/// Detects repeated submission of the same image. Works on image *content*,
/// never the filename.
///
/// The default implementation below computes a fast, dependency-free content
/// hash (FNV-1a 64-bit). It catches byte-identical re-submissions. For
/// production you should ALSO add a perceptual hash (aHash/pHash) to catch
/// near-duplicates (re-saved/re-compressed copies) — wire that into
/// [isPerceptualDuplicate].
abstract interface class DuplicateImageDetectionService {
  /// Stable content hash of the image bytes.
  String computeHash(Uint8List bytes);

  /// True if [hash] already exists among [knownHashes] (exact match).
  bool isExactDuplicate(String hash, Iterable<String> knownHashes);
}

class ContentHashDuplicateService implements DuplicateImageDetectionService {
  const ContentHashDuplicateService();

  @override
  String computeHash(Uint8List bytes) {
    // FNV-1a 32-bit. Deterministic and fast; good enough for exact-duplicate
    // detection without pulling in the `crypto` package. 32-bit constants are
    // used (instead of 64-bit) so the code also compiles for the web, where
    // JavaScript cannot represent integers larger than 2^53 exactly.
    const int fnvPrime = 0x01000193; // 16777619
    const int mask = 0xFFFFFFFF; // 32-bit
    int hash = 0x811c9dc5; // 32-bit offset basis (2166136261)
    for (final int b in bytes) {
      hash ^= b;
      hash = (hash * fnvPrime) & mask;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  @override
  bool isExactDuplicate(String hash, Iterable<String> knownHashes) {
    return knownHashes.contains(hash);
  }
}
