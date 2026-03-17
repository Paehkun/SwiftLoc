import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/services/location_service.dart';
import '../data/models/member_model.dart';
import 'package:geolocator_android/geolocator_android.dart';

class MapLogicController {
  final LocationService _locationService = LocationService();
  final Battery _battery = Battery();

  StreamSubscription? memberSubscription;
  StreamSubscription? positionSubscription;
  StreamSubscription? _circlesSubscription;

  Timer? _stationaryTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastFirebaseUpdateTime;
  String _lastSentStatus = "Stationary";
  
  String _activeCircleCode = "NOT_IN_CIRCLE";

  /// 1. START TRACKING (GPS & HEARTBEAT)
  Future<void> startTracking({
    required String currentCircleCode,
    required String myId,
    required Function(LatLng, double, String, int) onUpdate,
  }) async {
    if (positionSubscription != null) return;

    _activeCircleCode = currentCircleCode;

    // --- INITIAL PING ---
    try {
      Position firstPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      int batteryLevel = 100;
      try { batteryLevel = await _battery.batteryLevel; } catch (_) {}

      onUpdate(LatLng(firstPos.latitude, firstPos.longitude), 0.0, "Stationary", batteryLevel);

      if (_activeCircleCode != "NOT_IN_CIRCLE") {
        await _locationService.updateFirebaseLocation(
          circleCode: _activeCircleCode,
          userId: myId,
          pos: firstPos,
          status: "Stationary",
          battery: batteryLevel,
        );
        _lastFirebaseUpdateTime = DateTime.now();
        _lastSentStatus = "Stationary";
      }
    } catch (e) {
      print("Error getting initial location: $e");
    }

    // --- SETUP BACKGROUND SETTINGS ---
final AndroidSettings androidSettings = AndroidSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 2, 
  intervalDuration: const Duration(seconds: 5), 
  foregroundNotificationConfig: const ForegroundNotificationConfig(
    notificationTitle: "SwiftLoc Live Tracking",
    notificationText: "Sharing your location with your circle",
    enableWakeLock: true,
  ),
);

    // --- HEARTBEAT LOGIC (10 Minute) ---
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      if (_activeCircleCode != "NOT_IN_CIRCLE") {
        int batteryLevel = 100;
        try { batteryLevel = await _battery.batteryLevel; } catch (_) {}

        await FirebaseDatabase.instance
            .ref()
            .child('circles/$_activeCircleCode/members/$myId')
            .update({
          'lastSeen': ServerValue.timestamp,
          'battery': batteryLevel,
        });
      }
    });

    // --- START LOCATION STREAM ---
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: androidSettings,
    ).listen((Position pos) async {
      int batteryLevel = 100;
      try { batteryLevel = await _battery.batteryLevel; } catch (_) {}

      double speedKmH = pos.speed * 3.6; // Convert m/s to km/h
      LatLng currentPos = LatLng(pos.latitude, pos.longitude);

      // --- DRIVING VS STATIONARY ---
      // IF speed > 5 km/h = driving
      String status = (pos.speed > 1.4) ? "Driving" : "Stationary";

      // UI Update follow drive
      onUpdate(currentPos, speedKmH, status, batteryLevel);

      // --- FIREBASE UPDATE LOGIC (DYNAMIC) ---
      if (_activeCircleCode != "NOT_IN_CIRCLE") {
        DateTime now = DateTime.now();
        int secSinceLastUpdate = now.difference(_lastFirebaseUpdateTime ?? DateTime(0)).inSeconds;

        bool shouldUpdate = (status != _lastSentStatus) || 
                           (status == "Driving" && secSinceLastUpdate >= 10) || 
                           (status == "Stationary" && secSinceLastUpdate >= 30);

        if (shouldUpdate) {
          _lastSentStatus = status;
          _lastFirebaseUpdateTime = now;

          await _locationService.updateFirebaseLocation(
            circleCode: _activeCircleCode,
            userId: myId,
            pos: pos,
            status: status,
            battery: batteryLevel,
          );
          print("Logic: Firebase Updated ($status) - Speed: ${speedKmH.toStringAsFixed(1)}km/h");
        }
      }
    });
  }

  /// Update circle code 
  void updateCurrentCircle(String newCode) {
    _activeCircleCode = newCode;
    _lastFirebaseUpdateTime = null; 
    print("Logic: Tracking node updated to $newCode");
  }

  /// 2. LISTEN TO MEMBERS
  void listenToMembers({
    required String circleCode,
    required String myId,
    required Function(List<Member>) onMembersUpdate,
  }) {
    memberSubscription?.cancel();
    memberSubscription = _locationService.getMembersStream(circleCode).listen((event) async {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        List<Member> members = [];

        for (var entry in data.entries) {
          String userId = entry.key.toString();
          if (userId == myId) continue;

          final memberData = Map<String, dynamic>.from(entry.value as Map);

          final masterSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('users/$userId/profile')
              .get();

          if (masterSnapshot.exists) {
            final masterData = masterSnapshot.value as Map;
            memberData['name'] = masterData['name'] ?? memberData['name'] ?? "Friend";
            memberData['profileUrl'] = masterData['profileBase64'] ?? memberData['profileUrl'] ?? "";
          }

          try {
            members.add(Member.fromMap(userId, memberData));
          } catch (e) {
            print("Error parsing member $userId: $e");
          }
        }
        onMembersUpdate(members);
      } else {
        onMembersUpdate([]);
      }
    });
  }

  /// 4. STOP ALL
  Future<void> stopAll() async {
    await memberSubscription?.cancel();
    memberSubscription = null;

    await positionSubscription?.cancel();
    positionSubscription = null;

    await _circlesSubscription?.cancel();
    _circlesSubscription = null;

    _stationaryTimer?.cancel();
    _stationaryTimer = null;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    _activeCircleCode = "NOT_IN_CIRCLE";
    print("Logic: Cleanup complete.");
  }

  void stopListeningToMembers() {
    memberSubscription?.cancel();
    memberSubscription = null;
  }
}