import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ower_project/pages/user_profile_page.dart';
import 'package:ower_project/sendEmail/sendEmail.dart';


class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  String providerId = FirebaseAuth.instance.currentUser!.uid;

  /// change status logic
  Future<void> changeStatus(String requestId, String currentStatus) async {
    String newStatus = currentStatus;

    if (currentStatus == "Pending") {
      newStatus = "In Progress";
    } else if (currentStatus == "In Progress") {
      newStatus = "Completed";
    } else {
      newStatus = "Pending";
    }

    await FirebaseFirestore.instance
        .collection("requests")
        .doc(requestId)
        .update({"status": newStatus});
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "In Progress":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Service Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),
      backgroundColor: Colors.grey[100],

      // Get provider requests only
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("providerId", isEqualTo: providerId)
            
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No requests yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              var data = request.data() as Map<String, dynamic>;

              final clientName = data["clientName"] ?? "Unknown";
              final clientEmail = data["clientEmail"] ?? "No email";
              final clientPhone = data["clientPhone"] ?? "No phone";
              final serviceName = data["serviceName"] ?? "Unknown service";
              final description = data["description"] ?? "";
              final clientId = data["clientId"] ?? "";
              final status = data["status"] ?? "Pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: primaryColor),
                          const SizedBox(width: 8),
                          InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                        userId: data["clientId"] ?? "",
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 11, 53, 87),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          const Spacer(),

                          /// STATUS BUTTON
                          GestureDetector(
                            onTap: () => changeStatus(request.id, status),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
  onTap: () {
    sendEmail(clientEmail);
  },
  child: Text(
    clientEmail,
    style: const TextStyle(
      color: Colors.blue,
    ),
  ),
)
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 4),
                          Text(clientPhone),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.build, size: 16),
                          const SizedBox(width: 4),
                          Text(serviceName),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
