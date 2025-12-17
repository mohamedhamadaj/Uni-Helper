import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  String providerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Services",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("services")
            .where("providerId", isEqualTo: providerId)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You did not add any services yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var services = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              var doc = services[index];
              var data = doc.data() as Map<String, dynamic>;

              return _buildServiceCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  /// ----------- SERVICE CARD + REQUESTS -----------
  Widget _buildServiceCard(String serviceId, Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data["serviceName"],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              data["description"],
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  "${data["price"]} EGP",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Text(
                  data["deliveryTime"],
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ========== DELETE BUTTON ==========
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                    ),
                    onPressed: () {
                      _showDeleteDialog(serviceId);
                    },
                    child: const Text("Delete Service"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ========== REQUESTS SECTION ==========
            const Text(
              "Requests:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("requests")
                  .where("serviceId", isEqualTo: serviceId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, reqSnap) {
                if (reqSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!reqSnap.hasData || reqSnap.data!.docs.isEmpty) {
                  return const Text(
                    "No requests for this service yet.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                var requests = reqSnap.data!.docs;

                return Column(
                  children: requests.map((req) {
                    var r = req.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Description: ${r["description"]}"),
                          Text("Delivery Time: ${r["deliveryTime"]}"),
                          Text("Budget: ${r["budget"]}"),
                          const SizedBox(height: 6),
                          Text(
                            "Client ID: ${r["clientId"]}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- DELETE SERVICE ----------
  void _showDeleteDialog(String serviceId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Service"),
          content: const Text("Are you sure you want to delete this service?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("services")
                    .doc(serviceId)
                    .delete();

                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
