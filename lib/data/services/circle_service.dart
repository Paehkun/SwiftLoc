import 'dart:math';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Perlu untuk debugPrint

class CircleService {
  // Use .env
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: dotenv.env['FIREBASE_DB_URL']!,
  ).ref();

  // Initialize Firebase Storage
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  //Circle Functions

  Future<String> createCircle(String circleName, String adminId, String adminName) async {
    String newCode = _generateRandomCode();

    await _dbRef.child("circles/$newCode").set({
      "circle_name": circleName,
      "admin_id": adminId,
      "created_at": ServerValue.timestamp,
    });

    await _dbRef.child("circles/$newCode/members/$adminId").set({
      "name": adminName,
      "lat": 0.0,
      "lng": 0.0,
      "speed": 0,
      "status": "Stationary",
      "profileUrl": "",
      "battery": 100,
    });

    return newCode;
  }

  Future<bool> joinCircle(String circleCode, String userId, String userName) async {
    final snapshot = await _dbRef.child("circles/$circleCode").get();

    if (snapshot.exists) {
      await _dbRef.child("circles/$circleCode/members/$userId").set({
        "name": userName,
        "lat": 0.0,
        "lng": 0.0,
        "speed": 0,
        "status": "Stationary",
        "profileUrl": "",
        "battery": 100,
        "last_updated": ServerValue.timestamp
      });
      return true;
    }
    return false;
  }

  Future<void> removeMember(String circleCode, String userId) async {
    await _dbRef.child("circles/$circleCode/members/$userId").remove();
  }

  Future<Map<String, dynamic>?> getCircleInfo(String code) async {
    final snapshot = await _dbRef.child("circles/$code").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> updateCircleName(String circleCode, String newName) async {
    if (circleCode == "NOT_IN_CIRCLE") return;
    await _dbRef.child("circles/$circleCode").update({
      "circle_name": newName,
    });
  }

  Stream<List<Map<String, dynamic>>> getUserCircles(String userId) {
    return _dbRef.child("circles").onValue.map((event) {
      List<Map<String, dynamic>> myCircles = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((code, details) {
          final members = details['members'] as Map<dynamic, dynamic>?;
          if (members != null && members.containsKey(userId)) {
            myCircles.add({
              'code': code,
              'name': details['circle_name'] ?? 'Unknown',
            });
          }
        });
      }
      return myCircles;
    });
  }

  //Member & Profile Functions

  Future<void> updateMemberName(String circleCode, String uid, String newName) async {
    try {
      await _dbRef.child('circles/$circleCode/members/$uid').update({
        'name': newName,
      });
      debugPrint("Member name updated in Firebase: $newName");
    } catch (e) {
      debugPrint("Error updating member name: $e");
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(String userId, String circleCode, File imageFile) async {
    try {
      // Upload ke Firebase Storage
      Reference ref = _storage.ref().child("profiles/$userId.jpg");
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      // Update URL in Realtime Database
      await _dbRef.child("circles/$circleCode/members/$userId").update({
        "profileUrl": downloadUrl
      });

      return downloadUrl;
    } catch (e) {
      debugPrint("Error upload profile: $e");
      return null;
    }
  }

  Future<void> updateMasterProfile(String uid, String name, String? url) async {
  await _dbRef.child('users/$uid/profile').update({
    'name': name,
    'profileUrl': url,
  });
}
}