import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// Import Logic & Helpers
import '../../data/models/member_model.dart';
import '../../logic/map_logic_controller.dart';
import '../../logic/profile_cubit.dart'; 
import '../../utils/circle_dialog_helper.dart';

// Import Services & Widgets
import '../../data/services/circle_service.dart';
import 'login_screen.dart';
import '../widgets/modern_top_ui.dart';
import '../widgets/member_list_sheet.dart';
import '../widgets/map_markers.dart';

class SwiftLocMap extends StatefulWidget {
  const SwiftLocMap({super.key});
  @override
  State<SwiftLocMap> createState() => _SwiftLocMapState();
}

class _SwiftLocMapState extends State<SwiftLocMap> {
  final MapController _mapController = MapController();
  final MapLogicController _logic = MapLogicController();
  final CircleService _circleService = CircleService();

  String get myId => FirebaseAuth.instance.currentUser?.uid ?? "unknown";
  String myName = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "User";
  String? myProfileUrl;
  
  String currentCircleCode = "NOT_IN_CIRCLE";
  String circleName = "No Circle Joined";
  
  LatLng? _currentPos;
  double _currentSpeed = 0.0;
  int _currentBattery = 100;
  String _currentStatus = "Stationary";
  List<Marker> _friendMarkers = [];
  List<Map<String, dynamic>> _myCirclesList = [];
  List<Member> _currentMembers = [];
  
