import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_card.dart';
class ProductDetailScreen extends StatefulWidget {
  final Map product;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  int selectedSize = 1;
  final sizes = ["S", "M", "L", "XL"];

  final PageController _pageController = PageController();
  int currentPage = 0;

  bool _imagesPrecached = false;

  /// ✅ FIXED: use didChangeDependencies instead of initState
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_imagesPrecached) return;

    final imageList = widget.product["imageUrls"];

    if (imageList is List) {
      for (var img in imageList) {
        precacheImage(
          NetworkImage("$img&w=800"),
          context,
        );
      }
    }

    _imagesPrecached = true;
  }

  @override
  Widget build(BuildContext context) {

    final name = widget.product["productName"]?.toString() ?? "";
    final brand = widget.product["brandName"]?.toString() ?? "";
    final productCode = widget.product["productCode"]?.toString() ?? "";

    final rawPrice = widget.product["price"];
    final price = rawPrice == null
        ? 0
        : int.tryParse(rawPrice.toString()) ?? 0;

    final images = (widget.product["imageUrls"] is List)
        ? List<String>.from(widget.product["imageUrls"])
        : [];

    return Scaffold(
      backgroundColor: const Color(0xfff4f4f6),

      body: Stack(
        children: [

          /// 🔥 MAIN CONTENT
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 IMAGE SLIDER
                SizedBox(
                  height: 460,
                  child: Stack(
                    children: [

                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => currentPage = index);
                        },
                        itemBuilder: (context, index) {

                          final img = images[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Center(
                                        child: InteractiveViewer(
                                          child: CachedNetworkImage(
                                            imageUrl: "$img&w=1200",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: "$img&w=800",
                              fit: BoxFit.cover,
                              width: double.infinity,
                              fadeInDuration:
                                  const Duration(milliseconds: 200),
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          );
                        },
                      ),

                      /// 🔥 DOT INDICATOR
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: currentPage == index ? 10 : 6,
                              height: currentPage == index ? 10 : 6,
                              decoration: BoxDecoration(
                                color: currentPage == index
                                    ? Colors.white
                                    : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),

                      /// 🔙 TOP BAR
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _icon(Icons.arrow_back,
                                  () => Navigator.pop(context)),
                              Row(
                                children: [
                                  _icon(Icons.favorite_border, () {}),
                                  const SizedBox(width: 10),
                                  _icon(Icons.shopping_bag_outlined, () {}),
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔥 CONTENT
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "$brand • $productCode",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Text(
                            "₹$price",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("/ 3 days",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text("Select Size",
                          style: TextStyle(fontWeight: FontWeight.bold)),

                      const SizedBox(height: 10),

                      Row(
                        children: List.generate(sizes.length, (index) {
                          final isSelected = selectedSize == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSize = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(sizes[index]),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "ABOUT THIS OUTFIT",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Premium outfit perfect for weddings and events.",
                      ),
                    ],
                  ),
                ),
_similarProducts(),

                const SizedBox(height: 100),
              ],
            ),
          ),

          /// 🔥 BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text("Schedule Trial"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text("Book Now"),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }
Widget _similarProducts() {
  final collectionKeys = widget.product["collectionKeys"];

  if (collectionKeys == null || collectionKeys.isEmpty) {
    return const SizedBox();
  }

  final collectionKey = collectionKeys[0];

  return Container(
    margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),

      /// 🔥 subtle shadow (premium feel)
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔥 TITLE
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Similar Products",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 🔥 LIST
        SizedBox(
          height: 280,
          child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection("products")
                .doc(widget.product["branch"] ?? "7007")
                .collection("products")
                .where("collectionKeys", arrayContains: collectionKey)
                .limit(10)
                .get(),
            builder: (context, snapshot) {

              /// 🔥 LOADING STATE (better UX)
              if (!snapshot.hasData) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (_, index) => Container(
                    width: 170,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs
                  .where((d) => d.id != widget.productId)
                  .toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No similar products"),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {

                  final doc = docs[index];
                  final product = doc.data();

                  return Container(
                    width: 170,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 12,
                    ),
                    child: ProductCard(
                      product: product,
                      productId: doc.id,
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),
      ],
    ),
  );
}
}