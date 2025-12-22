import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ower_project/pages/Request_Page.dart';
import 'package:ower_project/pages/add_service_page.dart';
import 'package:ower_project/pages/request_list_page.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import '../widgets/rating_stars_widget.dart';
import '../services/rating_services.dart';
import '../models/rating_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RatingService _ratingService = RatingService();
  
  Map<String, dynamic>? userData;
  String? _imageUrl;
  File? _localImage; // لعرض الصورة فوراً قبل الرفع
  bool _isUploading = false;
  int totalServices = 0;
  int completedServices = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageUrl = user?.photoURL;
    _loadProviderData();
  }

  /// Helper function to delete old images before uploading a new one.
  /// This prevents unused files from piling up in your storage.
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

  

  Future<void> _loadProviderData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        final servicesSnapshot = await _firestore
            .collection('services')
            .where('providerId', isEqualTo: user.uid)
            .get();
        
        final completedSnapshot = await _firestore
            .collection('requests')
            .where('providerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Completed')
            .get();

        setState(() {
          userData = userDoc.data();
          totalServices = servicesSnapshot.docs.length;
          completedServices = completedSnapshot.docs.length;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Profile'),
          backgroundColor: const Color.fromARGB(255, 11, 53, 87),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    final String providerName = userData?['username'] ?? user?.displayName ?? 'Provider';
    final String email = userData?['email'] ?? user?.email ?? 'No email';
    final String phone = userData?['phone'] ?? 'No phone';
    final String initial = providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P';
    
    // Rating data
    final double avgRating = (userData?['averageRating'] ?? 0).toDouble();
    final int totalRatings = userData?['totalRatings'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 11, 53, 87)),
        centerTitle: true,
        title: const Text(
          'Provider Profile',
          style: TextStyle(
            color: Color.fromARGB(255, 11, 53, 87),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
              ).then((_) => _loadProviderData());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
              
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
  

            const SizedBox(height: 16),
            
            // Name
            Text(
              providerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 11, 53, 87),
              ),
            ),
            const SizedBox(height: 8),
            
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Service Provider',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // ⭐ RATING DISPLAY
            if (totalRatings > 0)
              RatingDisplay(
                rating: avgRating,
                totalRatings: totalRatings,
                starSize: 20,
              ),
            
            const SizedBox(height: 20),
            
            // Contact Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.email, "Email", email),
                    const Divider(),
                    _buildInfoRow(Icons.phone, "Phone", phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  "Total Services",
                  totalServices.toString(),
                  Icons.business_center,
                  Colors.blue,
                ),
                _buildStatCard(
                  "Completed",
                  completedServices.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // ⭐ RATINGS SECTION
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Client Reviews",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 11, 53, 87),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            StreamBuilder<List<RatingModel>>(
              stream: _ratingService.getProviderRatings(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No reviews yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final ratings = snapshot.data!;

                return Column(
                  children: ratings.take(5).map((rating) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    rating.clientName.isNotEmpty
                                        ? rating.clientName[0].toUpperCase()
                                        : "C",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 11, 53, 87),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rating.clientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(rating.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RatingStarsWidget(
                                  rating: rating.rating,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              rating.review,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (rating.serviceName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Service: ${rating.serviceName}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Quick Actions
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            _buildActionButton(
              icon: Icons.add_circle_outline,
              title: "Add New Service",
              color: Colors.green,
              onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServicePage()),
          );
        },
            ),
            const SizedBox(height: 10),
            
            _buildActionButton(
              icon: Icons.list_alt,
              title: "View My Services",
              color: Colors.blue,
            onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServiceListPage()),
          );
        },
            ),
            const SizedBox(height: 10),
            
            _buildActionButton(
              icon: Icons.request_page,
              title: "Service Requests",
              color: Colors.orange,
              onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestPage()),
                );
              },
            ),
            const SizedBox(height: 30),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 11, 53, 87)),
          const SizedBox(width: 16),
          Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}