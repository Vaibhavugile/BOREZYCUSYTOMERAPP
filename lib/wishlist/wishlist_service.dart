import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  /// 🔥 COLLECTION REFERENCE (clean + reusable)
  CollectionReference<Map<String, dynamic>> _wishlistRef() {
    return _firestore
        .collection("customers")
        .doc(userId)
        .collection("wishlist");
  }

  /// 🔥 ADD TO WISHLIST (USING PRODUCT ID)
  Future<void> addToWishlist({
    required String productId,
    required Map<String, dynamic> product,
  }) async {
    if (userId == null) return;

    try {
      await _wishlistRef().doc(productId).set({
        ...product,
        "productId": productId, // ✅ store explicitly
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to add to wishlist: $e");
    }
  }

  /// 🔥 REMOVE FROM WISHLIST
  Future<void> removeFromWishlist(String productId) async {
    if (userId == null) return;

    try {
      await _wishlistRef().doc(productId).delete();
    } catch (e) {
      throw Exception("Failed to remove from wishlist: $e");
    }
  }

  /// 🔥 CHECK (SINGLE DOC)
  Future<bool> isWishlisted(String productId) async {
    if (userId == null) return false;

    try {
      final doc = await _wishlistRef().doc(productId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 🔥 STREAM (REAL-TIME LIST)
  Stream<QuerySnapshot<Map<String, dynamic>>> getWishlistStream() {
    if (userId == null) {
      return const Stream.empty();
    }

    return _wishlistRef()
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// 🔥 OPTIONAL: CLEAR ALL (for logout)
  Future<void> clearWishlist() async {
    if (userId == null) return;

    final snapshot = await _wishlistRef().get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}