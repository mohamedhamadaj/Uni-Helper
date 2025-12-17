import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id; // Document ID from Firestore
  final String providerId; // UID of the provider
  final String title;
  final String? description;
  final double? price;
  final String? duration;
  final List<String> features;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.providerId,
    required this.title,
    this.description,
    this.price,
    this.duration,
    this.features = const [],
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore Document to Service object
  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Service(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      price: data['price']?.toDouble(),
      duration: data['duration'],
      features: data['features'] != null 
          ? List<String>.from(data['features']) 
          : [],
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Service object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'features': features,
      'isDone': isDone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // For updating existing service
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'features': features,
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for easy updates
  Service copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    double? price,
    String? duration,
    List<String>? features,
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      features: features ?? this.features,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}