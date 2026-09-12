import 'package:flutter/material.dart';

bool templateFileExists(String path) => false;

Widget templatePreview(String path) =>
    const Center(child: Icon(Icons.image_not_supported_outlined, size: 40));

Widget templateCanvasPreview(String path) =>
    const Center(child: Icon(Icons.image_not_supported_outlined, size: 40));

String? validateTemplatePath(String path) =>
    path.trim().isEmpty ? 'Required' : null;
