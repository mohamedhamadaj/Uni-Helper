import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String requestId;
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String providerName;
  final String clientId;
  final String clientName;
  final double rating; // 1-5
  final String review;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.requestId,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.providerName,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  // Convert from Firestore
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RatingModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      review: data['review'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'providerId': providerId,
      'providerName': providerName,
      'clientId': clientId,
      'clientName': clientName,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}