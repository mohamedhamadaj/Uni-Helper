import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_service_page.dart';
import 'add_service_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  final String providerId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> deleteService(String id) async {
    await FirebaseFirestore.instance.collection("services").doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Service Deleted")));
  }

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

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServicePage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection("services")
    .where("providerId", isEqualTo: providerId)
    .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No services added yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              var data = services[index].data() as Map<String, dynamic>;
              String id = services[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    data["name"] ?? "Unnamed Service",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data["description"] ?? "No Description"),
                      const SizedBox(height: 6),
                      Text("Price: ${data["price"] ?? "-"} EGP"),
                      Text("Delivery: ${data["deliveryTime"] ?? "-"}"),
                    ],
                  ),

                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == "edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditServicePage(
                              serviceId: id,
                              existingData: data,
                            ),
                          ),
                        );
                      } else if (value == "delete") {
                        deleteService(id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: primaryColor),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete"),
                          ],
                        ),
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
