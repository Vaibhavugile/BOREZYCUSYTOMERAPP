import 'package:flutter/material.dart';
import 'dart:async';
import 'wishlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();

  /// 🔥 IDS (fast lookup)
  final Set<String> _wishlistIds = {};

  /// 🔥 FULL ITEMS (for UI)
  final List<Map<String, dynamic>> _wishlistItems = [];

  Set<String> get wishlistIds => _wishlistIds;

  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;

  StreamSubscription<QuerySnapshot>? _wishlistSub;

  /// 🔥 INIT (REAL-TIME SYNC)
  void initWishlist() {
    try {
      _wishlistSub?.cancel();

      _wishlistSub = _service.getWishlistStream().listen(
        (snapshot) {
          _wishlistIds.clear();
          _wishlistItems.clear();

          for (var doc in snapshot.docs) {
            try {
              final id = doc.id.toString();

              if (id.isEmpty) continue;

              final data = doc.data() as Map<String, dynamic>?;

              _wishlistIds.add(id);

              /// 🔥 store full product
              if (data != null) {
                _wishlistItems.add({
                  ...data,
                  "id": id,
                });
              }
            } catch (e) {
              debugPrint("Skipping bad wishlist doc: $e");
            }
          }

          notifyListeners();
        },
        onError: (error) {
          debugPrint("Wishlist stream error: $error");
        },
      );
    } catch (e) {
      debugPrint("Wishlist init error: $e");
    }
  }

  /// 🔥 TOGGLE
  Future<void> toggleById(String productId, Map product) async {
    try {
      final id = productId.toString();
      if (id.isEmpty) return;

      if (_wishlistIds.contains(id)) {
        /// ❌ REMOVE
        await _service.removeFromWishlist(id);

        _wishlistIds.remove(id);
        _wishlistItems.removeWhere((e) => e["id"] == id);

      } else {
        /// ✅ ADD
        await _service.addToWishlist(
          productId: id,
          product: Map<String, dynamic>.from(product),
        );

        _wishlistIds.add(id);

        _wishlistItems.add({
          ...product,
          "id": id,
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Wishlist toggle error: $e");
    }
  }

  /// 🔥 CHECK
  bool isWishlisted(String id) {
    return _wishlistIds.contains(id.toString());
  }

  /// 🔥 CLEAR
  void clearWishlist() {
    _wishlistIds.clear();
    _wishlistItems.clear();
    notifyListeners();
  }

  /// 🔥 RESET (DEBUG)
  Future<void> resetWishlist() async {
    try {
      _wishlistIds.clear();
      _wishlistItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Wishlist reset error: $e");
    }
  }

  /// 🔥 CLEANUP
  @override
  void dispose() {
    _wishlistSub?.cancel();
    super.dispose();
  }
}