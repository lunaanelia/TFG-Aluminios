import 'package:flutter/material.dart';

void mostrarDialogoConfirmacion({
  required BuildContext context,
  required String mensaje,
  required int id,
  required Function(int) accionBorrar,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "Confirmar acción",
              style: TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF222B6F)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              accionBorrar(id);
            },
            child: const Text("Confirmar acción", key: Key('confirmar'), style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}