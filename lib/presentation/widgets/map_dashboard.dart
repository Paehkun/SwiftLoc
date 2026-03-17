import 'package:flutter/material.dart';

class MapDashboard extends StatelessWidget {
  final double speed;
  final String status;
  final VoidCallback onSOS;

  const MapDashboard({super.key, required this.speed, required this.status, required this.onSOS});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Speed", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("${speed.toStringAsFixed(0)} km/h", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Chip(
                  label: Text(status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: onSOS,
              child: const Text("SEND SOS ALERT"),
            ),
          ],
        ),
      ),
    );
  }
}