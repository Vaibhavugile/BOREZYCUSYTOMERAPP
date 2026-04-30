import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<String> banners = [
  "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542192372-h111.webp?alt=media&token=38bd2dab-9947-44fd-848d-282e23c6744a",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542198607-h133.webp?alt=media&token=ba683a47-4c3c-4542-af91-4fbe7b96dffe",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542203558-h211.webp?alt=media&token=be4eac36-df8d-4b36-891a-37990e7a35bc",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542209121-h222.webp?alt=media&token=8030ffc6-ed26-4dfc-b625-f3fd0a7602aa",
"https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3445567%2F1777542216342-h1422.webp?alt=media&token=6e5b7eb4-56f7-45ea-9385-535ea9ae9acc",

    "https://images.openai.com/static-rsc-4/mGqToIqQX0anumZAFEcDuYirLwMUQcpASgyLFXZZi4r1XsJi5Y2W_m8hueDROjHCv3en_kjIctrCvG1LcD3EHqZEYoAJTh116vDhw41NEeHG3YJGkEV3nnMCF3lEdXkE4vURLNXmzIKiekAb5UDJroGiA-8pBW0dsxfHpwTiuz10XHBZP1-UNLyGla-uYDJb?purpose=fullsize",
    "https://images.openai.com/static-rsc-4/_c9NVpLWJfDYhJWc4IY56LPDaSOzNj6rMrAM7NpCQ0HIvtahOaLsJBtC79pJ7DuWn_A64mqthAEgdrD0fzBTvcVLrZ4cy6t9ttUqdHr_HSOfmfCPq6ZxBehI5FF4aQposefR22Pv_MNrltgd2UgoPpONMJGCtkXT575dzQatV1p7-xnCnz6yoAMMoGW1OxJb?purpose=fullsize",

  ];
  int activeIndex = 0;
