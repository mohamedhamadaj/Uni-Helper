import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditServicePage extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> existingData;

  const EditServicePage({
    super.key,
    required this.serviceId,
    required this.existingData,
  });

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  static const primaryColor = Color.fromARGB(255, 11, 53, 87);

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController categoryController;
  late TextEditingController deliveryController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.existingData["name"]);
    descriptionController =
        TextEditingController(text: widget.existingData["description"]);
    priceController =
        TextEditingController(text: widget.existingData["price"]);
    categoryController =
        TextEditingController(text: widget.existingData["category"]);
    deliveryController =
        TextEditingController(text: widget.existingData["deliveryTime"]);
  }

  Future<void> updateService() async {
    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection("services")
        .doc(widget.serviceId)
        .update({
      "name": nameController.text,
      "description": descriptionController.text,
      "price": priceController.text,
      "category": categoryController.text,
      "deliveryTime": deliveryController.text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Service Updated")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Service",
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
              decoration: const InputDecoration(labelText: "Price"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deliveryController,
              decoration: const InputDecoration(labelText: "Delivery Time"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: loading ? null : updateService,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update Service"),
            )
          ],
        ),
      ),
    );
  }
}
