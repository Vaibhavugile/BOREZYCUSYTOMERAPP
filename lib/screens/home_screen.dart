import 'package:flutter/material.dart';
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
    "https://images.openai.com/static-rsc-4/mGqToIqQX0anumZAFEcDuYirLwMUQcpASgyLFXZZi4r1XsJi5Y2W_m8hueDROjHCv3en_kjIctrCvG1LcD3EHqZEYoAJTh116vDhw41NEeHG3YJGkEV3nnMCF3lEdXkE4vURLNXmzIKiekAb5UDJroGiA-8pBW0dsxfHpwTiuz10XHBZP1-UNLyGla-uYDJb?purpose=fullsize",
    "https://images.openai.com/static-rsc-4/_c9NVpLWJfDYhJWc4IY56LPDaSOzNj6rMrAM7NpCQ0HIvtahOaLsJBtC79pJ7DuWn_A64mqthAEgdrD0fzBTvcVLrZ4cy6t9ttUqdHr_HSOfmfCPq6ZxBehI5FF4aQposefR22Pv_MNrltgd2UgoPpONMJGCtkXT575dzQatV1p7-xnCnz6yoAMMoGW1OxJb?purpose=fullsize",

    "https://images.unsplash.com/photo-1593032465175-481ac7f401a0",
    "https://images.unsplash.com/photo-1537832816519-689ad163238b",
  ];

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

                _heroSlider(),

                const SizedBox(height:30),

                _categories(),

                const SizedBox(height:30),

                _collectionsGrid(),

                const SizedBox(height:40),

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
  Widget _topBar(){

    return SliverAppBar(

      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,

      title: const Text(
        "BOREZY",
        style: TextStyle(
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),

      actions: const [
        Padding(
          padding: EdgeInsets.only(right:20),
          child: Icon(Icons.shopping_bag_outlined,color: Colors.deepPurple),
        )
      ],
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

  /// HERO SLIDER
  Widget _heroSlider(){

    return CarouselSlider(

      options: CarouselOptions(
        height:220,
        viewportFraction:0.92,
        autoPlay:true,
        enlargeCenterPage:true
      ),

      items: banners.map((img){

        return ClipRRect(

          borderRadius: BorderRadius.circular(26),

          child: Stack(

            children: [

              CachedNetworkImage(
                imageUrl: img,
                width: double.infinity,
                fit: BoxFit.cover,

                placeholder:(c,u)=>Shimmer.fromColors(
                  baseColor:Colors.grey.shade300,
                  highlightColor:Colors.grey.shade100,
                  child:Container(color:Colors.white),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:[
                      Colors.black.withOpacity(.6),
                      Colors.transparent
                    ],
                    begin:Alignment.bottomCenter,
                    end:Alignment.center
                  ),
                ),
              ),

              const Positioned(
                left:20,
                bottom:20,
                child: Text(
                  "Luxury Wedding Collection",
                  style: TextStyle(
                    color:Colors.white,
                    fontSize:22,
                    fontWeight:FontWeight.bold
                  ),
                ),
              )

            ],
          ),
        );

      }).toList(),
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