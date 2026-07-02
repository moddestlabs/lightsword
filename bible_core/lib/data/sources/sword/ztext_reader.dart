import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Handles reading and decompression of SWORD zText compressed modules.
/// 
/// zText format with BlockType=BOOK uses:
/// - .bzz: Contains multiple ZLIB-compressed blocks (one per book)
/// - .bzv: Verse index with offsets into decompressed book data
/// - .bzs: Book index with offsets into compressed .bzz file
class ZTextReader {
  /// Decompresses all ZLIB blocks using the book index (.bzs file).
  /// 
  /// The book index tells us where each compressed book block starts in the .bzz file.
  /// Each entry is 6 bytes: 4-byte offset + 2-byte size (little-endian).
  static String decompressAllBlocks(Uint8List compressedData, Uint8List? bookIndex) {
    if (bookIndex == null || bookIndex.isEmpty) {
      // Fallback: try to find ZLIB headers manually
      return _decompressAllBlocksManual(compressedData);
    }
    
    final buffer = StringBuffer();
    final blockOffsets = <int>[];
    
    // Parse book index to get block offsets
    const entrySize = 6;
    for (int i = 0; i < bookIndex.length ~/ entrySize; i++) {
      final offset = i * entrySize;
      if (offset + entrySize > bookIndex.length) break;
      
      final entry = bookIndex.sublist(offset, offset + entrySize);
      final blockOffset = _readUint32LE(entry, 0);
      final blockSize = _readUint16LE(entry, 4);
      
      if (blockOffset > 0 || blockSize > 0) {
        blockOffsets.add(blockOffset);
      }
    }
    
    // Sort offsets
    blockOffsets.sort();
    
    // Decompress each book block
    for (int i = 0; i < blockOffsets.length; i++) {
      final start = blockOffsets[i];
      final end = i + 1 < blockOffsets.length
          ? blockOffsets[i + 1]
          : compressedData.length;
      
      try {
        final blockData = compressedData.sublist(start, end);
        final decompressed = const ZLibDecoder().decodeBytes(blockData);
        final text = String.fromCharCodes(decompressed);
        buffer.write(text);
      } catch (e) {
        // Skip blocks that fail to decompress
        continue;
      }
    }
    
    return buffer.toString();
  }
  
  /// Fallback method: find ZLIB headers manually.
  /// 
  /// This is less reliable as ZLIB magic bytes can appear in content.
  static String _decompressAllBlocksManual(Uint8List compressedData) {
    final buffer = StringBuffer();
    
    // Find all ZLIB block headers (magic bytes: 78 9c)
    final blockOffsets = <int>[];
    for (int i = 0; i < compressedData.length - 1; i++) {
      if (compressedData[i] == 0x78 && compressedData[i + 1] == 0x9c) {
        blockOffsets.add(i);
      }
    }
    
    // Decompress each potential block
    for (int i = 0; i < blockOffsets.length; i++) {
      final start = blockOffsets[i];
      final end = i + 1 < blockOffsets.length 
          ? blockOffsets[i + 1] 
          : compressedData.length;
      
      try {
        final blockData = compressedData.sublist(start, end);
        final decompressed = const ZLibDecoder().decodeBytes(blockData);
        final text = String.fromCharCodes(decompressed);
        buffer.write(text);
      } catch (e) {
        // Skip blocks that fail to decompress
        continue;
      }
    }
    
    return buffer.toString();
  }
  
  /// Parses the verse index (.bzv file) to locate a specific verse.
  /// 
  /// Each entry in .bzv is 10 bytes:
  /// - 4 bytes: offset in .bzz file (little-endian)
  /// - 2 bytes: compressed size (little-endian)
  /// - 2 bytes: uncompressed size (little-endian)
  /// - 2 bytes: padding/unused
  /// 
  /// Returns null if verse index is out of bounds.
  /// NOTE: This is kept for future use but not currently used in decompression.
  static VerseLocation? getVerseLocation(Uint8List indexData, int verseIndex) {
    const entrySize = 10;
    final offset = verseIndex * entrySize;
    
    if (offset + entrySize > indexData.length) {
      return null;
    }
    
    final entry = indexData.sublist(offset, offset + entrySize);
    
    // Read little-endian values
    final dataOffset = _readUint32LE(entry, 0);
    final compressedSize = _readUint16LE(entry, 4);
    final uncompressedSize = _readUint16LE(entry, 6);
    
    // Offset of 0 typically means empty verse
    if (dataOffset == 0 && compressedSize == 0) {
      return null;
    }
    
    return VerseLocation(
      offset: dataOffset,
      compressedSize: compressedSize,
      uncompressedSize: uncompressedSize,
    );
  }
  
  /// Decompresses a ZLIB/Deflate block from the .bzz file.
  /// 
  /// Reads compressed data starting at [location.offset] for [location.compressedSize] bytes,
  /// then decompresses it using ZLIB/Deflate (not BZIP2, despite the .bzz extension).
  /// NOTE: This is kept for future use but not currently used.
  static String? decompressVerse(Uint8List compressedData, VerseLocation location) {
    try {
      // Extract the compressed block
      final blockStart = location.offset;
      final blockEnd = blockStart + location.compressedSize;
      
      if (blockEnd > compressedData.length) {
        return null;
      }
      
      final compressedBlock = compressedData.sublist(blockStart, blockEnd);
      
      // Decompress using ZLIB/Deflate
      // The ZLibDecoder automatically handles the zlib wrapper
      final decompressed = ZLibDecoder().decodeBytes(compressedBlock);
      
      // Convert to string (assuming UTF-8)
      return String.fromCharCodes(decompressed);
    } catch (e) {
      // Decompression failed
      return null;
    }
  }
  
  /// Reads a 32-bit unsigned integer in little-endian format.
  static int _readUint32LE(Uint8List data, int offset) {
    return data[offset] |
           (data[offset + 1] << 8) |
           (data[offset + 2] << 16) |
           (data[offset + 3] << 24);
  }
  
  /// Reads a 16-bit unsigned integer in little-endian format.
  static int _readUint16LE(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }
}

/// Location information for a verse in the compressed data file.
class VerseLocation {
  /// Byte offset in the .bzz file where compressed data starts.
  final int offset;
  
  /// Size of compressed data in bytes.
  final int compressedSize;
  
  /// Expected size after decompression (informational).
  final int uncompressedSize;
  
  const VerseLocation({
    required this.offset,
    required this.compressedSize,
    required this.uncompressedSize,
  });
  
  @override
  String toString() {
    return 'VerseLocation(offset: $offset, compressed: $compressedSize, uncompressed: $uncompressedSize)';
  }
}
