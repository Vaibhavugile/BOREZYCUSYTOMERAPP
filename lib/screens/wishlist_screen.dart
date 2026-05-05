import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../wishlist/wishlist_provider.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    final items = wishlist.wishlistItems; // ✅ must be List<Map>

    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔥 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Wishlist",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      /// 🔥 BODY
      body: items.isEmpty
          ? _emptyState()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              itemCount: items.length,

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.60,
              ),

              itemBuilder: (context, index) {
                final product = items[index];

                final productId =
                    product["id"]?.toString() ?? index.toString();

                /// 🔥 REUSING YOUR PRODUCT CARD
                return ProductCard(
                  product: product,
                  productId: productId,
                );
              },
            ),
    );
  }

  /// ❌ EMPTY STATE UI
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [

          Icon(
            Icons.favorite_border,
            size: 70,
            color: Colors.grey,
          ),

          SizedBox(height: 12),

          Text(
            "Your wishlist is empty",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          SizedBox(height: 6),

          Text(
            "Save items you love ❤️",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}