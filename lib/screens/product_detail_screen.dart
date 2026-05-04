import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  int selectedSize = 1;
  final sizes = ["S", "M", "L", "XL"];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xfff4f4f6),

      body: Stack(
        children: [

          /// 🔥 MAIN CONTENT
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 HERO IMAGE (FULL WIDTH PREMIUM)
              Stack(
  children: [

    /// 🔥 IMAGE WITH ZOOM + HERO
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
                    tag: widget.product["image"],
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        widget.product["image"],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },

      child: Hero(
        tag: widget.product["image"],
        child: Container(
          height: 460,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),

          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [

                /// IMAGE
                Image.network(
                  widget.product["image"],
                  fit: BoxFit.cover,
                ),

                /// 🔥 PREMIUM GRADIENT (SOFTER)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black38,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                /// 🔍 ZOOM ICON
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),

    /// 🔥 PREMIUM TOP BAR
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            /// BACK BUTTON
            _floatingIcon(Icons.arrow_back, () {
              Navigator.pop(context);
            }),

            Row(
              children: [

                /// WISHLIST
                _floatingIcon(Icons.favorite_border, () {}),

                const SizedBox(width: 10),

                /// CART
                _floatingIcon(Icons.shopping_bag_outlined, () {}),
              ],
            ),
          ],
        ),
      ),
    ),
  ],
),

                const SizedBox(height: 16),

                /// 🔥 CONTENT CARD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// TAG
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "DESIGNER PICK",
                          style: TextStyle(fontSize: 11),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// TITLE
                      Text(
                        widget.product["name"],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// RATING
                      const Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.orange),
                          Icon(Icons.star, size: 16, color: Colors.orange),
                          Icon(Icons.star, size: 16, color: Colors.orange),
                          Icon(Icons.star, size: 16, color: Colors.orange),
                          Icon(Icons.star_half, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text("(48 reviews)",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      /// 🔥 PRICE SECTION (PREMIUM CARD)
                      Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: const Color(0xfffafafa),
  ),
  child: Column(
    children: [

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "RENT",
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "₹${widget.product["price"]}",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "/ 4 days",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                "DEPOSIT",
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "₹300",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),

      const SizedBox(height: 12),

      const Divider(),

      const SizedBox(height: 8),

      const Text(
        "Includes cleaning & maintenance. No hidden charges.",
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ],
  ),
),

                      const SizedBox(height: 20),

                      /// DESCRIPTION
                     Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: const [

    Text(
      "ABOUT THIS OUTFIT",
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        color: Colors.grey,
        fontWeight: FontWeight.w600,
      ),
    ),

    SizedBox(height: 8),

    Text(
      "Crafted from luxurious fabric, this statement piece is designed for weddings, receptions, and upscale evening events. The silhouette enhances elegance while ensuring all-day comfort and effortless grace.",
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

                      const SizedBox(height: 20),

                      /// SIZE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Select Size",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Size Guide",
                              style: TextStyle(color: Colors.deepPurple)),
                        ],
                      ),

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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300,
                                ),
                                color: isSelected
                                    ? Colors.deepPurple.withOpacity(0.1)
                                    : Colors.white,
                              ),
                              child: Text(sizes[index]),
                            ),
                          );
                        }),
                      ),

                      

                      /// AVAILABILITY
                      
                      

                      
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 PREMIUM BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Shedule Trials",
                          style: TextStyle(color: Colors.deepPurple)),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("BOOK NOW"),
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

Widget _floatingIcon(IconData icon, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
        )
      ],
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.black),
      onPressed: onTap,
    ),
  );
}
}