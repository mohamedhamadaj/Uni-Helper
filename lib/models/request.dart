import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  final String id; // Document ID from Firestore
  final String clientId; // UID of the client who made the request
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String serviceId; // ID of the service being requested (optional)
  final String serviceType; // Type/name of service
  final String description;
  final String? budget;
  final String? timeline;
  final String status; // Pending, In Progress, Completed, Rejected
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? providerId; // Provider who accepted the request

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    this.serviceId = '',
    required this.serviceType,
    required this.description,
    this.budget,
    this.timeline,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
    this.providerId,
  });

  // Convert Firestore Document to ServiceRequest object
  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ServiceRequest(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      budget: data['budget'],
      timeline: data['timeline'],
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      providerId: data['providerId'],
    );
  }

  // Convert ServiceRequest object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'serviceId': serviceId,
      'serviceType': serviceType,
      'description': description,
      'budget': budget,
      'timeline': timeline,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'providerId': providerId,
    };
  }

  // For updating status or other fields
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status,
      'providerId': providerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method
  ServiceRequest copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? serviceId,
    String? serviceType,
    String? description,
    String? budget,
    String? timeline,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? providerId,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      serviceId: serviceId ?? this.serviceId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      timeline: timeline ?? this.timeline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerId: providerId ?? this.providerId,
    );
  }

  // Helper getters
  bool get isPending => status == 'Pending';
  bool get isInProgress => status == 'In Progress';
  bool get isCompleted => status == 'Completed';
  bool get isRejected => status == 'Rejected';
}