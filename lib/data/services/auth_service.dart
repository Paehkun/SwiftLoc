import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Error Sign Up: $e");
      return null;
    }
  }

  // UserSign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Error Sign In: $e");
      return null;
    }
  }

  // Log out
  Future<void> signOut() async => await _auth.signOut();

  // Get current user UID
  String get currentUserId => _auth.currentUser?.uid ?? "";
  
  //Check if user already logged in
  User? get currentUser => _auth.currentUser;
}