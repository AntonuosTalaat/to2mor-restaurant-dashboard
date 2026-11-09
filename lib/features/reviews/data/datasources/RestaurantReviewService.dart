import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantdashboard/features/reviews/data/models/RestaurantReviewModel.dart';

class RestaurantReviewService {
  final FirebaseFirestore _firestore;

  RestaurantReviewService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const String _collection = 'userReviews';

  // Get reviews by restaurant ID (same as original service)
  Future<List<RestaurantReview>> getReviewsByRestaurantId(String restaurantId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .orderBy('restaurantRating')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting reviews by restaurant ID: $e');
      throw Exception('Failed to get restaurant reviews: $e');
    }
  }

  // Get reviews by restaurant ID with pagination
  Future<List<RestaurantReview>> getReviewsByRestaurantIdPaginated(
      String restaurantId, {
        int limit = 10,
        DocumentSnapshot? startAfter,
      }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .orderBy('restaurantRating')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting paginated reviews: $e');
      throw Exception('Failed to get restaurant reviews: $e');
    }
  }

  // Get restaurant average rating
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .get();

      if (querySnapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      int count = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['restaurantRating']?.toDouble();
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }

      return count > 0 ? totalRating / count : 0.0;
    } catch (e) {
      print('Error getting restaurant average rating: $e');
      return 0.0;
    }
  }

  // Get restaurant review statistics
  Future<Map<String, dynamic>> getRestaurantReviewStats(String restaurantId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }

      double totalRating = 0.0;
      Map<String, int> ratingDistribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['restaurantRating']?.toDouble();
        if (rating != null) {
          totalRating += rating;
          String ratingKey = rating.round().toString();
          if (ratingDistribution.containsKey(ratingKey)) {
            ratingDistribution[ratingKey] = ratingDistribution[ratingKey]! + 1;
          }
        }
      }

      int totalReviews = querySnapshot.docs.length;
      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting restaurant review statistics: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
        },
      };
    }
  }

  // Search reviews by customer name or order ID
  Future<List<RestaurantReview>> searchRestaurantReviews(
      String restaurantId, {
        String? customerName,
        String? orderId,
        double? minRating,
        double? maxRating,
      }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null);

      if (customerName != null && customerName.isNotEmpty) {
        query = query.where('userName', isEqualTo: customerName);
      }

      if (orderId != null && orderId.isNotEmpty) {
        query = query.where('orderId', isEqualTo: orderId);
      }

      QuerySnapshot querySnapshot = await query
          .orderBy('restaurantRating')
          .orderBy('createdAt', descending: true)
          .get();

      List<RestaurantReview> reviews = querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Filter by rating range if specified
      if (minRating != null || maxRating != null) {
        reviews = reviews.where((review) {
          bool meetsMin = minRating == null || review.restaurantRating >= minRating;
          bool meetsMax = maxRating == null || review.restaurantRating <= maxRating;
          return meetsMin && meetsMax;
        }).toList();
      }

      return reviews;
    } catch (e) {
      print('Error searching restaurant reviews: $e');
      throw Exception('Failed to search reviews: $e');
    }
  }

  // Get recent reviews (last 30 days)
  Future<List<RestaurantReview>> getRecentReviews(String restaurantId, {int days = 30}) async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));

      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .where('createdAt', isGreaterThanOrEqualTo: cutoffDate.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting recent reviews: $e');
      throw Exception('Failed to get recent reviews: $e');
    }
  }

  // Get reviews by rating
  Future<List<RestaurantReview>> getReviewsByRating(
      String restaurantId,
      double rating
      ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isEqualTo: rating)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting reviews by rating: $e');
      throw Exception('Failed to get reviews by rating: $e');
    }
  }

  // Get reviews with comments only
  Future<List<RestaurantReview>> getReviewsWithComments(String restaurantId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('restaurantRating', isNotEqualTo: null)
          .orderBy('restaurantRating')
          .orderBy('createdAt', descending: true)
          .get();

      List<RestaurantReview> reviews = querySnapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Filter reviews that have comments
      return reviews.where((review) =>
      (review.restaurantComment != null && review.restaurantComment!.isNotEmpty)
      ).toList();
    } catch (e) {
      print('Error getting reviews with comments: $e');
      throw Exception('Failed to get reviews with comments: $e');
    }
  }

  // Delete review (if restaurant owner has permission)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      throw Exception('Failed to delete review: $e');
    }
  }

  // Stream reviews for real-time updates
  Stream<List<RestaurantReview>> streamRestaurantReviews(String restaurantId) {
    return _firestore
        .collection(_collection)
        .where('restaurantId', isEqualTo: restaurantId)
        .where('restaurantRating', isNotEqualTo: null)
        .orderBy('restaurantRating')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestaurantReview.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }
}