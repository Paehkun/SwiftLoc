import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  late DatabaseReference _dbRef;
  LocationService() {
    // initialize .env here
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dotenv.env['FIREBASE_DB_URL']!,
    ).ref();
  } 

  Stream<Position> get locationStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
  );

  Stream<DatabaseEvent> getMembersStream(String circleCode) {
  return _dbRef.child("circles/$circleCode/members").onValue;
}

  // Dalam LocationService class
Future<void> updateFirebaseLocation({
  required String circleCode,
  required String userId,
  required Position pos,
  required String status,
  required int battery,
}) async {
  // Kita cuma update data yang "selalu berubah" sahaja
  await _dbRef.child('circles/$circleCode/members/$userId').update({
    'lat': pos.latitude,
    'lng': pos.longitude,
    'speed': pos.speed * 3.6,
    'status': status,
    'battery': battery,
    'lastSeen': ServerValue.timestamp,
    // Kita TAK HANTAR nama dan gambar kat sini dah!
  });
}

// Fungsi baru untuk update profile (panggil masa mula-mula login/set profile)
Future<void> updateUserProfile(String userId, String name, String? imageUrl) async {
  await _dbRef.child('users/$userId/profile').set({
    'name': name,
    'profileUrl': imageUrl,
  });
}
}