import 'package:flutter/material.dart';
import 'dart:async';
import 'wishlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';


class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();

  final Set<String> _wishlistIds = {};

  Set<String> get wishlistIds => _wishlistIds;

  StreamSubscription<QuerySnapshot>? _wishlistSub;

  /// 🔥 INIT (REAL-TIME SYNC + SAFE)
  void initWishlist() {
    try {
      _wishlistSub?.cancel();

      _wishlistSub = _service.getWishlistStream().listen(
        (snapshot) {
          _wishlistIds.clear();

          for (var doc in snapshot.docs) {
            try {
              // 🔥 FORCE STRING + SAFETY
              final id = doc.id.toString();

              if (id.isNotEmpty) {
                _wishlistIds.add(id);
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

  /// 🔥 TOGGLE (SAFE)
  Future<void> toggleById(String productId, Map product) async {
    try {
      final id = productId.toString();

      if (id.isEmpty) return;

      if (_wishlistIds.contains(id)) {
        await _service.removeFromWishlist(id);
        _wishlistIds.remove(id);
      } else {
        await _service.addToWishlist(
          productId: id,
          product: Map<String, dynamic>.from(product),
        );
        _wishlistIds.add(id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Wishlist toggle error: $e");
    }
  }

  /// 🔥 CHECK (SAFE)
  bool isWishlisted(String id) {
    return _wishlistIds.contains(id.toString());
  }

  /// 🔥 CLEAR
  void clearWishlist() {
    _wishlistIds.clear();
    notifyListeners();
  }

  /// 🔥 FORCE RESET (VERY USEFUL FOR DEBUG)
  Future<void> resetWishlist() async {
    try {
      _wishlistIds.clear();
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