import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ower_project/pages/user_list_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // ---------- Fetch stats from Firebase ----------
  Future<Map<String, dynamic>> getStats() async {
    final users = FirebaseFirestore.instance.collection("users");
    final services = FirebaseFirestore.instance.collection("services");

    int totalUsers = (await users.get()).docs.length;
    int totalProviders =
        (await users.where("role", isEqualTo: "Provider").get()).docs.length;
    int totalClients =
        (await users.where("role", isEqualTo: "Client").get()).docs.length;

    int totalServices = (await services.get()).docs.length;

    return {
      "users": totalUsers,
      "providers": totalProviders,
      "clients": totalClients,
      "services": totalServices,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 187, 161, 226),
      ),

      body: FutureBuilder(
        future: getStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Overview",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ===== GRID CARDS =====
                Expanded(
                  child: GridView(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    children: [
                      // USERS
                      _buildDashboardCard(
                        title: "Total Users",
                        value: stats["users"].toString(),
                        icon: Icons.people_alt,
                        color: Colors.blue,
                      ),

                      // PROVIDERS
                      _buildDashboardCard(
                        title: "Providers",
                        value: stats["providers"].toString(),
                        icon: Icons.engineering_rounded,
                        color: Colors.green,
                      ),

                      // CLIENTS
                      _buildDashboardCard(
                        title: "Clients",
                        value: stats["clients"].toString(),
                        icon: Icons.person_outline,
                        color: Colors.orange,
                      ),

                      // SERVICES
                      _buildDashboardCard(
                        title: "Services",
                        value: stats["services"].toString(),
                        icon: Icons.build_circle,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== USERS BUTTON =====
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersListPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: const Text(
                    "View All Users",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),

// ===== LOGOUT BUTTON =====
ElevatedButton.icon(
  onPressed: () async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login", // غيرها لاسم صفحة اللوجين عندك
      (route) => false,
    );
  },
  icon: const Icon(Icons.logout, color: Colors.white),
  label: const Text(
    "Logout",
    style: TextStyle(fontSize: 16, color: Colors.white),
  ),
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    backgroundColor: Colors.redAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),

              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Dashboard Card Widget ----------
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 34),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
