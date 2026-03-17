import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundLocService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_service',
      'SwiftLoc Tracking',
      description: 'This channel is used for live location tracking.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_service',
        initialNotificationTitle: 'SwiftLoc Active',
        initialNotificationContent: 'Monitoring location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Init Firebase dalam isolate berasingan
  await Firebase.initializeApp();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  
  Position? lastPosition;
  DateTime? lastUpdateTime;

  // Update setiap 15 saat untuk keseimbangan antara Live vs Bateri
  Timer.periodic(const Duration(seconds: 12), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('my_uid'); 
    final String? circleCode = prefs.getString('last_circle_code');

    // Jika tak login atau tak masuk circle, jangan bazir bateri
    if (uid == null || circleCode == null || circleCode == "NOT_IN_CIRCLE") return;

    try {
      // WAJIB LocationAccuracy.high untuk detect speed memandu
      Position currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      double distance = 0;
      if (lastPosition != null) {
        distance = Geolocator.distanceBetween(
          lastPosition!.latitude, lastPosition!.longitude,
          currentPos.latitude, currentPos.longitude
        );
      }

      double speedKmH = currentPos.speed * 3.6;
      
      // LOGIC UPDATE:
      // 1. First time run
      // 2. Bergerak lebih 10 meter
      // 3. Kelajuan melebihi 5km/h (tengah gerak)
      // 4. Dah lebih 5 minit tak update (Heartbeat)
      
      bool shouldUpdate = lastPosition == null || 
                         distance > 10 || 
                         speedKmH > 5 ||
                         (lastUpdateTime == null || DateTime.now().difference(lastUpdateTime!).inMinutes >= 5);

      if (shouldUpdate) {
        lastPosition = currentPos;
        lastUpdateTime = DateTime.now();

        // Tentukan status yang konsisten dengan Foreground UI
        String status = "Stationary";
        if (speedKmH > 15) {
          status = "Driving";
        } else if (speedKmH > 3) {
          status = "Walking";
        }

        await dbRef.child("circles/$circleCode/members/$uid").update({
          "lat": currentPos.latitude,
          "lng": currentPos.longitude,
          "speed": speedKmH.toInt(),
          "status": status,
          "lastSeen": ServerValue.timestamp, // Gunakan camelCase supaya match dengan Model
          "battery": 0, // Opsional: boleh tambah battery_plus kalau nak hantar data bateri juga
        });

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "SwiftLoc: $status",
            content: "Speed: ${speedKmH.toInt()} km/h | Updated: ${DateTime.now().hour}:${DateTime.now().minute}",
          );
        }
      }
    } catch (e) {
      debugPrint("Background Tracking Error: $e");
    }
  });
}