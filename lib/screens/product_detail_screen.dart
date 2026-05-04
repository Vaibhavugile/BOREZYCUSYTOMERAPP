import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {

    /// 🔥 SAFE DATA MAPPING
    final name = widget.product["productName"]?.toString() ?? "";
    final brand = widget.product["brandName"]?.toString() ?? "";
    final productCode = widget.product["productCode"]?.toString() ?? "";

    final rawPrice = widget.product["price"];
    final price = rawPrice == null
        ? 0
        : int.tryParse(rawPrice.toString()) ?? 0;

    final imageList = widget.product["imageUrls"];
    final image = (imageList is List && imageList.isNotEmpty)
        ? imageList[0].toString()
        : "";

    return Scaffold(
      backgroundColor: const Color(0xfff4f4f6),

      body: Stack(
        children: [

          /// 🔥 MAIN CONTENT
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 HERO IMAGE
                Stack(
                  children: [

                    GestureDetector(
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
                                  child: Hero(
                                    tag: image,
                                    child: InteractiveViewer(
                                      child: Image.network(image),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: image,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                          child: Image.network(
                            image,
                            height: 460,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    /// 🔙 TOP BAR
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _icon(Icons.arrow_back, () => Navigator.pop(context)),
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

                      /// BRAND + CODE
                      Text(
                        "$brand • $productCode",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// NAME
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// PRICE
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
                          const Text("/ 4 days",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// SIZE
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

                      /// DESCRIPTION
                      const Text(
                        "ABOUT THIS OUTFIT",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Premium outfit perfect for weddings and events.",
                      ),
                    ],
                  ),
                ),

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
}