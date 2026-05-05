import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';

class HomeProvider extends ChangeNotifier {

  bool isLoading = false;
  bool isLoaded = false;

  List<Map<String, dynamic>> banners = [];
  List<QueryDocumentSnapshot> collections = [];
  List<QueryDocumentSnapshot> promotions = [];
  List<QueryDocumentSnapshot> occasions = [];

  /// 🔥 NEW FLAT DATA
  List<Map<String, dynamic>> subCollections = [];

  /// 🔥 MAIN LOAD FUNCTION
  Future<void> loadHomeData() async {

    if (isLoaded) return;

    final branch = TenantConfig.branchCode;

    isLoading = true;
    notifyListeners();

    try {

      final results = await Future.wait([

        /// 🔥 BANNERS
        FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("banners")
            .orderBy("createdAt", descending: true)
            .get(),

        /// 🔥 COLLECTIONS
        FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("collections")
            .get(),

        /// 🔥 PROMOTIONS
        FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("promotions")
            .orderBy("order")
            .get(),

        /// 🔥 OCCASIONS
        FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("occasions")
            .orderBy("order")
            .get(),

        /// 🔥 NEW: FLAT SUBCOLLECTIONS
        FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("subcollections")
            .orderBy("createdAt", descending: true)
            .get(),
      ]);

      /// 🔥 ASSIGN

      banners = (results[0] as QuerySnapshot)
          .docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();

      collections = (results[1] as QuerySnapshot).docs;
      promotions = (results[2] as QuerySnapshot).docs;
      occasions = (results[3] as QuerySnapshot).docs;

      /// 🔥 NEW ASSIGN
      subCollections = (results[4] as QuerySnapshot)
          .docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            data["id"] = d.id; // 🔥 important for navigation
            return data;
          })
          .toList();

      isLoaded = true;

    } catch (e) {
      debugPrint("Home load error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// 🔥 OPTIONAL REFRESH
  Future<void> refresh() async {
    isLoaded = false;
    await loadHomeData();
  }
}