  bool _isFirstLocationUpdate = true; 
  bool _isUploadingImage = false; 
  bool _isFollowingUser = true; 
  StreamSubscription? _circlesSubscription;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _logic.stopAll();
    super.dispose();
  }

  void _bootstrap() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    user = await FirebaseAuth.instance.authStateChanges().first;
  }
  

  if (user == null) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    return;
  }

  if (mounted) {
    context.read<ProfileCubit>().fetchProfile(user.uid);
  }

  final prefs = await SharedPreferences.getInstance();
  String? savedName = prefs.getString('my_saved_name');

  setState(() {
    currentCircleCode = prefs.getString('last_circle_code') ?? "NOT_IN_CIRCLE";
    circleName = prefs.getString('last_circle_name') ?? "No Circle Joined";
    myName = savedName ?? (user?.email?.split('@')[0] ?? "User");
  });

  _startLocationTracking();
  
  if (currentCircleCode != "NOT_IN_CIRCLE") {
    _startListeningToMembers();
  }

    // --- PAKAI SATU SAHAJA & SIMPAN DALAM VARIABLE ---
    _circlesSubscription?.cancel(); // Safety check: cancel yang lama kalau ada
    _circlesSubscription = _circleService.getUserCircles(user.uid).listen((circles) {
      if (!mounted) return;
      setState(() {
        _myCirclesList = circles;
        if (currentCircleCode == "NOT_IN_CIRCLE" && circles.isNotEmpty) {
          _updateCircleState(circles[0]['code'], circles[0]['name']);
        }
      });
      });
  }

  void _startLocationTracking() {
    _logic.startTracking(
      currentCircleCode: currentCircleCode,
      myId: myId,
      onUpdate: (pos, speed, status, battery) {
        if (!mounted) return;
        setState(() {
          _currentPos = pos;
          _currentSpeed = speed;
          _currentStatus = status;
          _currentBattery = battery;
        });

        // --- UPDATE: Logic Auto-Center ---
        if (_isFollowingUser) {
          _mapController.move(pos, 16.0);
        }

        if (_isFirstLocationUpdate) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _mapController.move(pos, 17);
          });
          _isFirstLocationUpdate = false;
        }
      },
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return "Never";
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - timestamp) / 1000; 

    if (diff < 60) return "Just now";
    if (diff < 3600) return "${(diff / 60).toInt()}m ago";
    if (diff < 86400) return "${(diff / 3600).toInt()}h ago";
    return "Offline";
  }

  void _startListeningToMembers() {
    if (currentCircleCode == "NOT_IN_CIRCLE") return;

    _logic.listenToMembers(
      circleCode: currentCircleCode,
      myId: myId,
      onMembersUpdate: (members) {
        if (!mounted) return;
        
        setState(() {
          List<Member> otherMembers = members.where((m) => m.id != myId).toList();
          final profileState = context.read<ProfileCubit>().state;
          String? myImage;
          if (profileState is ProfileSuccess) myImage = profileState.imageUrl;

          Member me = Member(
            id: myId,
            name: "$myName (You)", 
            lat: _currentPos?.latitude ?? 0.0,
            lng: _currentPos?.longitude ?? 0.0,
            speed: _currentSpeed,
            status: _currentStatus,
            battery: _currentBattery, 
            profileUrl: myImage ?? "",
            lastSeen: DateTime.now().millisecondsSinceEpoch,
          );

          _currentMembers = [me, ...otherMembers];
          
          _friendMarkers = otherMembers.map((m) {
            return MapMarkerHelper.buildFriendMarker(
              m, 
              (member) => _confirmKick(member),
              timeLabel: _formatTimestamp(m.lastSeen),
            );
          }).toList();
        });
      },
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Leave Circle?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to leave '$circleName'?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _circleService.removeMember(currentCircleCode, myId);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('last_circle_code');
              setState(() {
                currentCircleCode = "NOT_IN_CIRCLE";
                _friendMarkers = [];
                _currentMembers = [];
              });
            },
            child: const Text("Leave", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0D1B2A);

    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSuccess) {
          setState(() => myProfileUrl = state.imageUrl);
          if (_isUploadingImage) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile image updated!")));
            setState(() => _isUploadingImage = false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: darkBg,
        extendBody: true,
        body: Stack(
          children: [
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                String? profileUrl;
                File? localFile;
                if (profileState is ProfileSuccess) {
                  profileUrl = profileState.imageUrl;
                  localFile = profileState.imageFile;
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPos ?? const LatLng(3.1390, 101.6869), 
                    initialZoom: 18,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture && _isFollowingUser) {
                        setState(() => _isFollowingUser = false);
                      }
                    },
                  ),
                  children: [
                    Opacity(
                      opacity: 0.8, 
                      child: TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: ['a', 'b', 'c', 'd'],
                        retinaMode: RetinaMode.isHighDensity(context),
                        userAgentPackageName: 'com.swiftloc.app',
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        ..._friendMarkers,
                        if (_currentPos != null) 
                        MapMarkerHelper.buildMyMarker(
                          _currentPos!,
                          _currentStatus, 
                          profileUrl,
                          localImageFile: localFile,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                String? currentImage;
                if (profileState is ProfileSuccess) {
                  currentImage = profileState.imageUrl;
                }

                return ModernTopUI(
                  circleName: circleName,
                  circleCode: currentCircleCode,
                  allCircles: _myCirclesList,
                  myName: myName,
                  myProfileImage: currentImage ?? myProfileUrl, 
                  onCircleChanged: (code, name) {
                    _logic.stopListeningToMembers(); 
                    setState(() {
                      _friendMarkers = []; 
                      _currentMembers = [];
                      _isFollowingUser = true; 
                    });
                    _updateCircleState(code, name);   
                  },
                  onActionMenu: _showActionMenu,
                  onUpdateImage: () {
                    setState(() => _isUploadingImage = true); 
                    context.read<ProfileCubit>().pickAndUploadImage();
                  },
                  onEditProfileName: _showEditMyNameDialog,
                  onEditCircleName: () {
                    CircleDialogHelper.showCreateDialog(
                      context, 
                      (newName) async {
                        if (newName.isNotEmpty) {
                          await _circleService.updateCircleName(currentCircleCode, newName);
                          _updateCircleState(currentCircleCode, newName);
                        }
                      },
                      title: "Edit Circle Name",
                      buttonText: "Save",
                    );
                  },
                  onLeaveCircle: _showLeaveConfirmation,
                  onLogout: () async {
                    // 1. Stop GPS tracking and member listeners in foreground logic
                    await _logic.stopAll(); 
                    await _circlesSubscription?.cancel();
                    _circlesSubscription = null;

                    // 2. Clear SharedPreferences so Background Service knows to stop updating
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('my_uid');
                    await prefs.setString('last_circle_code', 'NOT_IN_CIRCLE');

                    // 3. Small delay to ensure logic cleanup completes
                    await Future.delayed(const Duration(milliseconds: 600));

                    // 4. Sign out from Firebase
                    await FirebaseAuth.instance.signOut();
                    
                    // 5. Navigate to Login and clear all navigation stacks
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                );
              },
            ),

            Positioned(
              right: 15,
              bottom: 125, 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: "compass",
                    backgroundColor: darkBg,
                    onPressed: () => _mapController.rotate(0),
                    child: const Icon(Icons.explore, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: "recenter",
                    backgroundColor: darkBg,
                    onPressed: () {
                      // --- Recenter & Following ---
                      setState(() => _isFollowingUser = true);
                      if (_currentPos != null) {
                        _mapController.move(_currentPos!, 17);
                      }
                    },
                    child: Icon(
                      Icons.my_location, 
                      color: _isFollowingUser ? Colors.greenAccent : Colors.blueAccent
                    ),
                  ),
                ],
              ),
            ),

            MemberListSheet(
              members: _currentMembers, 
              mySpeed: _currentSpeed,
              myStatus: _currentStatus,
              onMemberTap: (member) async{
                // Go to member location when tap name
                setState(() => _isFollowingUser = false);
                _mapController.move(
                  LatLng(member.lat, member.lng), 
                  17.0, 
                );
                await _logic.triggerRemoteUpdate(currentCircleCode, member.id);

                // 4. (Optional) Bagitahu user tengah loading
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Requesting fresh location from ${member.name}..."),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              title: const Text("Create New Circle", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                CircleDialogHelper.showCreateDialog(context, (name) async {
                  String code = await _circleService.createCircle(name, myId, myName);
                  _updateCircleState(code, name);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined, color: Colors.blueAccent),
              title: const Text("Join Existing Circle", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                CircleDialogHelper.showJoinDialog(context, (code) async {
                  bool ok = await _circleService.joinCircle(code, myId, myName);
                  if (ok) {
                    var info = await _circleService.getCircleInfo(code);
                    _updateCircleState(code, info?['circle_name'] ?? "Joined");
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateCircleState(String code, String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_circle_code', code);
  await prefs.setString('last_circle_name', name);
  
  setState(() {
    currentCircleCode = code;
    circleName = name;
    _isFollowingUser = true; 
    _friendMarkers = []; // Clear marker 
    _currentMembers = []; // Clear list 
  });

  _logic.stopListeningToMembers(); 

  _startListeningToMembers(); 

  _logic.updateCurrentCircle(code); 

  debugPrint("Circle updated to $code in Foreground & SharedPreferences");
}

  void _showEditMyNameDialog() {
  CircleDialogHelper.showCreateDialog(
    context, 
    (newName) async {
      if (newName.isNotEmpty) {
        try {
          await _circleService.updateMasterProfile(myId, newName, myProfileUrl);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('my_saved_name', newName);

          setState(() => myName = newName);
          
          _startListeningToMembers();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Display name updated everywhere!"))
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    },
    title: "Edit Display Name",
    buttonText: "Update",
    hintText: "Enter your full name"
  );
}

  void _confirmKick(Member member) {
    debugPrint("Kick functionality triggered for: ${member.name}");
  }
}