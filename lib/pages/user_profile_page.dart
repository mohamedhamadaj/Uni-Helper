import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ower_project/pages/service_detail_page.dart';
import 'package:ower_project/sendEmail/sendEmail.dart';
import '../widgets/rating_stars_widget.dart';
import '../services/rating_services.dart';
class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final RatingService ratingService = RatingService();

    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Provider Profile"),
        backgroundColor: const Color.fromARGB(255, 11, 53, 87),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          String name = data["username"] ?? data["name"] ?? "Unknown User";
          String email = data["email"] ?? "No email";
          String role = data["role"] ?? "User";
          String? profileImage = data["profileImage"];
          
          // ⭐ الـ Rating الصح
          double avgRating = (data["averageRating"] ?? 0).toDouble();
          int totalRatings = data["totalRatings"] ?? 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- HEADER ----------
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 11, 53, 87),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage)
                            : null,
                        backgroundColor: Colors.white,
                        child: profileImage == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          sendEmail(email);
                        },
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      
                      // ⭐ RATING في الـ Header
                      if (role == "Provider" && totalRatings > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: RatingDisplay(
                            rating: avgRating,
                            totalRatings: totalRatings,
                            starSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---------- USER INFO ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ), 
                      ),
                    ),
                // ---------- RATING STATS ----------
                if (role == "Provider" && totalRatings > 0) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "$totalRatings reviews",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // ---------- SERVICES ----------
                if (role == "Provider") ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 11, 53, 87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("services")
                        .where("providerId", isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final services = snapshot.data!.docs;

                      if (services.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text("No services available."),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: services.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final service = services[index].data()
                              as Map<String, dynamic>;
                          
                          final serviceName = service["serviceName"] ?? 
                                            service["name"] ?? 
                                            "Service";
                          final description = service["description"] ?? "";
                          final price = service["price"]?.toString() ?? "N/A";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.build,
                                  size: 28,
                                  color: Color.fromARGB(255, 11, 53, 87),
                                ),
                              ),
                              title: Text(
                                serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServicesDetailsPage(
                                      serviceId: services[index].id,
                                      serviceData: service,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}