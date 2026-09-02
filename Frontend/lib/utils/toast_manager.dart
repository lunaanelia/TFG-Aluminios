import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ToastManager {
  static final List<OverlayEntry> _messages = [];

  static void show(
      BuildContext context,
      String message, {
        bool success = true,
        Duration duration = const Duration(seconds: 2),
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    double bottomOffset = 80.0 + (_messages.length * 60);

    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: bottomOffset,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (success ? Colors.green : Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    _messages.add(entry);
    overlay.insert(entry);

    Future.delayed(duration, () {
      entry.remove();
      _messages.remove(entry);
      _updatePositions();
    });
  }

  static void _updatePositions() {
    for (int i = 0; i < _messages.length; i++) {
      _messages[i].markNeedsBuild();
    }
  }
}

Future<String> saveImage(Uint8List bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = path.join(directory.path, 'tutor_admin.png');

  final file = File(filePath);
  await file.writeAsBytes(bytes);

  return filePath;
}