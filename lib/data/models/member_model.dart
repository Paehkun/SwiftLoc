import 'package:latlong2/latlong.dart';

class Member {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double speed;
  final String status;
  final int battery;
  final String profileUrl;
  final int lastSeen;

  Member({
    required this.id, 
    required this.name, 
    required this.lat, 
    required this.lng, 
    required this.speed, 
    required this.status,
    required this.battery,
    required this.profileUrl,
    required this.lastSeen
  });

  LatLng get position => LatLng(lat, lng);
  String get speedDisplay => "${speed.toStringAsFixed(0)} km/h";

  factory Member.fromMap(String id, Map data) {
  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Kita buat check yang lebih 'ganas' kat sini
  int parseTimestamp(Map data) {
    // Check 'lastSeen' (huruf besar S)
    if (data['lastSeen'] is int) return data['lastSeen'];
    // Check 'last_updated' (format Firebase ServerValue)
    if (data['last_updated'] is int) return data['last_updated'];
    // Kalau dua-dua tak ada, baru guna masa sekarang
    return DateTime.now().millisecondsSinceEpoch;
  }

  return Member(
    id: id,
    name: data['name'] ?? 'Friend',
    lat: toDouble(data['lat'] ?? data['latitude']), 
    lng: toDouble(data['lng'] ?? data['longitude']), 
    speed: toDouble(data['speed']),
    status: data['status'] ?? 'Stationary',
    battery: data['battery'] ?? 100,
    profileUrl: data['profileUrl'] ?? "",
    lastSeen: parseTimestamp(data), // Gunakan helper kat atas
  );
}
}