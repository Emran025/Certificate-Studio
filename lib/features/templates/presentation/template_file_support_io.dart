import 'dart:io';

import 'package:flutter/material.dart';

bool templateFileExists(String path) =>
    path.isNotEmpty && File(path).existsSync();

Widget templatePreview(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 40),
    );
  }
  return Image.file(
    file,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
  );
}

String? validateTemplatePath(String path) {
  final value = path.trim();
  if (value.isEmpty) return 'Required';
  if (!File(value).existsSync()) return 'File does not exist';
  final extension = value.toLowerCase().split('.').last;
  return ['png', 'jpg', 'jpeg', 'webp'].contains(extension)
      ? null
      : 'Use PNG, JPG, or WEBP image';
}
