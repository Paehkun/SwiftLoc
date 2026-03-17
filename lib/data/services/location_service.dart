import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  late DatabaseReference _dbRef;

  LocationService() {
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dotenv.env['FIREBASE_DB_URL']!,
    ).ref();
  }

  Stream<Position> get locationStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

  Stream<DatabaseEvent> getMembersStream(String circleCode) {
    return _dbRef.child("circles/$circleCode/members").onValue;
  }

  Future<void> triggerRemoteUpdate(String circleCode, String memberId) async {
    await _dbRef.child('circles/$circleCode/members/$memberId').update({
      'lastRequest': ServerValue.timestamp,
    });
  }

  Future<void> updateFirebaseLocation({
    required String circleCode,
    required String userId,
    required Position pos,
    required String status,
    required int battery,
  }) async {
    await _dbRef.child('circles/$circleCode/members/$userId').update({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': pos.speed * 3.6,
      'status': status,
      'battery': battery,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> updateUserProfile(String userId, String name, String? imageUrl) async {
    await _dbRef.child('users/$userId/profile').set({
      'name': name,
      'profileUrl': imageUrl,
    });
  }
}