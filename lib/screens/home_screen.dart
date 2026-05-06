import 'package:flutter/material.dart';

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/tenant_config.dart';
import 'product_list_screen.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
import '../providers/home_provider.dart'; // ✅ ADDED
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wishlist_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/user_helper.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool loadRest = false;

  @override
void initState() {
  super.initState();

  /// Wishlist init
  Future.microtask(() {
    Provider.of<WishlistProvider>(context, listen: false)
        .initWishlist();
  });

  /// 🔔 FOREGROUND NOTIFICATION
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {

    final title = message.notification?.title ?? "";
    final body = message.notification?.body ?? "";

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title\n$body"),
      ),
    );
  });

  /// Lazy load rest
  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      setState(() {
        loadRest = true;
      });
    }
  });
}

  int activeIndex = 0;
  final CarouselSliderController carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {

    final home = Provider.of<HomeProvider>(context);

    /// 🔥 LOADING STATE
    if (home.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),

      body: CustomScrollView(
        cacheExtent: 2000,
        physics: const BouncingScrollPhysics(),

        slivers: [

          _topBar(),

          /// 🔥 TOP SECTION
          SliverToBoxAdapter(
            child: Column(
              children:  [
                SizedBox(height: 20),
                 _searchBar(),

  const SizedBox(height:20),

  _heroSlider(),
              ],
            ),
          ),

          /// 🔥 REST
          SliverToBoxAdapter(
            child: loadRest
                ? Column(
                    children:  [
                      SizedBox(height: 30),
                      _collectionsGrid(),

        const SizedBox(height:40),

        _promotionsSlider(),

        const SizedBox(height:30),

        _miniTrendSlider(),

        const SizedBox(height:30),

        _occasionCarousel(),

        const SizedBox(height:40),

        _topStoriesSlider(),


                      SizedBox(height: 30),
                    ],
                  ) 
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  /// 🔥 TOP BAR
 Widget _topBar() {
  return SliverAppBar(
    floating: true,
    elevation: 0,
    backgroundColor: Colors.white,
    toolbarHeight: 70,

    title: Row(
      children: [

        /// 🏷 APP NAME
        Text(
          TenantConfig.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.5,
            color: Colors.black,
          ),
        ),

        const Spacer(),

        /// 🔔 NOTIFICATION
        Stack(
          children: [
            const Icon(Icons.notifications_none, size: 26),

            Positioned(
              right: 0,
              top: 0,
              child: Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        /// 💰 WALLET (LIVE FROM FIRESTORE)
        GestureDetector(
          onTap: () {
            // 👉 Navigate to wallet screen later
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [

                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Colors.black,
                ),

                const SizedBox(width: 6),

                /// 🔥 REAL WALLET VALUE
              FutureBuilder<String?>(
  future: UserHelper.getPhone(),
  builder: (context, phoneSnap) {

    /// 🔥 LOADING STATE
    if (phoneSnap.connectionState == ConnectionState.waiting) {
      return const Text(
        "₹0",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }

    /// ❌ NO PHONE
    if (!phoneSnap.hasData || phoneSnap.data == null) {
      return const Text(
        "₹0",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }

    final phone = phoneSnap.data!;

    /// 🔥 REALTIME WALLET
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("customers")
          .doc(TenantConfig.branchCode)
          .collection("users")
          .doc(phone)
          .snapshots(),

      builder: (context, snapshot) {

        int wallet = 0;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          wallet = data["creditBalance"] ?? 0;
        }

        return Text(
          "₹$wallet",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
      },
    );
  },
),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        /// ❤️ WISHLIST
        GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WishlistScreen(),
      ),
    );
  },
  child: Consumer<WishlistProvider>(
    builder: (context, wishlist, _) {
      final count = wishlist.wishlistIds.length;

      return Stack(
        clipBehavior: Clip.none,
        children: [

          /// ❤️ ICON
          const Icon(Icons.favorite_border, size: 26),

          /// 🔴 BADGE
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 99 ? "99+" : count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
),
        const SizedBox(width: 12),

        /// 👤 PROFILE

      ],
    ),
  );
}
  Widget _searchBar(){

return Padding(
  padding: const EdgeInsets.symmetric(horizontal:20),

  child: Container(

    height:50,

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          blurRadius: 20,
          color: Colors.black.withOpacity(.05)
        )
      ],
    ),

    child: Row(
      children: const [

        SizedBox(width:15),

        Icon(Icons.search,color:Colors.grey),

        SizedBox(width:10),

        Expanded(
          child: Text(
            "Find your perfect look...",
            style: TextStyle(color:Colors.grey),
          ),
        ),

        CircleAvatar(
          radius:18,
          backgroundColor:Colors.deepPurple,
          child: Icon(Icons.tune,color:Colors.white,size:18),
        ),

        SizedBox(width:10)

      ],
    ),
  ),
);

}

Widget _topStoriesSlider() {


  final stories = [
  "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542192372-h111.webp?alt=media&token=38bd2dab-9947-44fd-848d-282e23c6744a",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542198607-h133.webp?alt=media&token=ba683a47-4c3c-4542-af91-4fbe7b96dffe",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542203558-h211.webp?alt=media&token=be4eac36-df8d-4b36-891a-37990e7a35bc",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542209121-h222.webp?alt=media&token=8030ffc6-ed26-4dfc-b625-f3fd0a7602aa",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542216342-h1422.webp?alt=media&token=6e5b7eb4-56f7-45ea-9385-535ea9ae9acc",
    "https://images.openai.com/static-rsc-4/mGqToIqQX0anumZAFEcDuYirLwMUQcpASgyLFXZZi4r1XsJi5Y2W_m8hueDROjHCv3en_kjIctrCvG1LcD3EHqZEYoAJTh116vDhw41NEeHG3YJGkEV3nnMCF3lEdXkE4vURLNXmzIKiekAb5UDJroGiA-8pBW0dsxfHpwTiuz10XHBZP1-UNLyGla-uYDJb?purpose=fullsize",
    "https://images.openai.com/static-rsc-4/_c9NVpLWJfDYhJWc4IY56LPDaSOzNj6rMrAM7NpCQ0HIvtahOaLsJBtC79pJ7DuWn_A64mqthAEgdrD0fzBTvcVLrZ4cy6t9ttUqdHr_HSOfmfCPq6ZxBehI5FF4aQposefR22Pv_MNrltgd2UgoPpONMJGCtkXT575dzQatV1p7-xnCnz6yoAMMoGW1OxJb?purpose=fullsize",

  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Top Stories Of The Week",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 4),

            Text(
              "In the spotlight",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      CarouselSlider.builder(
        itemCount: stories.length,

        options: CarouselOptions(
          height: 300,
          viewportFraction: 0.85,
          enlargeCenterPage: true,

          autoPlay: false,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.easeInOut,
        ),

        itemBuilder: (context, index, realIndex) {

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: CachedNetworkImage(
              imageUrl: stories[index] + "&w=400",
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        },
      ),
    ],
  );
}

  /// HERO SLIDER
Widget _heroSlider() {

  final home = Provider.of<HomeProvider>(context);
  final banners = home.banners.map((e) => e["imageUrl"]).toList();

  if (banners.isEmpty) return const SizedBox();

  return Column(
    children: [

      CarouselSlider.builder(
        carouselController: carouselController,
        itemCount: banners.length,

        options: CarouselOptions(
          height: 280,
          viewportFraction: 1.0,
          autoPlay: false,
          enableInfiniteScroll: true,

          onPageChanged: (index, reason) {
            if (activeIndex != index) {
              setState(() => activeIndex = index);
            }
          },
        ),

        itemBuilder: (context, index, realIndex) {

          final image = banners[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),

              child: Stack(
                children: [

                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      
                      fit: BoxFit.cover,
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      const SizedBox(height: 10),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(banners.length, (index) {

          final isActive = activeIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 5,
            width: isActive ? 14 : 5,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.deepPurple
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    ],
  );
}


Widget _miniTrendSlider() {

  final home = Provider.of<HomeProvider>(context);
  final collections = home.collections;
  final allSubs = home.subCollections; // ✅ NEW

  if (collections.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(collections.length, (index) {

      final collectionDoc = collections[index];
      final collectionId = collectionDoc.id;

      final data = collectionDoc.data() as Map<String, dynamic>;
      final title = data["title"] ?? "";

      /// 🔥 FILTER FROM FLAT DATA
      final items = allSubs
          .where((e) => e["collectionId"] == collectionId)
          .toList();

      if (items.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// SLIDER
          _genderSlider(
            items.map((d) {
              return {
                "title": d["title"] ?? "",
                "image": d["imageUrl"] ?? "",
                "collectionId": d["collectionId"],
                "subcollectionId": d["id"], // ✅ now from flat
              };
            }).toList(),
          ),

          const SizedBox(height: 28),
        ],
      );
    }),
  );
}
Widget _genderSlider(List<Map<String, dynamic>> items) {

  return SizedBox(
    height: 220,

    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,

      itemBuilder: (context, index) {

        final item = items[index];

        return GestureDetector(

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  title: item["title"],
                  collectionKey:
                      "${item["collectionId"]}_${item["subcollectionId"]}",
                ),
              ),
            );
          },

          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 14),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),

              child: Stack(
                children: [

                  CachedNetworkImage(
                    imageUrl: item["image"],
                    
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(.6),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Text(
                      item["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
Widget _occasionCarousel() {

  final home = Provider.of<HomeProvider>(context);
  final occasions = home.occasions;

  if (occasions.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// HEADER
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Select By Occasion",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Find outfits for every celebration",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              height: 4,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      /// 🔥 CAROUSEL
      CarouselSlider.builder(
        itemCount: occasions.length,

        options: CarouselOptions(
          height: 320,
          viewportFraction: 0.72,
          enlargeCenterPage: true,
          autoPlay: false,
        ),

        itemBuilder: (context, index, realIndex) {

          final item = occasions[index].data() as Map<String, dynamic>;

          return _occasionCard(
            item["title"] ?? "",
            item["subtitle"] ?? "",
            item["imageUrl"] ?? "",
          );
        },
      ),

      const SizedBox(height: 10),
    ],
  );
}
Widget _occasionCard(String title, String subtitle, String image) {

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),

    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(
          blurRadius: 10, // 🔥 reduced (performance)
          color: Colors.black.withOpacity(.12),
          offset: const Offset(0, 6),
        )
      ],
    ),

    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(30),
      ),

      child: Stack(
        children: [

          /// 🔥 OPTIMIZED IMAGE
          CachedNetworkImage(
            imageUrl: image,
           
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          /// 🔥 GRADIENT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(.7),
                  Colors.transparent
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          /// 🔥 TEXT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}
Widget _promotionsSlider() {

  final home = Provider.of<HomeProvider>(context);
  final promos = home.promotions;

  if (promos.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          "Offers & Promotions",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      const SizedBox(height: 16),

      CarouselSlider.builder(
        itemCount: promos.length,

        options: CarouselOptions(
          height: 170,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          autoPlay: false,
        ),

        itemBuilder: (context, index, realIndex) {

          final item = promos[index].data() as Map<String, dynamic>;

          return _promotionCard(
            item["title"] ?? "",
            item["subtitle"] ?? "",
            item["discount"] ?? "",
            item["imageUrl"] ?? "",
          );
        },
      ),
    ],
  );
}
Widget _promotionCard(
  String title,
  String subtitle,
  String discount,
  String image,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),

    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),

      /// 🔥 lighter shadow (performance)
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black.withOpacity(.12),
          offset: const Offset(0, 6),
        )
      ],
    ),

    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),

      child: Stack(
        children: [

          /// 🔥 optimized image
          CachedNetworkImage(
            imageUrl: image,
            
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(.6),
                  Colors.transparent
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  /// CATEGORY ICONS
  

  /// BENTO COLLECTION GRID
 Widget _collectionsGrid() {

  final home = Provider.of<HomeProvider>(context);
  final collections = home.collections;

  if (collections.isEmpty) return const SizedBox();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Collections",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: collections.length,

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: collections.length <= 2 ? 1 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,

            /// 🔥 better sizing
            childAspectRatio: collections.length <= 2 ? 1.6 : 0.9,
          ),

          itemBuilder: (context, index) {

            final data = collections[index].data() as Map<String, dynamic>;
final doc = collections[index];
           return _collectionCard(
  data["title"] ?? "",
  data["imageUrl"] ?? "",
  doc.id,
);
          },
        ),
      ],
    ),
  );
}
  /// GLASSMORPHISM COLLECTION CARD
Widget _collectionCard(String title, String image, String collectionId) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            title: title,
            collectionKey: collectionId, // ✅ PASS ID
          ),
        ),
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// BRANCHES
 

 
}