import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ower_project/pages/service_detail_page.dart';
import 'package:ower_project/sendEmail/sendEmail.dart'; // ← تأكد من المسار الصحيح

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(userId);

    final servicesRef = FirebaseFirestore.instance
        .collection("services")
        .where("providerId", isEqualTo: userId);

    return Scaffold(
      backgroundColor: Color(0xfff4f6fa),

      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Color.fromARGB(255, 11, 53, 87),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: userRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          String name = data["username"] ?? "Unknown User";
          String email = data["email"] ?? "No email";
          String role = data["role"] ?? "User";
          double rating =
              double.tryParse(data["rating"]?.toString() ?? "0") ?? 0;
          String? profileImage = data["profileImage"];

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
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.grey)
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

                    InkWell(
  onTap: () {
    sendEmail(email);  // ← دالة الإرسال جاهزة عندك
  },
  child: Text(
    email,
    style: const TextStyle(
      color: Color.fromARGB(255, 255, 255, 255),            // شكله لينك
      fontSize: 14,
    ),
  ),
),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---------- USER INFO ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Role:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(
                              role,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: role == "Provider"
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------- RATING ----------
                if (role == "Provider") ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // ---------- SERVICES ----------
                if (role == "Provider") ...[
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Services",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: servicesRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final services = snapshot.data!.docs;

                      if (services.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No services available."),
                        );
                      }

                      return ListView.builder(
                        itemCount: services.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final service = services[index].data()
                              as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Card(
                              elevation: 3,
                              child: ListTile(
                                leading: const Icon(Icons.build, size: 32),
                                title: Text(service["name"] ?? "Service"),
                                subtitle:
                                    Text(service["description"] ?? ""),

                                // 🚀🚀🚀 HERE: Go To Service Details
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ServicesDetailsPage(
                                              serviceData: service),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
