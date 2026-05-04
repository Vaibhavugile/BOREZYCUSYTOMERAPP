import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
import 'product_detail_screen.dart';
class ProductListScreen extends StatefulWidget {
  final String title;

  const ProductListScreen({super.key, required this.title});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {

  final List<Map<String, dynamic>> dummyProducts = List.generate(20, (index) {
    final images = [
      "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/subcollections%2F7007%2F1777727877283_1777037665346_0548.webp?alt=media",
      "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/subcollections%2F7007%2F1777727678751_1777037686334_0727.webp?alt=media",
      "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/subcollections%2F7007%2F1777727709876_1777038649215_0534.webp?alt=media&token=51a34c88-11dc-4e19-b183-6db65cc4b60a",
      "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/subcollections%2F7007%2F1777727755759_1777038559603_0036%20(1).webp?alt=media&token=05214fc8-7a0e-4d5c-a514-fc28c072e8c9",
    ];

    final names = [
  "Designer Bridal Lehenga",
  "Embroidered Wedding Lehenga",
  "Silk Saree with Zari Work",
  "Floral Anarkali Gown",
  "Party Wear Indo-Western Dress",
  "Sequined Cocktail Gown",
  "Traditional Banarasi Saree",
  "Reception Lehenga Choli",
  "Festive Sharara Set",
  "Velvet Evening Gown",
];

    return {
      "brand": "DOR ",
      "name": names[index % names.length],
      "price": 279 + index * 10,
      "image": images[index % images.length],
    };
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔥 CLEAN APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),

        centerTitle: false,

      actions: [

  const Icon(Icons.search, color: Colors.black),
  const SizedBox(width: 16),

  /// 🔥 WISHLIST WITH COUNT
  Consumer<WishlistProvider>(
    builder: (context, wishlist, _) {

      final count = wishlist.wishlistIds.length;

      return Stack(
        children: [

          const Icon(
            Icons.favorite_border,
            color: Colors.black,
            size: 26,
          ),

          /// 🔴 COUNT BADGE
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),

  const SizedBox(width: 16),

  const Icon(Icons.shopping_bag_outlined, color: Colors.black),
  const SizedBox(width: 12),
],
      ),

      /// 🔥 PRODUCT GRID
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        itemCount: dummyProducts.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.60, // 🔥 BIGGER CARDS
        ),

        itemBuilder: (context, index) {

          final product = dummyProducts[index];

          return _ProductCard(product: product);
        },
      ),

      /// 🔥 BOTTOM BAR
      bottomNavigationBar: Container(
        height: 55,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [

            Expanded(
              child: InkWell(
                onTap: () {},
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_vert),
                      SizedBox(width: 6),
                      Text("SORT"),
                    ],
                  ),
                ),
              ),
            ),

            Container(width: 1, color: Colors.black12),

            Expanded(
              child: InkWell(
                onTap: () {},
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune),
                      SizedBox(width: 6),
                      Text("FILTER"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map product;


  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
  final wishlist = context.watch<WishlistProvider>();
final isLiked = wishlist.isWishlisted(product["name"]);
    return InkWell(
  borderRadius: BorderRadius.circular(12),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
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

          /// 🔥 FIXED IMAGE HEIGHT (KEY FIX)
          SizedBox(
            height: 200,
            width: double.infinity,

            child: Stack(
              children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product["image"],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                /// RATING
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

                /// HEART
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
    wishlist.toggle(product);
  },
  child: Icon(
    isLiked ? Icons.favorite : Icons.favorite_border,
    color: isLiked ? Colors.red : Colors.black,
    size: 18,
  ),
),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 FLEXIBLE TEXT AREA (NO OVERFLOW)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// BRAND
                  Text(
                    product["brand"],
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
                    product["name"],
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
                        "₹${product["price"] + 100}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(width: 3),

                      Text(
                        "₹${product["price"]}",
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