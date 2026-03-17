import 'package:flutter/material.dart';
import '../../data/models/member_model.dart';
import 'dart:convert';

class MemberListSheet extends StatelessWidget {
  final List<Member> members;
  final double mySpeed;
  final String myStatus;
  // 1. Tambah callback function ni
  final Function(Member) onMemberTap;

  const MemberListSheet({
    super.key,
    required this.members,
    required this.mySpeed,
    required this.myStatus,
    required this.onMemberTap, // 2. Masukkan dalam constructor
  });

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.greenAccent;
    if (level > 20) return Colors.orangeAccent;
    return Colors.redAccent;
  }
  String _formatLastSeen(int timestamp) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}



  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0D1B2A);
    const Color cardBg = Color(0xFF1B263B);
    const Color accentBlue = Color(0xFF415A77);

    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
              )
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Circle Members",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text(
                          "${members.length} people online",
                          style: TextStyle(color: accentBlue, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${mySpeed.toStringAsFixed(0)} km/h • $myStatus",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      "No other members online",
                      style: TextStyle(color: Colors.white24),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return ListTile(
                      // 3. SEKARANG KITA TAMBAH ONTAP KAT SINI
                      onTap: () => onMemberTap(m),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: cardBg,
                        // Check  profileUrl
                        backgroundImage: (m.profileUrl.isNotEmpty) 
                            ? MemoryImage(base64Decode(m.profileUrl)) 
                            : null,
                        // default image
                        child: (m.profileUrl.isEmpty)
                            ? Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        m.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            m.status == "Driving"
                                ? Icons.directions_car
                                : Icons.person_pin_circle,
                            size: 14,
                            color: accentBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(m.status,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white54)),
                          const Text(" • ", style: TextStyle(color: Colors.white24)),
                          Text(
                            _formatLastSeen(m.lastSeen),
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${m.battery}%",
                                style: TextStyle(
                                  color: _getBatteryColor(m.battery),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _getBatteryIcon(m.battery),
                                color: _getBatteryColor(m.battery),
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Live",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}