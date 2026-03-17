import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            // Error message pop up
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Preview image??
                _buildProfileImage(state),
                
                const SizedBox(height: 20),

                // Pick image button
                ElevatedButton.icon(
                  onPressed: () {
                    // Call function in cubit
                    context.read<ProfileCubit>().pickAndUploadImage();
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Tukar Gambar Profile"),
                ),

                const SizedBox(height: 10),
                
                if (state is ProfileLoading)
                  const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Make the image round
  Widget _buildProfileImage(ProfileState state) {
    if (state is ProfileSuccess && state.imageFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(state.imageFile!),
      );
    } 
    
    // Return image link 
    if (state is ProfileSuccess && state.imageUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(state.imageUrl!),
      );
    }

    // Default icon 
    return const CircleAvatar(
      radius: 60,
      child: Icon(Icons.person, size: 60),
    );
  }
}