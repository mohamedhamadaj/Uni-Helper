import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ower_project/pages/user_profile_page.dart';
import 'package:ower_project/sendEmail/sendEmail.dart';
import '../widgets/rating_stars_widget.dart';

class ServicesDetailsPage extends StatelessWidget {
  final String serviceId; // ← الـ ID الصح
  final Map<String, dynamic> serviceData;

  const ServicesDetailsPage({
    super.key,
    required this.serviceId,
    required this.serviceData,
  });

  @override
  Widget build(BuildContext context) {
    final String providerName = serviceData['providerName'] ?? "Unknown Provider";
    final String providerEmail = serviceData['providerEmail'] ?? "No Email";
    final String providerPhone = serviceData['providerPhone'] ?? "No Phone Number";
    final String price = serviceData['price']?.toString() ?? "Not specified";
    final String deliveryTime = serviceData['deliveryTime'] ?? "Not specified";
    final String fullDescription = serviceData['fullDescription'] ??
        serviceData['description'] ??
        "No detailed description was provided for this service.";
    final List<dynamic> features = serviceData['features'] ??
        [
          "High-quality output",
          "Fast delivery",
          "24/7 Support",
          "Customizable solutions",
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceData['serviceName'] ?? serviceData['name'] ?? "Service"),
        backgroundColor: const Color.fromARGB(255, 17, 139, 239),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Service Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 11, 53, 87).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.build,
                    size: 60,
                    color: Color.fromARGB(255, 11, 53, 87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    serviceData['serviceName'] ?? serviceData['name'] ?? "Service Name",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 11, 53, 87),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    serviceData['category'] ?? "No category",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  // ⭐ SERVICE RATING (Real-time from Firestore)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('services')
                        .doc(serviceId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final double avgRating = (data?['averageRating'] ?? 0).toDouble();
                        final int totalRatings = data?['totalRatings'] ?? 0;

                        if (totalRatings > 0) {
                          return RatingDisplay(
                            rating: avgRating,
                            totalRatings: totalRatings,
                            starSize: 22,
                          );
                        }
                      }
                      return const Text(
                        "No ratings yet",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ---------------- Provider Info ----------------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Color.fromARGB(255, 11, 53, 87),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                        userId: serviceData["providerId"] ?? "",
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  providerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 11, 53, 87),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  sendEmail(providerEmail);
                                },
                                child: Text(
                                  providerEmail,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 1, 70, 126),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                providerPhone,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- Service Info ----------------
            _buildInfoCard(
              title: 'Price',
              value: price,
              icon: Icons.attach_money,
            ),
            _buildInfoCard(
              title: 'Delivery Time',
              value: deliveryTime,
              icon: Icons.timer,
            ),

            const SizedBox(height: 20),

            // ---------------- Description ----------------
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 11, 53, 87),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- Features ----------------
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 11, 53, 87),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.toString(),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // ⭐ REVIEWS SECTION (Real-time)
            const Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 11, 53, 87),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ratings')
                  .where('serviceId', isEqualTo: serviceId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Error loading reviews: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No reviews yet. Be the first to review!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final ratings = snapshot.data!.docs;

                // Sort manually in code instead of Firestore
                final sortedRatings = ratings.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'doc': doc,
                    'data': data,
                    'timestamp': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  };
                }).toList();

                sortedRatings.sort((a, b) => 
                  (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime)
                );

                return Column(
                  children: sortedRatings.map((item) {
                    final data = item['data'] as Map<String, dynamic>;
                    final clientName = data['clientName'] ?? "Anonymous";
                    final rating = (data['rating'] ?? 0).toDouble();
                    final review = data['review'] ?? "";
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

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
                                    clientName.isNotEmpty
                                        ? clientName[0].toUpperCase()
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
                                        clientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RatingStarsWidget(
                                  rating: rating,
                                  size: 18,
                                ),
                              ],
                            ),
                            if (review.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                review,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 11, 53, 87)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}