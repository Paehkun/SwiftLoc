import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/member_model.dart';

class MapMarkerHelper {
  
  static Widget buildMarkerWidget({
    required String name,
    required String status,
    String? profileUrl,
    File? localImageFile,
    bool isMe = false,
  }) {
    bool isDriving = status.toLowerCase() == "driving";

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
            border: Border.all(
              color: isMe ? Colors.blueAccent : (isDriving ? Colors.greenAccent : Colors.white70),
              width: 2.5,
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
            radius: 18,
            backgroundColor: const Color(0xFF0D1B2A),
            child: ClipOval(
              child: profileImage != null
                  ? Image(
                      image: profileImage,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) => isMe
                          ? const Icon(Icons.person, color: Colors.white, size: 20)
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                    )
                  : (isMe
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        )),
            ),
          ),
        ),
        if (isDriving)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 12),
          )
        else
          _buildNameLabel(isMe ? "Me" : name),
      ],
    );
  }

  static Marker buildMyMarker(LatLng point, String status, String? profileUrl, {File? localImageFile}) {
    return Marker(
      point: point,
      width: 65,
      height: 65,
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

static Marker buildFriendMarker(Member m, Function(Member) onKick) {
    return Marker(
      point: m.position,
      width: 65,
      height: 80, 
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => onKick(m),
        behavior: HitTestBehavior.opaque, 
        child: buildMarkerWidget(
          name: m.name,
          status: m.status,
          profileUrl: m.profileUrl,
          isMe: false,
        ),
      ),
    );
  }

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
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}