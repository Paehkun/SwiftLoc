import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert'; // Required for base64Decode
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/member_model.dart';

class MapMarkerHelper {
  
  /// Main widget builder for the marker's visual representation
  static Widget buildMarkerWidget({
    required String name,
    required String status,
    String? profileUrl,
    File? localImageFile,
    bool isMe = false,
  }) {
    // Check if user is currently moving/driving
    bool isMoving = status.toLowerCase() == "driving" || status.toLowerCase() == "moving";

    // Handle different image sources (File, Network, or Base64)
    ImageProvider? profileImage;
    if (localImageFile != null) {
      profileImage = FileImage(localImageFile);
    } else if (profileUrl != null && profileUrl.isNotEmpty) {
      if (profileUrl.startsWith('http')) {
        profileImage = NetworkImage(profileUrl);
      } else {
        try {
          profileImage = MemoryImage(base64Decode(profileUrl));
        } catch (e) {
          profileImage = null;
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Dynamic border color based on activity and identity
            border: Border.all(
              color: isMe
                  ? Colors.blueAccent
                  : (isMoving ? Colors.greenAccent : Colors.white70),
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMe ? Colors.blueAccent : Colors.black).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: CircleAvatar(
            radius: 20, // Slightly larger for better visibility
            backgroundColor: const Color(0xFF0D1B2A),
            backgroundImage: profileImage,
            child: profileImage == null
                ? (isMe
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ))
                : null,
          ),
        ),
        // Display car icon if driving, otherwise show name label
        if (isMoving)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 10),
          )
        else
          _buildNameLabel(isMe ? "Me" : name),
      ],
    );
  }

  /// Builds the marker for the current user
  static Marker buildMyMarker(LatLng point, String status, String? profileUrl,
      {File? localImageFile}) {
    return Marker(
      point: point,
      width: 70,
      height: 70,
      alignment: Alignment.center,
      child: buildMarkerWidget(
        name: "Me",
        status: status,
        profileUrl: profileUrl,
        localImageFile: localImageFile,
        isMe: true,
      ),
    );
  }

  /// Builds a detailed marker for friends with Last Seen and Speed info
  static Marker buildFriendMarker(
    Member member, 
    Function(Member) onTap, 
    {required String timeLabel}
  ) {
    bool isMoving = member.status.toLowerCase() == "moving" || member.status.toLowerCase() == "driving";

    return Marker(
      point: LatLng(member.lat, member.lng),
      width: 80,  
      height: 110, 
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => onTap(member),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time Label (e.g., "5m ago")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                timeLabel,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 9, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Main Marker Circle
            buildMarkerWidget(
              name: member.name,
              status: member.status,
              profileUrl: member.profileUrl,
              isMe: false,
            ),
            // Speed Tag: Only shown if moving significantly
            if (isMoving && member.speed > 5)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Text(
                  "${member.speed.toInt()} km/h",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 9, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for the name tag below the marker
  static Widget _buildNameLabel(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}