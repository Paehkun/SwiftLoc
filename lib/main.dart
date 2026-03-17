import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'logic/profile_cubit.dart';             
import 'logic/background_service.dart';
import 'presentation/screens/swift_loc_map.dart';
import 'presentation/screens/login_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> requestPermissions() async {
  // Request notification permission for Android 13+
  await Permission.notification.request();

  // Request location permission while using the app
  var status = await Permission.location.request();
  
  // Request background location permission for Android 10+
  // User must manually select "Allow all the time" in settings
  if (status.isGranted) {
    await Permission.locationAlways.request();
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // Prompt permissions during app startup
  await requestPermissions();
  
  FirebaseDatabase.instance.databaseURL = dotenv.env['FIREBASE_DB_URL'];

  try {
    // Start background location tracking service
    await BackgroundLocService.initializeService();
  } catch (e) {
    debugPrint("Background Service Error: $e");
  }
  
  FlutterNativeSplash.remove();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit()..loadProfile(), 
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftLoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Navigate to map if user is logged in
          if (snapshot.hasData) {
            return const SwiftLocMap();
          }

          // Otherwise, show login screen
          return const LoginScreen();
        },
      ),
    );
  }
}