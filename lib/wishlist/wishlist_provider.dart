import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {

  final WishlistService _service = WishlistService();

  /// 🔥 Store wishlist IDs
  final Set<String> _wishlistIds = {};

  Set<String> get wishlistIds => _wishlistIds;

  /// 🔥 INIT (LOAD FROM FIRESTORE)
  Future<void> initWishlist() async {
    try {
      final snapshot = await _service.getWishlistStream().first;

      _wishlistIds.clear();

      for (var doc in snapshot.docs) {
        _wishlistIds.add(doc.id);
      }

      notifyListeners();

    } catch (e) {
      debugPrint("Wishlist init error: $e");
    }
  }

  /// 🔥 TOGGLE (ADD / REMOVE)
  Future<void> toggle(Map product) async {

    final id = product["name"]; // ⚠️ replace later with productId

    try {

      if (_wishlistIds.contains(id)) {

        await _service.removeFromWishlist(id);
        _wishlistIds.remove(id);

      } else {

        await _service.addToWishlist(product);
        _wishlistIds.add(id);
      }

      notifyListeners();

    } catch (e) {
      debugPrint("Wishlist toggle error: $e");
    }
  }

  /// 🔥 CHECK
  bool isWishlisted(String id) {
    return _wishlistIds.contains(id);
  }

  /// 🔥 CLEAR (for logout)
  void clearWishlist() {
    _wishlistIds.clear();
    notifyListeners();
  }
}