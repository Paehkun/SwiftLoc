import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart'; // Ensure this is in pubspec.yaml
import '../../utils/map_marker_helper.dart';
import '../../data/services/location_service.dart'; // Adjust path if needed

class MapScreen extends StatefulWidget {
  final String circleId; 
  final String userId;

  const MapScreen({super.key,
  required this.circleId, 
  required this.userId
  });
  

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // Service and Controller instances
  late final _animatedMapController = AnimatedMapController(vsync: this);
  final LocationService _locationService = LocationService();
  final Battery _battery = Battery();

  // Local State
  Map<String, dynamic> members = {};
  LatLng myInitialPos = const LatLng(3.1390, 101.6869);

  // Stream Subscriptions to prevent memory leaks
  StreamSubscription? _membersSubscription;
  StreamSubscription? _myLocationSubscription;

  @override
  void initState() {
    super.initState();
    _setupRemoteUpdateListener();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _myLocationSubscription?.cancel();
    _animatedMapController.dispose();
    super.dispose();
  }

  /// 1. REAL-TIME DATA SYNC
  void _startLiveTracking() {
    // Listen to all members in the circle
    _membersSubscription = _locationService.getMembersStream(widget.circleId).listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          members = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });

    // Listen to local GPS and push to Firebase
    _myLocationSubscription = _locationService.locationStream.listen((Position position) async {
      int level = await _battery.batteryLevel;
      
      await _locationService.updateFirebaseLocation(
        circleCode: widget.circleId,
        userId: widget.userId,
        pos: position,
        status: _determineStatus(position.speed),
        battery: level,
      );
    });
  }

  /// 2. REMOTE TRIGGER LISTENER (Listen for "Pings" from others)
  void _setupRemoteUpdateListener() {
    FirebaseDatabase.instance
        .ref('circles/${widget.circleId}/members/${widget.userId}/lastRequest')
        .onValue
        .listen((event) async {
      if (event.snapshot.value != null) {
        debugPrint("Remote Ping Received: Forcing GPS update...");
        
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        int level = await _battery.batteryLevel;

        await _locationService.updateFirebaseLocation(
          circleCode: widget.circleId,
          userId: widget.userId,
          pos: position,
          status: "Live Update",
          battery: level,
        );
      }
    });
  }

  /// Simple logic to determine status based on speed (m/s to km/h)
  String _determineStatus(double speedInMps) {
    double speedKph = speedInMps * 3.6;
    if (speedKph > 10) return "Driving";
    if (speedKph > 2) return "Walking";
    return "Stationary";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SwiftLoc Tracker"),
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // LAYER 1: THE MAP
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: myInitialPos,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.swiftloc.app',
              ),

              // DYNAMIC MARKER GENERATION
              AnimatedMarkerLayer(
                markers: members.entries.map((entry) {
                  final data = Map<String, dynamic>.from(entry.value);
                  final isMe = entry.key == widget.userId;
                  
                  return AnimatedMarker(
                    point: LatLng(data['lat'] ?? 0.0, data['lng'] ?? 0.0),
                    width: 70,
                    height: 70,
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, animation) => MapMarkerHelper.buildMarkerWidget(
                      name: isMe ? "You" : (data['name'] ?? "Member"),
                      status: data['status'] ?? "Idle",
                      isMe: isMe,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // LAYER 2: INTERACTIVE MEMBER LIST
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.12,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)
                  ],
                ),
                child: Column(
                  children: [
                    // Handlebar UI
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Circle Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    const Divider(height: 1),

                    // LIST OF MEMBERS FROM FIREBASE
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          String userId = members.keys.elementAt(index);
                          var data = Map<String, dynamic>.from(members[userId]);
                          LatLng pos = LatLng(data['lat'] ?? 0.0, data['lng'] ?? 0.0);

                          return ListTile(
                            onTap: () async {
                              // Focus map on member
                              _animatedMapController.animateTo(dest: pos, zoom: 18.0);
                              
                              // TRIGGER Remote Force Update
                              await _locationService.triggerRemoteUpdate(widget.circleId, userId);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Requesting update from ${data['name'] ?? 'Member'}..."),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: userId == widget.userId ? Colors.blue : Colors.grey[200],
                              child: Text(
                                (data['name'] ?? "M").substring(0, 1).toUpperCase(),
                                style: TextStyle(color: userId == widget.userId ? Colors.white : Colors.black),
                              ),
                            ),
                            title: Text(userId == widget.userId ? "You" : (data['name'] ?? "Unknown User")),
                            subtitle: Text("${data['status']} • 🔋 ${data['battery']}%"),
                            trailing: const Icon(Icons.chevron_right, size: 16),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      // Manual test button (optional)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () {
            // Re-center on self
            if (members[widget.userId] != null) {
              var myData = members[widget.userId];
              _animatedMapController.animateTo(
                dest: LatLng(myData['lat'], myData['lng']),
                zoom: 17
              );
            }
          },
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      ),
    );
  }
}