import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_list_page.dart';
import 'service_detail_page.dart';
import 'profile_page.dart';
import 'Request_Page.dart';
import 'login_page.dart';
import 'client_request_page.dart';
import '../widgets/rating_stars_widget.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  List<Map<String, dynamic>> allServices = [];
  List<Map<String, dynamic>> filteredServices = [];

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  /// Load services from Firestore
  Future<void> fetchServices() async {
    var snapshot = await FirebaseFirestore.instance
        .collection("services")
        .orderBy("timestamp", descending: true)
        .get();

    List<Map<String, dynamic>> temp = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      data["id"] = doc.id; // ← مهم جداً
      temp.add(data);
    }

    setState(() {
      allServices = temp;
      filteredServices = temp;
    });
  }

  /// Search filter
  void _filterServices(String query) {
    setState(() {
      filteredServices = allServices.where((service) {
        final name = (service["serviceName"] ?? service["name"] ?? "").toLowerCase();
        final desc = (service["description"] ?? "").toLowerCase();
        query = query.toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRoleBadge(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            const Text(
              "Featured Services",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredServices.isEmpty
                  ? const Center(child: Text("No services found"))
                  : ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        return _buildServiceCard(filteredServices[index], context);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- UI WIDGETS BELOW ---------------------

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.role == 'Provider'
            ? Colors.green.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.role == 'Provider' ? Icons.business : Icons.person,
            size: 16,
            color: widget.role == 'Provider' ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            'Logged in as ${widget.role}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.role == 'Provider' ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: _filterServices,
      decoration: InputDecoration(
        hintText: "Search services...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: primaryColor),
      centerTitle: true,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: primaryColor),
          SizedBox(width: 8),
          Text(
            "Uni Helper",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Uni Helper",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.role == 'Provider') ...[
            _buildSectionTitle("Provider Menu"),
            _buildDrawerItem(Icons.list, "My Services", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ServiceListPage()));
            }),
            _buildDrawerItem(Icons.request_page, "Service Requests", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => RequestPage()));
            }),
          ],

          if (widget.role == 'Client') ...[
            _buildSectionTitle("Client Menu"),
            _buildDrawerItem(Icons.shopping_bag, "My Requests", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ClientRequestPage()));
            }),
          ],

          _buildSectionTitle("Profile"),
          _buildDrawerItem(Icons.person, "My Profile", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage()));
          }),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginFormLayout()),
                    (route) => false,
                  );
                }
              },
              child: const Text("Logout"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, BuildContext context) {
    final serviceName = service['serviceName'] ?? service['name'] ?? "Service";
    final description = service['description'] ?? "";
    final price = service['price']?.toString() ?? "N/A";
    final deliveryTime = service['deliveryTime'] ?? "N/A";
    final serviceId = service['id'] ?? "";
    
    // Rating data
    final double avgRating = (service['averageRating'] ?? 0).toDouble();
    final int totalRatings = service['totalRatings'] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Name
            Text(
              serviceName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            
            // Rating
            if (totalRatings > 0) ...[
              RatingDisplay(
                rating: avgRating,
                totalRatings: totalRatings,
                starSize: 16,
              ),
              const SizedBox(height: 6),
            ],
            
            // Description
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            
            // Price & Time
            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(deliveryTime),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
                      foregroundColor: primaryColor,
                    ),
                    child: const Text("View Details"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServicesDetailsPage(
                            serviceId: serviceId, // ← الحل هنا!
                            serviceData: service,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                if (widget.role == 'Client')
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                      ),
                      child: const Text("Request Now"),
                      onPressed: () {
                        _showRequestDialog(context, service);
                      },
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================= SEND REQUEST TO FIRESTORE ===================

  void _showRequestDialog(BuildContext context, Map<String, dynamic> service) {
    final desc = TextEditingController();
    final time = TextEditingController();
    final budget = TextEditingController();

    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Request ${service['serviceName'] ?? service['name']}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Describe your request...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(
                    labelText: "Delivery Time",
                    hintText: "ex: 3 days",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budget,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Budget",
                    hintText: "ex: 200 EGP",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                if (desc.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please add a description!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  // Get CLIENT data
                  final clientSnapshot = await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user!.uid)
                      .get();

                  final clientData = clientSnapshot.data() ?? {};
                  final clientName = clientData["username"] ?? clientData["name"] ?? "Unknown";
                  final clientEmail = clientData["email"] ?? user.email ?? "";
                  final clientPhone = clientData["phone"] ?? "No phone";

                  // Get PROVIDER data
                  final providerName  = service["providerName"] ?? "Unknown";
final providerEmail = service["providerEmail"] ?? "";
final providerPhone = service["providerPhone"] ?? "No phone";

                  // Save request to Firestore
                  await FirebaseFirestore.instance.collection("requests").add({
                    "clientId": user.uid,
                    "clientName": clientName,
                    "clientEmail": clientEmail,
                    "clientPhone": clientPhone,

                    "providerId": service["providerId"],
                    "providerName": providerName,
                    "providerEmail": providerEmail,
                    "providerPhone": providerPhone,

                    "serviceId": service["id"],
                    "serviceName": service["serviceName"] ?? service["name"],

                    "description": desc.text.trim(),
                    "deliveryTime": time.text.trim(),
                    "budget": budget.text.trim(),

                    "status": "Pending",
                    "isRated": false,
                    "timestamp": FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Request sent successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Send Request"),
            ),
          ],
        );
      },
    );
  }
}