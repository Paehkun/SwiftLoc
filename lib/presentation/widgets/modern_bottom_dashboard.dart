import 'package:flutter/material.dart';

class ModernBottomDashboard extends StatelessWidget {
  final double speed;
  final String status;

  const ModernBottomDashboard({
    super.key,
    required this.speed,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(Icons.speed_rounded, "SPEED", "${speed.toStringAsFixed(0)} km/h", Colors.blue),
            Container(width: 1, height: 35, color: Colors.grey.shade200),
            _buildStat(
              status == "Driving" ? Icons.directions_car_filled : Icons.person_pin_circle_rounded,
              "STATUS",
              status,
              status == "Driving" ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}