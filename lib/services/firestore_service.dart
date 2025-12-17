import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service.dart';
import '../models/request.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== SERVICES ====================
  
  // Add new service (Provider only)
  Future<String?> addService(Service service) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docRef = await _firestore.collection('services').add(service.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding service: $e');
      return null;
    }
  }

  // Update existing service
  Future<bool> updateService(String serviceId, Service service) async {
    try {
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update(service.toUpdateMap());
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // Get all services (for all users to browse)
  Stream<List<Service>> getAllServices() {
    return _firestore
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  // Get services by provider (for provider's own services)
  Stream<List<Service>> getProviderServices(String providerId) {
    return _firestore
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  // Get single service by ID
  Future<Service?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return Service.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting service: $e');
      return null;
    }
  }

  // ==================== REQUESTS ====================
  
  // Create new request (Client)
  Future<String?> createRequest(ServiceRequest request) async {
    try {
      final docRef = await _firestore.collection('requests').add(request.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating request: $e');
      return null;
    }
  }

  // Update request status (Provider)
  Future<bool> updateRequestStatus(
    String requestId, 
    String status, 
    {String? providerId}
  ) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (providerId != null) {
        updateData['providerId'] = providerId;
      }

      await _firestore.collection('requests').doc(requestId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating request: $e');
      return false;
    }
  }

  // Get all requests (for providers to see)
  Stream<List<ServiceRequest>> getAllRequests() {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequest.fromFirestore(doc))
          .toList();
    });
  }

  // Get requests by client (for client to see their own requests)
  Stream<List<ServiceRequest>> getClientRequests(String clientId) {
    return _firestore
        .collection('requests')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequest.fromFirestore(doc))
          .toList();
    });
  }

  // Get requests by provider (requests accepted by this provider)
  Stream<List<ServiceRequest>> getProviderRequests(String providerId) {
    return _firestore
        .collection('requests')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequest.fromFirestore(doc))
          .toList();
    });
  }

  // Get requests by status
  Stream<List<ServiceRequest>> getRequestsByStatus(String status) {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequest.fromFirestore(doc))
          .toList();
    });
  }

  // Get single request by ID
  Future<ServiceRequest?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (doc.exists) {
        return ServiceRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting request: $e');
      return null;
    }
  }

  // Delete request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }

  // ==================== USER INFO ====================
  
  // Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user is provider
  Future<bool> isProvider() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == 'Provider';
  }

  // Check if user is client
  Future<bool> isClient() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == 'Client';
  }
}