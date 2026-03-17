import 'dart:io';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/image_service.dart';

abstract class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileSuccess extends ProfileState {
  final File? imageFile;
  final String? imageUrl; // Simpan string Base64
  ProfileSuccess({this.imageFile, this.imageUrl});
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileCubit extends Cubit<ProfileState> {
  final ImageService _imageService = ImageService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  ProfileCubit() : super(ProfileInitial());

  /// 1. Take profile from Master Node (users/$uid/profile)
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchProfile(user.uid);
    }
  }

  Future<void> fetchProfile(String uid) async {
    try {
      final snapshot = await _dbRef.child('users/$uid/profile/profileBase64').get();
      
      if (snapshot.exists && snapshot.value != null) {
        emit(ProfileSuccess(imageUrl: snapshot.value.toString()));
        print("Cubit: Profile loaded for $uid");
      } else {
        emit(ProfileInitial());
      }
    } catch (e) {
      print("Error fetch profile: $e");
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      emit(ProfileLoading());
      
      final File? pickedFile = await _imageService.pickImage(
        maxWidth: 250,    
        imageQuality: 50,  
      );
      
      if (pickedFile == null) {
        loadProfile();
        return;
      }

      List<int> imageBytes = await pickedFile.readAsBytes();
      
      if (imageBytes.length > 300000) {
         emit(ProfileError("Gambar terlalu besar. Sila pilih bawah 150KB."));
         return;
      }

      String base64Image = base64Encode(imageBytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      await _dbRef.child('users/${user.uid}/profile').update({
        'profileBase64': base64Image,
        'lastUpdated': ServerValue.timestamp,
      });

      emit(ProfileSuccess(imageFile: pickedFile, imageUrl: base64Image));
      print("Cubit: Profile image updated to Master Node.");
      
    } catch (e) {
      emit(ProfileError("Gagal menyimpan profil: $e"));
    }
  }

  /// 4. Clear state during logout
  void clearProfile() {
    emit(ProfileInitial());
  }
}