final CarouselSliderController carouselController = CarouselSliderController();
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFCF9F8),

      body: CustomScrollView(

        physics: const BouncingScrollPhysics(),

        slivers: [

          _topBar(),

          SliverToBoxAdapter(
            child: Column(
              children: [

                const SizedBox(height:20),

                _searchBar(),

                const SizedBox(height:20),
                _imageCategories(),  
                SizedBox(height:20),

                _heroSlider(),

                

                const SizedBox(height:30),

                _collectionsGrid(),

                const SizedBox(height:40),
                
_promotionsSlider(),


SizedBox(height:30),
                _miniTrendSlider(),   // 👈 NEW MINI SLIDER
   SizedBox(height:30),

_occasionCarousel(),
   const SizedBox(height:40),

                _topStoriesSlider(),

SizedBox(height:30),


                _branches(),

                const SizedBox(height:120),

              ],
            ),
          )

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
        const Text(
          "BOREZY",
          style: TextStyle(
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

        const Icon(Icons.favorite_border),

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

              Container(
                height: 65,
                width: 65,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: NetworkImage(items[i]["image"]!),
                    fit: BoxFit.cover,
                  ),
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

  return Column(
    children: [

      /// HERO CAROUSEL
     CarouselSlider.builder(
  carouselController: carouselController,

        itemCount: banners.length,

        options: CarouselOptions(
height: 280, // big banner like Myntra/Max

viewportFraction: 1.0, // full width
enlargeCenterPage: false, // disable center zoom
enableInfiniteScroll: true,

autoPlay: true,
autoPlayInterval: const Duration(seconds: 4),
autoPlayAnimationDuration: const Duration(milliseconds: 900),
autoPlayCurve: Curves.easeInOut,

scrollPhysics: const BouncingScrollPhysics(),

pauseAutoPlayOnTouch: true,
pauseAutoPlayOnManualNavigate: true,

onPageChanged: (index, reason) {
setState(() {
activeIndex = index;
});
},
),

        itemBuilder: (context, index, realIndex) {

          final image = banners[index];

          return Container(

            margin: const EdgeInsets.symmetric(horizontal: 6),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(.15),
                  offset: const Offset(0, 10),
                )
              ],
            ),

            child: ClipRRect(

              borderRadius: BorderRadius.circular(24),

              child: Stack(
                children: [

                  /// IMAGE
                  CachedNetworkImage(
                    imageUrl: image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,

                    placeholder: (context, url) =>
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),

                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),

                  /// GRADIENT OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(.7),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),

                  /// TEXT CONTENT
                  Positioned(
                    left: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "ATHLETIC EDGE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "UNLEASHED",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Text(
                            "Min 45% OFF",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      const SizedBox(height: 12),

      /// DOT INDICATOR
      Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: banners.asMap().entries.map((entry) {

          bool isActive = activeIndex == entry.key;

          return AnimatedContainer(

            duration: const Duration(milliseconds: 300),

            margin: const EdgeInsets.symmetric(horizontal: 4),

            height: 6,

            width: isActive ? 18 : 6,

            decoration: BoxDecoration(
              color: isActive
                  ? Colors.deepPurple
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),

          );

        }).toList(),
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

          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.easeInOut,
        ),

        itemBuilder: (context, index, realIndex) {

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: CachedNetworkImage(
              imageUrl: stories[index],
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
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [


  /// FOR HER
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      "For Her",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  const SizedBox(height: 14),

  _genderSlider([
    {
      "title": "Lehenga",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fwomen%2F1777037686334_0727.webp?alt=media&token=f38a3156-d8cc-481b-9516-6e1339a9e7d3"
    },
    {
      "title": "Bridal",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fwomen%2F1777038649215_0534.webp?alt=media&token=f4b0573e-144c-4739-84c4-f850c950dc86"
    },
    {
      "title": "Maternity\nGown",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fwomen%2F1777038559603_0036%20(1).webp?alt=media&token=671033f8-5a1d-4a06-959b-c7d8763b1ac0"
    },
    {
      "title": "Designer\nGown",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fwomen%2F1777037665346_0548.webp?alt=media&token=39ce1f92-6c29-463d-b5c0-a86d88d074eb"
    },
  ]),

  const SizedBox(height: 28),

  /// FOR HIM
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      "For Him",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  const SizedBox(height: 14),

  _genderSlider([
    {
      "title": "Jodhpuri",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fmen%2F1774859915340_1774681546378_jodhpuri.webp?alt=media&token=2513dcb1-4bdd-478a-ac6e-9586971b3240"
    },
    {
      "title": "Suits",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fmen%2F1774859941775_1774681621407_suit.webp?alt=media&token=ce58b87d-8b4c-4423-93a5-993f9c9e2e41"
    },
    {
      "title": "Blazers",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fmen%2F1774859890472_1774681491397_blazzer%2011.webp?alt=media&token=8bc80a05-f751-4a34-ad04-f9b44c5d7b89"
    },
    {
      "title": "Sherwani",
      "image":
          "https://firebasestorage.googleapis.com/v0/b/dressonrent-e51be.firebasestorage.app/o/category_images%2Fmen%2F1774859811487_1774681409809_sherwani.webp?alt=media&token=c01b8d95-dba3-4781-8b15-e1f390de4526"
    },
  ]),
],


);
}
Widget _genderSlider(List<Map<String, String>> items) {

return SizedBox(
height: 220,


child: ListView.builder(
  scrollDirection: Axis.horizontal,
  padding: const EdgeInsets.symmetric(horizontal: 20),
  itemCount: items.length,

  itemBuilder: (context, index) {

    final item = items[index];

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),

        child: Stack(
          children: [

            CachedNetworkImage(
              imageUrl: item["image"]!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.65),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            Positioned(
              left: 14,
              bottom: 14,
              child: Text(
                item["title"]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
),


);
}
Widget _occasionCarousel() {

final occasions = [
{
"title": "Wedding",
"subtitle": "Royal Bridal & Groom Looks",
"image": "https://images.unsplash.com/photo-1520854221256-17451cc331bf"
},
{
"title": "Haldi",
"subtitle": "Bright Yellow Celebration",
"image": "https://images.unsplash.com/photo-1606800052052-a08af7148866"
},
{
"title": "Sangeet",
"subtitle": "Dance Ready Styles",
"image": "https://images.unsplash.com/photo-1519741497674-611481863552"
},
{
"title": "Reception",
"subtitle": "Elegant Evening Looks",
"image": "https://images.unsplash.com/photo-1509631179647-0177331693ae"
},
{
"title": "Pre Wedding",
"subtitle": "Photoshoot Perfect Outfits",
"image": "https://images.unsplash.com/photo-1511285560929-80b456fea0bc"
},
{
"title": "Maternity",
"subtitle": "Beautiful Maternity Gowns",
"image": "https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03"
},
];

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [


  /// PREMIUM HEADER
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Select By Occasion",
          style: TextStyle(
            fontSize: 28,
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

  /// OCCASION CAROUSEL
  CarouselSlider.builder(
    itemCount: occasions.length,

    options: CarouselOptions(
      height: 340,
      viewportFraction: 0.72,
      enlargeCenterPage: true,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 4),
    ),

    itemBuilder: (context, index, realIndex) {

      final item = occasions[index];

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
              blurRadius: 22,
              color: Colors.black.withOpacity(.18),
              offset: const Offset(0, 12),
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

              /// IMAGE
              Transform.scale(
                scale: 1.05,
                child: CachedNetworkImage(
                  imageUrl: item["image"]!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              /// GRADIENT
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(.75),
                      Colors.transparent
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              /// OCCASION BADGE
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item["title"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              /// CENTER TEXT
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      item["title"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item["subtitle"]!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(.2),
                          )
                        ],
                      ),
                      child: const Text(
                        "Explore Collection",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
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
],


);
}
Widget _promotionsSlider() {

final promos = [
{
"title": "Wedding Season Sale",
"subtitle": "Up to 40% Off Bridal Rentals",
"discount": "40% OFF",
"image":
"https://images.unsplash.com/photo-1520854221256-17451cc331bf"
},
{
"title": "Groom Special",
"subtitle": "Sherwani Rentals Starting ₹799",
"discount": "30% OFF",
"image":
"https://images.unsplash.com/photo-1617127365659-c47fa864d8bc"
},
{
"title": "Couple Combo",
"subtitle": "Bride + Groom Package Deals",
"discount": "SAVE ₹2000",
"image":
"https://images.unsplash.com/photo-1519741497674-611481863552"
},
{
"title": "Pre-Wedding Shoot",
"subtitle": "Perfect Outfits for Your Photos",
"discount": "25% OFF",
"image":
"https://images.unsplash.com/photo-1511285560929-80b456fea0bc"
},
];

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [


  /// HEADER
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      "Offers & Promotions",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  const SizedBox(height: 16),

  CarouselSlider.builder(
    itemCount: promos.length,

    options: CarouselOptions(
      height: 180,
      viewportFraction: 0.9,
      enlargeCenterPage: true,
      autoPlay: true,
      autoPlayInterval: Duration(seconds: 4),
    ),

    itemBuilder: (context, index, realIndex) {

      final item = promos[index];

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: Colors.black.withOpacity(.15),
              offset: const Offset(0, 8),
            )
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),

          child: Stack(
            children: [

              /// IMAGE
              CachedNetworkImage(
                imageUrl: item["image"]!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),

              /// GRADIENT
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

              /// TEXT
              Positioned(
                left: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      item["title"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      item["subtitle"]!,
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
                        item["discount"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
    },
  ),
],


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
 Widget _collectionsGrid() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Collections",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        StaggeredGrid.count(
          crossAxisCount: 2, // ⭐ important
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,

          children: [

            /// WOMEN (BIG)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1.4,
              child: _collectionCard(
                "Women",
                "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2F7007%2F3456789%2F1777489630637-7ca1239b-305f-43cd-aed2-18b43139a105.png?alt=media&token=4f7e05f0-e588-4ed6-84a1-71a869caa688",
              ).animate().fade().scale(),
            ),

            /// MEN
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _collectionCard(
                "Men",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuD6HyG7fn8eybgpz-RJnKxHZb3c29QNiLPKFs1fIrKEFQ4titGT3lFfbu0mC6p-1Kk3-3vkTTbMj-LJtukn7ZwYHokQasI82sWgjHuMruQV6iC7Su6Tkd5OMzhAk6NabWuNtSPu_sCajR5UmVDzh3YOBj0az_eiwWcAtMImxdglHVDX-5GbF86OQiABQWsSsIOrwKmKBKl0qVAU-NqO9Bh5SPhFyNbNnFdBbzscnh03khE32I4x1jYLaqQlPvnaootDoGfP4FeppCw",
              ),
            ),

            /// BRIDAL
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _collectionCard(
                "Bridal",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCMbZo3-3ETipRGA3MBkRTLXDL1MvKGumqT6LtajN7b7Ojwh5SFMxNhcQZbMn3y7_KSCAXx9Zllg-kQPOhOJrJsoIbKqLjvj_PpKwJ_nv1MJK7wahfd58NxJIqcq7FjRzKhzdRg929x3OFNeyrQ5wHGpYAFZoYrD5PAAfT8c7xjRe7bZccy5ngVTesRB-yTMLAazG0564KQq0tzY8RwDx11veY3VPG0yxonG2z4Pod8NfIP1z-jbqFLRL7DWOYTkn7JOb8f-yvPMYQ",
              ),
            ),

            /// SHERWANI
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _collectionCard(
                "Sherwani",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBkm8vlzaY8F0BusG9KNxmXEuCOZoFZrMfFay6Mz6mGhVlfGLElwB_MSY-wlQkTszbN8rqC2JuDItvVp63zpolv7ZvrolCOfU-GEE15Ti-ax-SeaMTddh0jsBQ0csPxu2lxpNGiwXiyDuwLGfnD75M0iaIxEtbONlNe-23n1wWQee8ZhH6Z3MJXK8v092nmg1psRDXZCyabx0oRd_y4G07a5R2KtWDOe74K9yrN3o9BKtDJs9Qp0vaTpsWGpS2qG5VPCZHweCOcPRc",
              ),
            ),

            /// RECEPTION
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 0.9,
              child: _collectionCard(
                "Reception",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBKt1tINdA4f0UEt-nWqLfQPpeZBN2RyMQKHVSvxcOp_UkeeFsGVj_QbxhdimJJWHPJHzt_Iie94UO6jliv9oqt9T9avO-V7PcEVjMZwTQTXh4IJIWeU9p5UFc11FMxlOauFfQs9vzJfOEp8gnNFfg1KsKSNY29jgQ6Nz0WgMoEkDnosHyUielU7FeUFZil9ZaVZnvx8_D-n1QFrXE5CGpmVzHHBB7UQS1EENWtUzlMzzyj8PTy4ze_DdXbUQ07adbJE4ymv_xA9KY",
              ),
            ),

            /// KIDS
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _collectionCard(
                "Kids",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBufWYlyQ8xFB5brDHX0Z-0wvJ60GoR-NJNRZizr00WhjTvZNVqQvDBUlt7-d9lP6WBegY3RHYus3ukcIEChsQLPXhFe97xca-nHa39stzsWR0VKaPtp_fRQSo7ADFgKhNwUzKlZBkrdjSG0d1VwOPnufXbSmR879WJrq3xye4DDgx85LCiTmRNGpVh9jXX2aHWWq9MU0F2b7CLI64fLYkMHdmPK1UhWrqdbhYz6MHVwA-wiTf9uYZf8N-l-P6XmoAo8vC8qHwI0hQ",
              ),
            ),

            /// ACCESSORIES
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _collectionCard(
                "Accessories",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBrWlE_ZPGGS4eGzmUfln3Z6D2-3yUlozcRAIe050GgINcxfoSva-q6UPC55gxw9v_9xgGoKinmqkoPCR3QoDvMNoYxPN80RkbWzeyja3f1oZ7_2dzNErArKeIPWdPwkFGIsq2RvTARG5kfXA-DJyqqOsNm5DDp8xCs-Q3CjkUCNP602fulhjPqYSBYu8VwqG3815jeFEuYpu1oi1QWxUidXx8qSh959TSlccgQRs1AiFIlYwRzcPk9ykOAz-WjM6dOP5Fv1HStBLs",
              ),
            ),

          ],
        ),
      ],
    ),
  );
}
  /// GLASSMORPHISM COLLECTION CARD
  Widget _collectionCard(String title,String image){

    return ClipRRect(

      borderRadius: BorderRadius.circular(26),

      child: Stack(

        children: [

          CachedNetworkImage(
            imageUrl:image,
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