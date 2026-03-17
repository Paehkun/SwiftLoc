import 'dart:convert';
import 'package:flutter/material.dart';

class ModernTopUI extends StatelessWidget {
  final String circleName;
  final String circleCode;
  final String myName;
  final String? myProfileImage; // Base64 string for user profile
  final List<Map<String, dynamic>> allCircles;
  
  // Callbacks
  final Function(String code, String name) onCircleChanged;
  final VoidCallback onActionMenu;      // Join/Create Circle Menu
  final VoidCallback onUpdateImage;    // Trigger Image Picker
  final VoidCallback onEditProfileName; // Edit User's Display Name
  final VoidCallback onEditCircleName;  // Edit Current Circle Name
  final VoidCallback onLeaveCircle;     // Leave Current Circle
  final VoidCallback onLogout;

  const ModernTopUI({
    super.key,
    required this.circleName,
    required this.circleCode,
    required this.myName,
    this.myProfileImage,
    required this.allCircles,
    required this.onCircleChanged,
    required this.onActionMenu,
    required this.onUpdateImage,
    required this.onEditProfileName,
    required this.onEditCircleName,
    required this.onLeaveCircle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const Color darkBg = Color(0xFF0D1B2A);
    const Color cardBg = Color(0xFF1B263B);
    const Color accentBlue = Color(0xFF415A77);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // 1. LEFT SECTION: User Profile Button
            GestureDetector(
              onTap: () => _showMyProfileMenu(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cardBg,
                backgroundImage: (myProfileImage != null && myProfileImage!.isNotEmpty)
                    ? MemoryImage(base64Decode(myProfileImage!.contains(',') 
                        ? myProfileImage!.split(',').last 
                        : myProfileImage!))
                    : null,
                child: (myProfileImage == null || myProfileImage!.isEmpty)
                    ? Text(
                        myName.isNotEmpty ? myName[0].toUpperCase() : "U",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // 2. MIDDLE SECTION: Circle Selection & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      // Safety check: ensure value exists in list or set to null
                      value: (circleCode == "NOT_IN_CIRCLE" || 
                              !allCircles.any((c) => c['code'] == circleCode)) 
                          ? null 
                          : circleCode,
                      isDense: true,
                      dropdownColor: darkBg,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                      hint: const Text(
                        "Select Circle",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return allCircles.map<Widget>((c) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              c['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: allCircles.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text(
                            c['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (newCode) {
                        if (newCode != null) {
                          final selected = allCircles.firstWhere(
                            (element) => element['code'] == newCode
                          );
                          onCircleChanged(newCode, selected['name']);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Code: $circleCode",
                    style: const TextStyle(fontSize: 10, color: accentBlue, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            // 3. RIGHT SECTION: Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Circle Name Button
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                  onPressed: onEditCircleName,
                  tooltip: "Edit Circle Name",
                ),
                
                // Leave Circle Button
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  icon: const Icon(Icons.logout_rounded, color: Colors.orangeAccent, size: 18),
                  onPressed: onLeaveCircle,
                  tooltip: "Leave Circle",
                ),

                const SizedBox(width: 4),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(color: Colors.white10, thickness: 1),
                ),
                const SizedBox(width: 4),

                // Join/Create Circle Menu Button
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent, size: 24),
                  onPressed: onActionMenu,
                  tooltip: "Circle Actions",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the Personal Profile Menu when the user avatar is tapped
  void _showMyProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          const Text(
            "My Profile Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(color: Colors.white10),
          
          // Option 1: Update Profile Image
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: Colors.blueAccent),
            title: const Text("Update Profile Image", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onUpdateImage();
            },
          ),
          
          // Option 2: Edit Display Name
          ListTile(
            leading: const Icon(Icons.badge_outlined, color: Colors.blueAccent),
            title: const Text("Edit Display Name", style: TextStyle(color: Colors.white)),
            subtitle: Text("How others see you: $myName", 
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              onEditProfileName();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context); // Tutup BottomSheet dulu
              _showLogoutConfirmation(context); // Panggil confirmation dialog
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout from SwiftLoc?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              onLogout(); // Jalankan fungsi logout sebenar
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}