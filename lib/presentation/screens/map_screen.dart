import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import '../../utils/map_marker_helper.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(vsync: this);
  
  // Starting location
  LatLng memberPos = const LatLng(3.1390, 101.6869);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SwiftLoc Tracker"),
        elevation: 2,
      ),
      body: Stack(
        children: [
          // LAYER 1: MAP
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: memberPos,
              initialZoom: 18, // zoom size
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Map Voyager Opacity 0.8 (Clean & Soft)
              Opacity(
                opacity: 0.8,
                child: TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                  userAgentPackageName: 'com.swiftloc.app',
                ),
              ),

              // Friend Marker
              AnimatedMarkerLayer(
                markers: [
                  AnimatedMarker(
                    point: memberPos,
                    width: 65,
                    height: 65,
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, animation) => MapMarkerHelper.buildMarkerWidget(
                      name: "Member",
                      status: "driving",
                      isMe: false,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // LAYER 2: DRAGGABLE BOTTOM SHEET (Member list)
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)
                  ],
                ),
                child: Column( 
                  children: [
                    // Handle Bar 
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 45,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // Title
                    const Padding(
                      padding: EdgeInsets.only(left: 20, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Group Members", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // List Item scrollable
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          ListTile(
                            onTap: () {
                              _animatedMapController.animateTo(
                                dest: memberPos, 
                                zoom: 18.0,
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: const Icon(Icons.person, color: Colors.blue),
                            ),
                            title: const Text("Member Name"),
                            subtitle: const Text("Status: Driving • Tap to focus"),
                            trailing: const Icon(Icons.gps_fixed, color: Colors.blue, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      // Floating Action Button 
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95), 
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              memberPos = LatLng(memberPos.latitude + 0.0002, memberPos.longitude + 0.0002);
              _animatedMapController.animateTo(dest: memberPos, zoom: 18);
            });
          },
          child: const Icon(Icons.directions_car),
        ),
      ),
    );
  }
}