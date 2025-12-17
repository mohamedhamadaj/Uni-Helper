import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController deliveryController = TextEditingController();

  bool loading = false;

  Future<void> saveService() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final providerId = user.uid;

    // -------- GET PROVIDER DATA FROM FIRESTORE --------
    final providerData = await FirebaseFirestore.instance
        .collection("users")
        .doc(providerId)
        .get();

    final providerName = providerData["username"] ?? "";
    final providerEmail = providerData["email"] ?? "";
    final providerPhone = providerData["phone"] ?? "";

    // -------- SAVE SERVICE WITH PROVIDER NAME + EMAIL --------
    await FirebaseFirestore.instance.collection("services").add({
      "providerId": providerId,
      "providerName": providerName,
      "providerEmail": providerEmail,
      "providerPhone": providerPhone, 

      "name": nameController.text,
      "description": descriptionController.text,
      "price": priceController.text,
      "category": categoryController.text,
      "deliveryTime": deliveryController.text,

      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Service Added")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Service",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Service Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(labelText: "Price (ex: 200 EGP)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deliveryController,
              decoration:
                  const InputDecoration(labelText: "Delivery Time"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: loading ? null : saveService,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Service"),
            )
          ],
        ),
      ),
    );
  }
}
