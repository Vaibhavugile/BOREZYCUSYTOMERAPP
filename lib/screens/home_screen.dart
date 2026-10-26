import 'dart:async';

import 'package:flutter/material.dart';

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/tenant_config.dart';
import 'product_list_screen.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
import '../providers/home_provider.dart'; // ✅ ADDED
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wishlist_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/user_helper.dart';
import 'rent_your_dress_screen.dart';
import 'credit_history_screen.dart';
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EFE7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.checkroom_outlined,
        color: Color(0xFFB68A52),
        size: 30,
      ),
    );
  }
}


class _PremiumReveal extends StatefulWidget {
  const _PremiumReveal({
    required this.child,
    this.offset = const Offset(0, 0.035),
  });

  final Widget child;
  final Offset offset;

  @override
  State<_PremiumReveal> createState() => _PremiumRevealState();
}

class _PremiumRevealState extends State<_PremiumReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color _canvas = Color(0xFFFAF8F5);
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _softGold = Color(0xFFF7F0E7);
  static const Color _line = Color(0xFFECE5DC);

  bool loadRest = false;
  final List<Map<String, String>> notifications = [];
  StreamSubscription<RemoteMessage>? _messageSubscription;
  late final AnimationController _entranceController;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pageFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();

  /// Wishlist init
  Future.microtask(() {
    Provider.of<WishlistProvider>(context, listen: false)
        .initWishlist();
  });

  /// 🔔 FOREGROUND NOTIFICATION
  _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {

  final title =
      message.notification?.title ?? "Notification";

  final body =
      message.notification?.body ?? "";

  /// 🔥 SAVE NOTIFICATION
  notifications.insert(0, {
    "title": title,
    "body": body,
  });

  if (mounted) {
    setState(() {});
  }

  /// 🔥 OPTIONAL SNACKBAR
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

  SnackBar(
    behavior: SnackBarBehavior.floating,

    backgroundColor: Colors.transparent,
    elevation: 0,

    margin: const EdgeInsets.all(16),

    content: Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF30251F),
            Color(0xFF76583E),
          ],
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 12,
          )
        ],
      ),

      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  body,

                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ),

    duration: const Duration(seconds: 3),
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

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  int activeIndex = 0;
  final CarouselSliderController carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);

    if (home.isLoading) {
      return const Scaffold(
        backgroundColor: _canvas,
        body: Center(
          child: CircularProgressIndicator(
            color: _gold,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: _buildHomeContent(),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      cacheExtent: 1600,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _topBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 2),
              _PremiumReveal(child: _editorialIntro()),
              const SizedBox(height: 10),
              _PremiumReveal(child: _heroSlider()),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: loadRest
              ? Column(
                  children: [
                    const SizedBox(height: 2),
                    _PremiumReveal(child: _collectionsGrid()),
                    const SizedBox(height: 24),
                    _miniTrendSlider(),
                    const SizedBox(height: 16),
                    _PremiumReveal(child: _dorExperienceSection()),
                    const SizedBox(height: 24),
                  ],
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: _gold,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _editorialIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DOR • Dress On Rent',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Luxury looks. Lighter living.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Discover your next signature look.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _line),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _gold,
              size: 21,
            ),
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
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    backgroundColor: _canvas,
    toolbarHeight: 72,
    automaticallyImplyLeading: false,

    title: Row(
      children: [

        /// 🏷 APP NAME
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF30251F), Color(0xFF76583E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.diamond_rounded,
            color: Color(0xFFE5C995),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TenantConfig.appName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.4,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Dress On Rent',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.1,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        /// 🔔 NOTIFICATION
    GestureDetector(
  onTap: () {
    showNotificationsSheet();
  },

  child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _line),
    ),
    alignment: Alignment.center,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          size: 22,
          color: _ink,
        ),

      /// 🔥 BADGE
      if (notifications.isNotEmpty)
        Positioned(
          right: -4,
          top: -4,

          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),

            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(20),
            ),

            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),

            child: Text(
              notifications.length > 9
                  ? "9+"
                  : notifications.length.toString(),

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
    ),
  ),
),

        const SizedBox(width: 9),

        /// 💰 WALLET (LIVE FROM FIRESTORE)
        GestureDetector(
         onTap: () async {

  final phone =
      await UserHelper.getPhone();

  if (phone == null) return;

  Navigator.push(
    context,

    MaterialPageRoute(
      builder: (_) => CreditHistoryScreen(
        mobileNumber: phone,
      ),
    ),
  );
},
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
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
    return StreamBuilder<QuerySnapshot>(

  stream: FirebaseFirestore.instance
      .collection("products")
      .doc(TenantConfig.branchCode)
      .collection("creditNotes")
      .where(
        "mobileNumber",
        isEqualTo: phone,
      )
      .limit(1)
      .snapshots(),

  builder: (context, snapshot) {

    int wallet = 0;

    if (snapshot.hasData &&
        snapshot.data != null &&
        snapshot.data!.docs.isNotEmpty) {

      final data =
          snapshot.data!.docs.first.data()
              as Map<String, dynamic>;

      final rawBalance = data["Balance"];
      wallet = rawBalance is num
          ? rawBalance.toInt()
          : int.tryParse(rawBalance?.toString() ?? '') ?? 0;
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

        const SizedBox(width: 9),

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 21,
              color: _ink,
            ),
          ),

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
          height: 228,
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
              borderRadius: BorderRadius.circular(24),

              child: Stack(
                children: [

                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      placeholder: (_, __) => const _ImagePlaceholder(),
                      errorWidget: (_, __, ___) => const _ImagePlaceholder(),
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
                  ? _gold
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    ],
  );
}
Widget _rentYourDressBanner() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RentYourDressScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF251D19), Color(0xFF6B5038)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF30251F).withOpacity(0.14),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE DOR WARDROBE CIRCLE',
                    style: TextStyle(
                      color: Color(0xFFE5C995),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your wardrobe can earn.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Share your outfits. Earn or get Dor credits.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'EXPLORE THE PROGRAM  ↗',
                    style: TextStyle(
                      color: Color(0xFFE5C995),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(
              Icons.checkroom_outlined,
              color: Color(0xFFE5C995),
              size: 48,
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _dorExperienceSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7D9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7D9C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "STYLE, YOUR WAY",
                      style: TextStyle(
                        color: Color(0xFF967044),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Wear the moment.\\nKeep the memories.",
                      style: TextStyle(
                        color: Color(0xFF29221F),
                        fontSize: 22,
                        height: 1.13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your next favourite look is closer than you think.",
                      style: TextStyle(
                        color: const Color(0xFF51473F).withOpacity(0.82),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 76,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF30251F),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Color(0xFFE5C995),
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFFDCCBB5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _experiencePoint(
                  icon: Icons.checkroom_outlined,
                  title: "Curated looks",
                  subtitle: "For your plans",
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: const Color(0xFFDCCBB5),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _experiencePoint(
                  icon: Icons.auto_awesome_outlined,
                  title: "DOR credits",
                  subtitle: "More wardrobe value",
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _experiencePoint({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Icon(icon, size: 20, color: const Color(0xFF967044)),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF29221F),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8E857D),
                fontSize: 9,
                height: 1.25,
              ),
            ),
          ],
        ),
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

      final normalizedTitle = title.toString().toLowerCase();
      final isWomenSection = normalizedTitle.contains("women") ||
          normalizedTitle.contains("woman") ||
          normalizedTitle.contains("ladies") ||
          normalizedTitle.contains("female");
      final isMenSection = normalizedTitle.contains("men") ||
          normalizedTitle.contains("mens") ||
          normalizedTitle.contains("men's") ||
          normalizedTitle.contains("gentlemen");

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// EDITORIAL SECTION HEADER — intentionally different from the collection tiles.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWomenSection ? 'THE WOMEN’S EDIT' :
                            isMenSection ? 'THE MEN’S EDIT' : 'CURATED SELECTION',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 9,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 23,
                          height: 1.0,
                          letterSpacing: -0.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: .25, end: .85),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    width: 42,
                    height: 1,
                    color: _gold.withOpacity(value),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

          const SizedBox(height: 14),
          if (isWomenSection) ...[
            _rentYourDressBanner(),
            const SizedBox(height: 18),
          ] else if (isMenSection && !collections.any((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final t = (d["title"] ?? "").toString().toLowerCase();
            return t.contains("women") || t.contains("woman") ||
                t.contains("ladies") || t.contains("female");
          })) ...[
            _rentYourDressBanner(),
            const SizedBox(height: 18),
          ],
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

        return TweenAnimationBuilder<double>(
          key: ValueKey('subcollection-card-${item["subcollectionId"] ?? item["title"]}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 520 + (index * 85)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(
                offset: Offset(18 * (1 - value), 0),
                child: Transform.scale(
                  scale: 0.97 + (0.03 * value),
                  child: child,
                ),
              ),
            );
          },
          child: GestureDetector(
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
                    imageUrl: item["image"] ?? "",
                    placeholder: (_, __) => const _ImagePlaceholder(),
                    errorWidget: (_, __, ___) => const _ImagePlaceholder(),
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
          ),
        );
      },
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
          "THE COLLECTION ATELIER",
          style: TextStyle(
            fontSize: 21,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Prevent GridView from inheriting the screen's top/bottom
          // MediaQuery padding, which creates large blank gaps here.
          padding: EdgeInsets.zero,

          itemCount: collections.length,

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: collections.length == 1 ? 1 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,

            /// 🔥 better sizing
            childAspectRatio: collections.length == 1 ? 1.45 : 0.90,
          ),

          itemBuilder: (context, index) {

            final data = collections[index].data() as Map<String, dynamic>;
            final doc = collections[index];

            return TweenAnimationBuilder<double>(
              key: ValueKey('collection-card-${doc.id}'),
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 620 + (index * 110)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, 22 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.965 + (0.035 * value),
                      child: child,
                    ),
                  ),
                );
              },
              child: _collectionCard(
                data["title"] ?? "",
                data["imageUrl"] ?? "",
                doc.id,
              ),
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
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImagePlaceholder(),
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
void showNotificationsSheet() {

  showModalBottomSheet(
    context: context,

    isScrollControlled: true,
    backgroundColor: Colors.transparent,

    builder: (_) {

      return Container(
        height: MediaQuery.of(context).size.height * .78,

        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),

        decoration: const BoxDecoration(
          color: _canvas,

          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Center(
              child: Container(
                width: 50,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Notifications",

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: notifications.isEmpty

                  ? const Center(
                      child: Text(
                        "No notifications yet",
                      ),
                    )

                  : ListView.builder(
                      itemCount: notifications.length,

                      itemBuilder: (context, index) {

                        final item = notifications[index];

                        return Dismissible(

  key: Key(index.toString()),

  direction: DismissDirection.endToStart,

  onDismissed: (_) {

    setState(() {
      notifications.removeAt(index);
    });
  },

  background: Container(
    alignment: Alignment.centerRight,

    padding: const EdgeInsets.only(right: 24),

    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(20),
    ),

    child: const Icon(
      Icons.delete,
      color: Colors.white,
    ),
  ),

  child: notificationTile(
    Icons.notifications,
    item["title"] ?? "",
    item["body"] ?? "",
  ),
);
                      },
                    ),
            )
          ],
        ),
      );
    },
  );
}
Widget notificationTile(
  IconData icon,
  String title,
  String subtitle,
) {

  return Container(
    margin: const EdgeInsets.only(bottom: 14),

    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: _softGold,
      borderRadius: BorderRadius.circular(20),
    ),

    child: Row(
      children: [

        Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: _gold,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              )
            ],
          ),
        )
      ],
    ),
  );
}
  /// BRANCHES
 

 
}