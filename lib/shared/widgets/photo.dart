import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Resolves a stored photo reference into an [ImageProvider] that works on
/// every platform (web included).
///
/// Supported forms:
/// - `data:image/...;base64,....`  → in-memory bytes (how we persist uploads)
/// - `http(s)://...`               → network image
/// - `blob:...`                    → web object URL (network image)
/// - local file path               → file image (native only)
ImageProvider photoProvider(String path) {
  if (path.startsWith('data:')) {
    final comma = path.indexOf(',');
    final b64 = comma >= 0 ? path.substring(comma + 1) : path;
    return MemoryImage(base64Decode(b64));
  }
  if (path.startsWith('http') || path.startsWith('blob:') || kIsWeb) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

/// A square photo thumbnail/preview with a graceful fallback.
class PhotoView extends StatelessWidget {
  const PhotoView(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.iconSize = 20,
  });

  final String path;
  final double? width;
  final double? height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: Icon(Icons.broken_image, size: iconSize, color: AppColors.primary),
    );
    return Image(
      image: photoProvider(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
