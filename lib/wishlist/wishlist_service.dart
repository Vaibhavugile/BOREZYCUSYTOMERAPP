import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';
import '../services/user_helper.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 GET USER ID (FROM LOCAL STORAGE)
  Future<String?> get userId async {
    return await UserHelper.getPhone();
  }

  /// 🔥 COLLECTION REFERENCE (FIXED - ASYNC)
  Future<CollectionReference<Map<String, dynamic>>> _wishlistRef() async {
    final branch = TenantConfig.branchCode;
    final id = await userId;

    return _firestore
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(id)
        .collection("wishlist");
  }

  /// 🔥 ADD TO WISHLIST
  Future<void> addToWishlist({
    required String productId,
    required Map<String, dynamic> product,
  }) async {
    final id = await userId;
    if (id == null) return;

    try {
      final ref = await _wishlistRef();

      await ref.doc(productId).set({
        ...product,
        "productId": productId,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to add to wishlist: $e");
    }
  }

  /// 🔥 REMOVE FROM WISHLIST
  Future<void> removeFromWishlist(String productId) async {
    final id = await userId;
    if (id == null) return;

    try {
      final ref = await _wishlistRef();
      await ref.doc(productId).delete();
    } catch (e) {
      throw Exception("Failed to remove from wishlist: $e");
    }
  }

  /// 🔥 CHECK (SINGLE DOC)
  Future<bool> isWishlisted(String productId) async {
    final id = await userId;
    if (id == null) return false;

    try {
      final ref = await _wishlistRef();
      final doc = await ref.doc(productId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 🔥 STREAM (REAL-TIME LIST)
  Stream<QuerySnapshot<Map<String, dynamic>>> getWishlistStream() async* {
    final id = await userId;

    if (id == null) {
      yield* const Stream.empty();
      return;
    }

    final branch = TenantConfig.branchCode;

    yield* _firestore
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(id)
        .collection("wishlist")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// 🔥 CLEAR ALL
  Future<void> clearWishlist() async {
    final id = await userId;
    if (id == null) return;

    final ref = await _wishlistRef();
    final snapshot = await ref.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}