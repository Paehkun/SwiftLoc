import 'package:flutter/material.dart';

class CircleHeader extends StatelessWidget {
  final String circleName;
  final String circleCode;
  final VoidCallback onEdit;

  const CircleHeader({super.key, required this.circleName, required this.circleCode, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.hub, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(circleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Code: $circleCode", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
        ],
      ),
    );
  }
}