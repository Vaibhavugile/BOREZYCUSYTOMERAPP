import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/tenant_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_list_screen.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

List banners = [];
bool bannersLoading = true;
bool loadRest = false;
Future<void> loadBanners() async {

  final snap = await FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("banners")
      .orderBy("createdAt", descending: true)
      .get();

  banners = snap.docs.map((d) => d.data()["imageUrl"]).toList();

  /// 🔥 PRELOAD IMAGES
  for (var img in banners) {
    precacheImage(NetworkImage(img), context);
  }

  setState(() {
    bannersLoading = false;
  });
}
@override
void initState() {
  super.initState();

  loadBanners();

  Future.microtask(() {
    Provider.of<WishlistProvider>(context, listen: false)
        .initWishlist();
  });

  /// 🔥 LOAD BELOW CONTENT ONCE
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

    return Scaffold(

      backgroundColor: const Color(0xFFFCF9F8),

      body: CustomScrollView(
      cacheExtent: 2000,
        physics: const BouncingScrollPhysics(),

        slivers: [

          _topBar(),

          SliverToBoxAdapter(
  child: Column(
    children: [

      const SizedBox(height:20),

      _searchBar(),

      const SizedBox(height:20),

      _heroSlider(), // 👈 ONLY FAST SECTION

    ],
  ),
),

/// 🔥 LAZY LOAD REST
SliverToBoxAdapter(
  child: loadRest
      ? Column(
          children: [

            const SizedBox(height:30),

            _collectionsGrid(),

            const SizedBox(height:40),

            _promotionsSlider(),

            const SizedBox(height:30),

            _miniTrendSlider(),

            const SizedBox(height:30),

            _occasionCarousel(),

            const SizedBox(height:40),

            _topStoriesSlider(),

            const SizedBox(height:30),
          ],
        )
      : const SizedBox(),
),

        ],
      ),
    );
  }

  /// TOP BAR
  Widget _topBar() {
  return SliverAppBar(
    floating: true,
    elevation: 0,
    backgroundColor: Colors.white,
    toolbarHeight: 70,

    title: Row(
      children: [

        /// LOGO
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

        /// NOTIFICATION
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
            )
          ],
        ),

        const SizedBox(width: 15),

        Consumer<WishlistProvider>(
  builder: (context, wishlist, _) {

    final count = wishlist.wishlistIds.length;

    return Stack(
      children: [

        const Icon(Icons.favorite_border, size: 26),

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
                ),
              ),
            ),
          ),
      ],
    );
  },
),

        const SizedBox(width: 15),

        const Icon(Icons.person_outline),
      ],
    ),
  );
}

  /// SEARCH BAR
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
  Widget _imageCategories() {

  final items = [
    {
      "image":
      "https://images.unsplash.com/photo-1520975922284-9f2a4b6e9a7e",
      "title": "Wedding"
    },
    {
      "image":
      "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9",
      "title": "Party"
    },
    {
      "image":
      "https://images.unsplash.com/photo-1519710164239-da123dc03ef4",
      "title": "Home"
    },
    {
      "image":
      "https://images.unsplash.com/photo-1542291026-7eec264c27ff",
      "title": "Ethnic"
    },
    {
      "image":
      "https://images.unsplash.com/photo-1590874103328-eac38a683ce7",
      "title": "Formal"
    },
  ];

  return SizedBox(
    height: 95,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: items.length,
      itemBuilder: (context, i) {

        return Padding(
          padding: const EdgeInsets.only(right: 14),

          child: Column(
            children: [

              ClipRRect(
  borderRadius: BorderRadius.circular(18),
  child: CachedNetworkImage(
    imageUrl: items[i]["image"]!,
    width: 65,
    height: 65,
    fit: BoxFit.cover,

    placeholder: (context, url) => Container(
      color: Colors.grey.shade200,
    ),

    errorWidget: (context, url, error) =>
        const Icon(Icons.error),
  ),
),

              const SizedBox(height: 6),

              Text(
                items[i]["title"]!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        );
      },
    ),
  );
}

  /// HERO SLIDER
Widget _heroSlider() {

  if (bannersLoading) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (banners.isEmpty) {
    return const SizedBox();
  }

  return Column(
    children: [

      /// 🔥 HERO CAROUSEL
      CarouselSlider.builder(
        carouselController: carouselController,
        itemCount: banners.length,

        options: CarouselOptions(
          height: 220,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          enableInfiniteScroll: true,

          /// 🔥 SMOOTH + LIGHT
          autoPlay: false,
          scrollPhysics: const BouncingScrollPhysics(),
          pageSnapping: true,

          onPageChanged: (index, reason) {
            if (activeIndex != index) {
              setState(() {
                activeIndex = index;
              });
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

                  /// 🔥 IMAGE WITH PERFECT RATIO (NO STRETCH)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image,

                      /// 🔥 CORRECT RATIO FOR BANNERS
                      memCacheWidth: 1200,
                      memCacheHeight: 675,

                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 250),

                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                      ),

                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.error),
                    ),
                  ),

                  /// 🔥 PREMIUM GRADIENT
                  Positioned.fill(
                    child: Container(
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
                  ),

                  /// 🔥 TEXT CONTENT (PREMIUM SPACING)
                  Positioned(
                    left: 18,
                    bottom: 18,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "NEW COLLECTION",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "UNLEASHED STYLE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: const Text(
                            "Min 45% OFF",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
        },
      ),

      const SizedBox(height: 10),

      /// 🔥 DOT INDICATOR (CLEAN + PREMIUM)
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

Widget _miniTrendSlider() {

return FutureBuilder(
  future: FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("collections")
      .get(),

builder: (context, snapshot) {

if (!snapshot.hasData) {
return const SizedBox(
height: 200,
child: Center(child: CircularProgressIndicator()),
);
}

final collections = snapshot.data!.docs;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: collections.map((collectionDoc) {

final collectionId = collectionDoc.id;
final data = collectionDoc.data();
final title = data["title"] ?? "";

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

/// COLLECTION TITLE (For Her / For Him etc)
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

/// SUBCOLLECTIONS
FutureBuilder(
  future: FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("collections")
      .doc(collectionId)
      .collection("subcollections")
      .orderBy("createdAt", descending: true)
      .get(),

builder: (context, subSnap) {

if (!subSnap.hasData) {
return const SizedBox(
height: 200,
child: Center(child: CircularProgressIndicator()),
);
}

final items = subSnap.data!.docs;

if (items.isEmpty) {
return const SizedBox();
}

return _genderSlider(
  List.generate(items.length, (index) {

    final doc = items[index];
    final d = doc.data();

    return {
      "title": d["title"] ?? "",
      "image": d["imageUrl"] ?? "",
      "collectionId": collectionId,
      "subcollectionId": doc.id,
    };

  }),
);

},

),

const SizedBox(height: 28),

],
);

}).toList(),

);

},

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
  imageUrl: item["image"] + "&w=400",
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,

  placeholder: (context, url) => Container(
    color: Colors.grey.shade200,
  ),

  errorWidget: (context, url, error) =>
      const Icon(Icons.error),
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
Widget _occasionCarousel(){

return FutureBuilder(
future: FirebaseFirestore.instance
.collection("products")
.doc(TenantConfig.branchCode)
.collection("occasions")
.orderBy("order")
.get(),

builder:(context,snapshot){

if(!snapshot.hasData){
return const SizedBox(
height:300,
child:Center(child:CircularProgressIndicator())
);
}

final occasions = snapshot.data!.docs;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children:[

/// HEADER
Padding(
padding: const EdgeInsets.symmetric(horizontal:20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children:[

const Text(
"Select By Occasion",
style: TextStyle(
fontSize:28,
fontWeight:FontWeight.bold
),
),

const SizedBox(height:4),

Text(
"Find outfits for every celebration",
style: TextStyle(
color: Colors.grey.shade600,
fontSize:14
),
),

const SizedBox(height:10),

Container(
height:4,
width:50,
decoration: BoxDecoration(
color: Colors.deepPurple,
borderRadius: BorderRadius.circular(10)
),
)

],
),
),

const SizedBox(height:20),

CarouselSlider.builder(

itemCount: occasions.length,

options: CarouselOptions(
height:340,
viewportFraction:0.72,
enlargeCenterPage:true,
autoPlay:false,
),

itemBuilder:(context,index,realIndex){

final item = occasions[index].data();

return _occasionCard(
item["title"],
item["subtitle"],
item["imageUrl"]
);

}

),

const SizedBox(height:10)

]

);

}

);

}
Widget _occasionCard(String title,String subtitle,String image){

return Container(
margin: const EdgeInsets.symmetric(horizontal:6),

decoration: BoxDecoration(
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(30),
topRight: Radius.circular(10),
bottomLeft: Radius.circular(10),
bottomRight: Radius.circular(30),
),
boxShadow:[
BoxShadow(
blurRadius:22,
color: Colors.black.withOpacity(.18),
offset: const Offset(0,12)
)
]
),

child: ClipRRect(

borderRadius: const BorderRadius.only(
topLeft: Radius.circular(30),
topRight: Radius.circular(10),
bottomLeft: Radius.circular(10),
bottomRight: Radius.circular(30),
),

child: Stack(

children:[

CachedNetworkImage(
imageUrl: image + "&w=500",
width:double.infinity,
height:double.infinity,
fit:BoxFit.cover
),

Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors:[
Colors.black.withOpacity(.75),
Colors.transparent
],
begin:Alignment.bottomCenter,
end:Alignment.topCenter
)
),
),

Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children:[

Text(
title,
style: const TextStyle(
color:Colors.white,
fontSize:26,
fontWeight:FontWeight.bold
),
),

const SizedBox(height:6),

Text(
subtitle,
style: const TextStyle(
color:Colors.white70,
fontSize:14
),
textAlign: TextAlign.center,
)

],
),
)

]

)

)

);

}
Widget _promotionsSlider(){

return FutureBuilder(
  future: FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("promotions")
      .orderBy("order")
      .get(),

builder:(context,snapshot){

if(!snapshot.hasData){

return const SizedBox(
height:200,
child:Center(child:CircularProgressIndicator())
);

}

final promos = snapshot.data!.docs;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children:[

const Padding(
padding: EdgeInsets.symmetric(horizontal:20),
child: Text(
"Offers & Promotions",
style: TextStyle(
fontSize:24,
fontWeight:FontWeight.bold
),
),
),

const SizedBox(height:16),

CarouselSlider.builder(

itemCount: promos.length,

options: CarouselOptions(
height:180,
viewportFraction:0.9,
enlargeCenterPage:true,
autoPlay:false,
),

itemBuilder:(context,index,realIndex){

final item = promos[index].data();

return _promotionCard(
item["title"],
item["subtitle"],
item["discount"],
item["imageUrl"]
);

}

)

]

);

}

);

}
Widget _promotionCard(
String title,
String subtitle,
String discount,
String image
){

return Container(
margin: const EdgeInsets.symmetric(horizontal:6),

decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
boxShadow:[
BoxShadow(
blurRadius:18,
color: Colors.black.withOpacity(.15),
offset: const Offset(0,8)
)
]
),

child: ClipRRect(
borderRadius: BorderRadius.circular(20),

child: Stack(

children:[

CachedNetworkImage(
imageUrl: image + "&w=500",
fit:BoxFit.cover,
width:double.infinity,
height:double.infinity
),

Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors:[
Colors.black.withOpacity(.6),
Colors.transparent
],
begin:Alignment.bottomLeft,
end:Alignment.topRight
)
),
),

Positioned(
left:16,
bottom:16,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children:[

Text(
title,
style: const TextStyle(
color:Colors.white,
fontSize:18,
fontWeight:FontWeight.bold
),
),

const SizedBox(height:2),

Text(
subtitle,
style: const TextStyle(
color:Colors.white70,
fontSize:13
),
),

const SizedBox(height:6),

Container(
padding: const EdgeInsets.symmetric(
horizontal:12,
vertical:4
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20)
),
child: Text(
discount,
style: const TextStyle(
fontWeight:FontWeight.bold,
fontSize:12
),
),
)

]
)
)

]

)

)

);

}





  /// CATEGORY ICONS
  Widget _categories() {

  final items = [
    {"icon": Icons.diamond_outlined, "title": "Wedding"},
    {"icon": Icons.celebration_outlined, "title": "Party"},
    {"icon": Icons.auto_awesome_outlined, "title": "Ethnic"},
    {"icon": Icons.checkroom_outlined, "title": "Formal"},
    {"icon": Icons.grid_view_rounded, "title": "View All"},
  ];

  return SizedBox(
    height: 85,

    child: ListView.separated(

      scrollDirection: Axis.horizontal,

      padding: const EdgeInsets.symmetric(horizontal: 20),

      itemCount: items.length,

      separatorBuilder: (_, __) => const SizedBox(width: 18),

      itemBuilder: (context, i) {

        return Column(
          children: [

            /// ICON CONTAINER
            Container(

              height: 52,
              width: 52,

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 12,
                    offset: const Offset(0,4),
                  )
                ],

              ),

              child: Icon(
                items[i]["icon"] as IconData,
                color: const Color(0xFF6A3DE8),
                size: 22,
              ),

            ),

            const SizedBox(height:8),

            /// TITLE
            Text(
              items[i]["title"].toString(),

              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )

          ],
        );
      },
    ),
  );
}

  /// BENTO COLLECTION GRID
 Widget _collectionsGrid(){

return FutureBuilder(
  future: FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("collections")
      .get(),

builder:(context,snapshot){

if(!snapshot.hasData){

return const Padding(
padding: EdgeInsets.all(30),
child: Center(child:CircularProgressIndicator()),
);

}

final collections = snapshot.data!.docs;

return Padding(

padding: const EdgeInsets.symmetric(horizontal:20),

child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

const Text(
"Collections",
style: TextStyle(
fontSize:26,
fontWeight:FontWeight.bold
),
),

const SizedBox(height:20),

GridView.builder(

  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),

  itemCount: collections.length,

  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

    crossAxisCount: collections.length <= 2 ? 1 : 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,

    /// Bigger cards when few collections
    childAspectRatio: collections.length <= 2 ? 1.8 : 1.1,

  ),

  itemBuilder: (context, index) {

    final data = collections[index].data();

    return SizedBox(
      height: collections.length <= 2 ? 220 : null,

      child: _collectionCard(
        data["title"],
        data["imageUrl"],
      ),
    );

  }

)

]

)

);

}

);

}
  /// GLASSMORPHISM COLLECTION CARD
  Widget _collectionCard(String title,String image){

    return ClipRRect(

      borderRadius: BorderRadius.circular(26),

      child: Stack(

        children: [

          CachedNetworkImage(
            imageUrl: image + "&w=500",
            width:double.infinity,
            height:double.infinity,
            fit:BoxFit.cover,
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:[
                  Colors.transparent,
                  Colors.black.withOpacity(.7)
                ],
                begin:Alignment.topCenter,
                end:Alignment.bottomCenter
              ),
            ),
          ),

          Positioned(
            bottom:16,
            left:16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal:14,
                vertical:6
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color:Colors.white30)
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color:Colors.white,
                  fontWeight:FontWeight.bold
                ),
              ),
            ),
          )

        ],
      ),
    );
  }

  /// BRANCHES
  Widget _branches(){

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:20),

      child: Column(

        crossAxisAlignment:CrossAxisAlignment.start,

        children: [

          const Text(
            "Nearby Branches",
            style: TextStyle(
              fontSize:20,
              fontWeight:FontWeight.bold
            ),
          ),

          const SizedBox(height:16),

          _branchCard("Downtown Flagship","1.2 km"),
          const SizedBox(height:10),
          _branchCard("Upper East Studio","4.8 km"),

        ],
      ),
    );
  }

  Widget _branchCard(String name,String distance){

    return Container(

      padding:const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius:BorderRadius.circular(20),
        boxShadow:[
          BoxShadow(
            blurRadius:20,
            color:Colors.black.withOpacity(.05)
          )
        ]
      ),

      child: Row(

        children: [

          Container(
            height:50,
            width:50,
            decoration: BoxDecoration(
              color:Colors.deepPurple.withOpacity(.1),
              borderRadius:BorderRadius.circular(12)
            ),
            child:const Icon(Icons.location_on,color:Colors.deepPurple),
          ),

          const SizedBox(width:12),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight:FontWeight.bold),
            ),
          ),

          Text(distance)

        ],
      ),
    );
  }
}