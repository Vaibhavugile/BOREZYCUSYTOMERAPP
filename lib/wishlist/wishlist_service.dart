import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  /// ADD
  Future<void> addToWishlist(Map product) async {

    if (userId == null) return;

    await _firestore
        .collection("customers")
        .doc(userId)
        .collection("wishlist")
        .doc(product["name"]) // later use productId
        .set({
      ...product,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// REMOVE
  Future<void> removeFromWishlist(String productId) async {

    if (userId == null) return;

    await _firestore
        .collection("customers")
        .doc(userId)
        .collection("wishlist")
        .doc(productId)
        .delete();
  }

  /// CHECK
  Future<bool> isWishlisted(String productId) async {

    if (userId == null) return false;

    final doc = await _firestore
        .collection("customers")
        .doc(userId)
        .collection("wishlist")
        .doc(productId)
        .get();

    return doc.exists;
  }

  /// STREAM (for wishlist page)
  Stream<QuerySnapshot> getWishlistStream() {

    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("customers")
        .doc(userId)
        .collection("wishlist")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}