import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ower_project/sendEmail/sendEmail.dart';

class ClientRequestPage extends StatefulWidget {
  const ClientRequestPage({super.key});

  @override
  State<ClientRequestPage> createState() => _ClientRequestPageState();
}

class _ClientRequestPageState extends State<ClientRequestPage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  String clientId = FirebaseAuth.instance.currentUser!.uid;

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
          "My Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),
      backgroundColor: Colors.grey[100],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("clientId", isEqualTo: clientId)
            .snapshots(), // 🔥 شيلنا orderBy علشان ميتطلبش index
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You have no requests.",
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

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, color: primaryColor),
                          const SizedBox(width: 8),

                          Text(
                            data["serviceName"] ?? "",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: getStatusColor(data["status"] ?? "Pending")
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data["status"] ?? "Pending",
                              style: TextStyle(
                                color:
                                    getStatusColor(data["status"] ?? "Pending"),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text("Provider: ${data["providerName"] ?? ""}"),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
  children: [
    GestureDetector(
      onTap: () {
        sendEmail(data["providerEmail"]); // ← دي الدالة اللي انت عاملها برا
      },
      child: const Icon(Icons.email, size: 18, color: Color.fromARGB(255, 0, 69, 125)),
    ),
    const SizedBox(width: 6),
    Text(data["providerEmail"] ?? ""),
  ],
),


                      const SizedBox(height: 8),

                      Text(
                        data["description"] ?? "",
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
