import 'package:flutter/material.dart';
import 'package:ower_project/pages/user_profile_page.dart';
import 'package:ower_project/sendEmail/sendEmail.dart';


class ServicesDetailsPage extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const ServicesDetailsPage({
    super.key,
    required this.serviceData,
  });

  @override
  Widget build(BuildContext context) {
    final String providerName = serviceData['providerName'] ?? "Unknown Provider";
    final String providerEmail = serviceData['providerEmail'] ?? "No Email";
    final String providerPhone = serviceData['providerPhone'] ?? "No Phone Number";

    final String price = serviceData['price']?.toString() ?? "Not specified";
    final String deliveryTime = serviceData['deliveryTime'] ?? "Not specified";
    final String rating = serviceData['rating']?.toString() ?? "Not rated";

    final String fullDescription = serviceData['fullDescription'] ??
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
        title: Text(serviceData['name'] ?? "Service"),
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
                  Icon(
                    Icons.build,
                    size: 60,
                    color: const Color.fromARGB(255, 11, 53, 87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    serviceData['name'] ?? "Service Name",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 11, 53, 87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    serviceData['category'] ?? "No category",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userId: serviceData["providerId"],  // ← مهم جداً
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
      decoration: TextDecoration.underline,   // شكل لينك
    ),
  ),
),

                            const SizedBox(height: 4),
                            InkWell(
  onTap: () {
    sendEmail(providerEmail);  // ← دالة الإرسال جاهزة عندك
  },
  child: Text(
    providerEmail,
    style: const TextStyle(
      color: Color.fromARGB(255, 1, 70, 126),            // شكله لينك
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
            _buildInfoCard(
              title: 'Rating',
              value: "$rating ⭐",
              icon: Icons.star,
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
                      Icon(Icons.check_circle,
                          color: Colors.green[600], size: 20),
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
