import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
import 'product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
class ProductListScreen extends StatefulWidget {
  final String title;
  final String collectionKey;

  const ProductListScreen({super.key, required this.title ,required this.collectionKey});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {

 List<DocumentSnapshot> products = [];
bool isLoading = false;
bool hasMore = true;
DocumentSnapshot? lastDoc;
bool isFirstLoad = true;
final ScrollController _scrollController = ScrollController();
@override
void initState() {
  super.initState();

  fetchProducts();

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchProducts();
    }
  });
}

@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}
Future<void> fetchProducts() async {
  if (isLoading || !hasMore) return;

  setState(() => isLoading = true);

  Query query = FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("products")
      .where("collectionKeys",
          arrayContains: widget.collectionKey)
      .limit(20);

  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc!);
  }

  final snap = await query.get();

  if (snap.docs.isNotEmpty) {
    lastDoc = snap.docs.last;
    products.addAll(snap.docs);
  }

  if (snap.docs.length < 20) {
    hasMore = false;
  }

  if (mounted) {
  setState(() {
    isLoading = false;
    isFirstLoad = false; // ✅ IMPORTANT
  });
}
}

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
      body: isFirstLoad
    ? GridView.builder(
        itemCount: 6,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.all(8),
          color: Colors.grey[300],
        ),
      )
    : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),

        itemCount: products.length + (hasMore ? 1 : 0),

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.60,
        ),

        itemBuilder: (context, index) {

          if (index >= products.length) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final doc = products[index];
          final product =
              Map<String, dynamic>.from(doc.data() as Map);

          return _ProductCard(
            product: product,
            productId: doc.id,
          );
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
  final String productId;

  const _ProductCard({
    required this.product,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final safeId = productId.toString();
final isLiked = wishlist.isWishlisted(safeId);

    // 🔥 SAFE DATA MAPPING
   final name = product["productName"]?.toString() ?? "";
final brand = product["brandName"]?.toString() ?? "";
  final rawPrice = product["price"];
final productCode = product["productCode"]?.toString() ?? "";
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

               ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: image.isNotEmpty
      ? CachedNetworkImage(
          /// 🔥 slightly higher width to avoid blur
          imageUrl: "$image&w=600",

          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,

          /// 🔥 smooth fade (premium feel)
          fadeInDuration: const Duration(milliseconds: 200),

          /// 🔥 lightweight placeholder (no spinner jank)
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
          ),

          /// 🔥 error fallback
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              ),
            ),
          ),
        )
      : Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.image,
              color: Colors.grey,
            ),
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
                          color: isLiked
                              ? Colors.red
                              : Colors.black,
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
  "$brand  •  $productCode",
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