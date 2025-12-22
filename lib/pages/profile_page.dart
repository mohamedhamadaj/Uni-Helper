import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ower_project/pages/client_request_page.dart';
import 'package:ower_project/pages/profile_provider_page.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Main Profile Page - Routes to correct profile based on role
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }



  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userRole = doc.data()?['role'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color.fromARGB(255, 11, 53, 87),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Route to correct profile page based on role
    if (userRole == 'Provider') {
      return const ProviderProfilePage();
    } else {
      return const ClientProfilePage();
    }
  }
}

// CLIENT PROFILE PAGE
class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
      final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? userData;
  bool isLoading = true;
      String? _imageUrl;
  File? _localImage; // لعرض الصورة فوراً قبل الرفع
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
        _imageUrl = user?.photoURL;
    _loadUserData();
  }

  Future<void> _deleteOldProfileImage() async {
    try {
      if (user?.uid == null) return;

      // We list all common extensions to ensure we clean up whatever was there before.
      final List<String> possibleFiles = [
        '${user!.uid}.jpg',
        '${user!.uid}.jpeg',
        '${user!.uid}.png',
        '${user!.uid}.webp',
      ];

      // Supabase 'remove' ignores files that don't exist, so this is safe.
      await supabase.storage.from('profile-images').remove(possibleFiles);
      debugPrint('Old profile images cleanup attempt finished.');
    } catch (e) {
      // We catch this silently because if it fails (e.g. permission issue),
      // we still want the Upload to proceed.
      debugPrint('Note: Cleanup warning: $e');
    }
  }

    Future<void> _uploadProfileImage() async {
      
    final ImagePicker picker = ImagePicker();

    // 1. Pick the image
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, // Optimization: Resize for faster uploads
      maxHeight: 512,
      imageQuality: 75, // Optimization: Compress to save bandwidth
    );
    

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 2. CLEANUP: Try to delete the old image first
      await _deleteOldProfileImage();

      // 3. READ FILE (Platform Safe Way)
      // Using readAsBytes works on Web, MacOS, and Mobile universally.
      final bytes = await image.readAsBytes();

      // Get extension from the filename (safe on web)
      final fileExt = image.name.split('.').last;
      final fileName = '${user!.uid}.$fileExt';

      // 4. UPLOAD TO SUPABASE
      await supabase.storage
          .from('profile-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true, // Overwrite if exact name exists
              contentType: 'image/$fileExt',
            ),
          );

      // 5. GET URL
      final imageUrlPath = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Add "Cache Buster" (?v=timestamp) so Flutter knows to reload the image
      final finalUrl =
          '$imageUrlPath?v=${DateTime.now().millisecondsSinceEpoch}';

      // 6. SAVE TO FIRESTORE & AUTH PROFILE

      // A. Update Firebase User Profile (Instant Access)
      if (user != null) {
        await user!.updatePhotoURL(finalUrl);
      }

      // B. Update Firestore Database (Permanent Record)
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'profileImage': finalUrl,
        'last_updated': FieldValue.serverTimestamp(),
        'email': user!.email, // Useful to have email in DB too
      }, SetOptions(merge: true)); // MERGE: Don't overwrite other fields!

      // 7. Update UI
      if (mounted) {
        setState(() {
          _imageUrl = finalUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile picture updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        debugPrint('Upload Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    final String displayName = userData?['username'] ?? user?.displayName ?? 'User';
    final String email = userData?['email'] ?? user?.email ?? 'No email';
    final String phone = userData?['phone'] ?? 'No phone';
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 11, 53, 87)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: Color.fromARGB(255, 11, 53, 87), size: 26),
            SizedBox(width: 8),
            Text(
              "Profile",
              style: TextStyle(
                color: Color.fromARGB(255, 11, 53, 87),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              ).then((_) => _loadUserData()); // Reload data after edit
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
      onTap: _isUploading ? null : _uploadProfileImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Avatar Itself
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: _localImage != null
    ? FileImage(_localImage!)
    : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,

              child: _imageUrl == null
                  ? Icon(Icons.person, size: 80, color: Colors.grey[400])
                  : null,
            ),
          ),

          // Loading Overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),

          // Edit Badge (Camera Icon)
          if (!_isUploading)
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact Info Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: Color.fromARGB(255, 11, 53, 87),
                    ),
                    title: const Text("Email"),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.phone,
                      color: Color.fromARGB(255, 11, 53, 87),
                    ),
                    title: const Text("Phone"),
                    subtitle: Text(phone),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Account Settings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Account Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _optionItem(
              icon: Icons.shopping_bag,
              title: "My Requests",
              onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientRequestPage()),
                );
              },
            ),
            const SizedBox(height: 30),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    await _auth.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginFormLayout(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _optionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 11, 53, 87)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}