import 'package:flutter/material.dart';

class CircleDialogHelper {
  static void showCreateDialog(
    BuildContext context, 
    Function(String) onSuccess, {
    String title = "Create New Circle", 
    String buttonText = "Create",
    String hintText = "Enter circle name", // 1. TAMBAH PARAMETER INI
  }) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration( // 2. BUANG 'const' DAN GUNA VARIABLE hintText
            hintText: hintText, 
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSuccess(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Join circle dialog
  static void showJoinDialog(BuildContext context, Function(String) onJoin) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Circle"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter 6-digit code"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              onJoin(controller.text.trim().toUpperCase());
              Navigator.pop(context);
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}