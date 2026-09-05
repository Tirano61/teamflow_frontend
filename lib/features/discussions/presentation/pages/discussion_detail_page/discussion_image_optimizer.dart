import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class OptimizedImageResult {
  const OptimizedImageResult({
    required this.bytes,
    required this.fileName,
    required this.wasOptimized,
  });

  final Uint8List bytes;
  final String fileName;
  final bool wasOptimized;
}

OptimizedImageResult optimizeImageForUpload({
  required Uint8List originalBytes,
  required String originalFileName,
}) {
  try {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      return OptimizedImageResult(
        bytes: originalBytes,
        fileName: originalFileName,
        wasOptimized: false,
      );
    }

    const maxSide = 1440;
    var processed = decoded;
    final longestSide = decoded.width >= decoded.height
        ? decoded.width
        : decoded.height;

    if (longestSide > maxSide) {
      final scale = maxSide / longestSide;
      final targetWidth = (decoded.width * scale).round();
      final targetHeight = (decoded.height * scale).round();
      processed = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    var jpg = img.encodeJpg(processed, quality: 70);
    if (jpg.length > 900 * 1024) {
      jpg = img.encodeJpg(processed, quality: 58);
    }
    if (jpg.length > 700 * 1024) {
      jpg = img.encodeJpg(processed, quality: 48);
    }

    if (jpg.length >= originalBytes.length) {
      return OptimizedImageResult(
        bytes: originalBytes,
        fileName: originalFileName,
        wasOptimized: false,
      );
    }

    return OptimizedImageResult(
      bytes: Uint8List.fromList(jpg),
      fileName: _withJpgExtension(originalFileName),
      wasOptimized: true,
    );
  } catch (_) {
    return OptimizedImageResult(
      bytes: originalBytes,
      fileName: originalFileName,
      wasOptimized: false,
    );
  }
}

String _withJpgExtension(String fileName) {
  final normalized = fileName.trim();
  if (normalized.isEmpty) {
    return 'image.jpg';
  }

  final dotIndex = normalized.lastIndexOf('.');
  if (dotIndex <= 0) {
    return '$normalized.jpg';
  }

  return '${normalized.substring(0, dotIndex)}.jpg';
}
