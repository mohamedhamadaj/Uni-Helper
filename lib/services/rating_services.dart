import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add Rating
  Future<void> addRating(RatingModel rating) async {
    try {
      // 1. Add rating to ratings collection
      await _firestore.collection('ratings').add(rating.toMap());

      // 2. Update provider's average rating
      await _updateProviderRating(rating.providerId);

      // 3. Update service's average rating
      await _updateServiceRating(rating.serviceId);

      // 4. Mark request as rated
      await _firestore.collection('requests').doc(rating.requestId).update({
        'isRated': true,
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // Update Provider Rating
  Future<void> _updateProviderRating(String providerId) async {
    try {
      var ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('providerId', isEqualTo: providerId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      double avgRating = totalRating / ratingsSnapshot.docs.length;
      int totalRatings = ratingsSnapshot.docs.length;

      await _firestore.collection('users').doc(providerId).update({
        'averageRating': avgRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      print('Error updating provider rating: $e');
    }
  }

  // Update Service Rating
  Future<void> _updateServiceRating(String serviceId) async {
    try {
      var ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('serviceId', isEqualTo: serviceId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      double avgRating = totalRating / ratingsSnapshot.docs.length;
      int totalRatings = ratingsSnapshot.docs.length;

      await _firestore.collection('services').doc(serviceId).update({
        'averageRating': avgRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      print('Error updating service rating: $e');
    }
  }

  // Get Provider Ratings
  Stream<List<RatingModel>> getProviderRatings(String providerId) {
    return _firestore
        .collection('ratings')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get Service Ratings
  Stream<List<RatingModel>> getServiceRatings(String serviceId) {
    return _firestore
        .collection('ratings')
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();
    });
  }

  // Check if Request is Rated
  Future<bool> isRequestRated(String requestId) async {
    var doc = await _firestore.collection('requests').doc(requestId).get();
    return doc.data()?['isRated'] ?? false;
  }
}