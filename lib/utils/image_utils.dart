import 'dart:io';
import 'package:flutter/material.dart';

class ImageUtils {
  static ImageProvider optimizeImage(String path, {int? width, int? height}) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
  
  static Widget cachedImage(String path, {double? width, double? height}) {
    return Image.file(
      File(path),
      width: width,
      height: height,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      fit: BoxFit.cover,
    );
  }
}