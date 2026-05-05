import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../wishlist/wishlist_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Map product;
  final String productId;

  const ProductCard({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final safeId = productId.toString();

    /// ✅ optimized (no full rebuild)
    final isLiked = context.select<WishlistProvider, bool>(
      (w) => w.isWishlisted(safeId),
    );

    final wishlist = context.read<WishlistProvider>();

    /// 🔥 DATA
    final name = product["productName"]?.toString() ?? "";
    final brand = product["brandName"]?.toString() ?? "";
    final productCode = product["productCode"]?.toString() ?? "";

    final rawPrice = product["price"];
    final price = rawPrice == null
        ? 0
        : int.tryParse(rawPrice.toString()) ?? 0;

    final imageList = product["imageUrls"];
    final image = (imageList is List && imageList.isNotEmpty)
        ? imageList[0].toString()
        : "";

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              productId: productId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 IMAGE
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [

                  /// IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: "$image&w=600",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            fadeInDuration:
                                const Duration(milliseconds: 200),
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image),
                            ),
                          ),
                  ),

                  /// ⭐ RATING
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Text("4.2", style: TextStyle(fontSize: 10)),
                          SizedBox(width: 2),
                          Icon(Icons.star, size: 11, color: Colors.green),
                        ],
                      ),
                    ),
                  ),

                  /// ❤️ WISHLIST
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          wishlist.toggleById(safeId, product);
                        },
                        child: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              isLiked ? Colors.red : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 TEXT AREA
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// BRAND
                    Text(
                      "$brand • $productCode",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 2),

                    /// NAME
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// PRICE
                    Row(
                      children: [

                        Text(
                          "₹${price + 100}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(width: 3),

                        Text(
                          "₹$price",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(width: 3),

                        const Text(
                          "20% OFF",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}