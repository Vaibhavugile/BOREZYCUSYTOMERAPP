import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_card.dart';

const Color _ink = Color(0xFF29221F);
const Color _muted = Color(0xFF8E857D);
const Color _gold = Color(0xFFB68A52);
const Color _line = Color(0xFFECE5DC);
const Color _cream = Color(0xFFFAF8F5);
const Color _softGold = Color(0xFFF7F0E7);

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

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentPage = 0;
  int selectedSize = 1;
  final List<String> sizes = const ['S', 'M', 'L', 'XL'];
  bool _imagesPrecached = false;
  bool _isFavorite = false;
  late final AnimationController _entranceController;
  late final AnimationController _favoriteController;

  List<String> get _images {
    final raw = widget.product['imageUrls'];
    if (raw is! List) return [];
    return raw
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => item.toString())
        .toList();
  }

  String _imageUrl(String source, {int width = 1000}) {
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasScheme) return source;
    final params = Map<String, String>.from(uri.queryParameters);
    params['w'] = '$width';
    return uri.replace(queryParameters: params).toString();
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    for (final image in _images.take(5)) {
      precacheImage(CachedNetworkImageProvider(_imageUrl(image, width: 1000)), context);
    }
    _imagesPrecached = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _showActionMessage(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            '$action flow is not connected on this screen yet.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    if (_isFavorite) {
      _favoriteController.forward(from: 0).then((_) {
        if (mounted) _favoriteController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = (product['productName'] ?? 'Selected piece').toString();
    final brand = (product['brandName'] ?? '').toString();
    final productCode = (product['productCode'] ?? '').toString();
    final rawPrice = product['price'];
    final price = rawPrice == null ? 0 : int.tryParse(rawPrice.toString()) ?? 0;
    final images = _images;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildGallery(images),
              ),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    final value = Curves.easeOutCubic.transform(
                      _entranceController.value,
                    );
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 22 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductInformation(
                          brand: brand,
                          productCode: productCode,
                          name: name,
                          price: price,
                        ),
                        const SizedBox(height: 14),
                        _buildRentalInfo(),
                        const SizedBox(height: 14),
                        _buildSizeSelector(),
                        const SizedBox(height: 22),
                        _buildDetailsNote(),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _similarProducts(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 124)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    Row(
                      children: [
                        _GlassIconButton(
                          icon: _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: _isFavorite ? const Color(0xFFB94D50) : _ink,
                          onTap: _toggleFavorite,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.18).animate(
                              CurvedAnimation(
                                parent: _favoriteController,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _isFavorite
                                  ? const Color(0xFFB94D50)
                                  : _ink,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        _GlassIconButton(
                          icon: Icons.shopping_bag_outlined,
                          onTap: () => _showActionMessage('Bag'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (context, index) {
                final image = images[index];
                return GestureDetector(
                  onTap: () => _openFullScreenImage(image),
                  child: Hero(
                    tag: 'product-detail-${widget.productId}-$index',
                    child: CachedNetworkImage(
                      imageUrl: _imageUrl(image, width: 1200),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 400),
                      placeholder: (_, __) => const _GalleryPlaceholder(),
                      errorWidget: (_, __, ___) => const _GalleryPlaceholder(
                        showError: true,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const _GalleryPlaceholder(showError: true),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x26000000),
                      Colors.transparent,
                      Color(0x42000000),
                    ],
                    stops: [0, 0.36, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 23,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _gold, size: 13),
                  SizedBox(width: 6),
                  Text(
                    'THE SIGNATURE EDIT',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 18,
              bottom: 23,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: _ink.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${currentPage + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final active = currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.fromLTRB(3, 0, 3, 9),
                    width: active ? 22 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white60,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInformation({
    required String brand,
    required String productCode,
    required String name,
    required int price,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  brand.isEmpty ? 'CURATED COLLECTION' : brand.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              if (productCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID  $productCode',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: _ink,
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$price',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, bottom: 5),
                child: Text(
                  '/ 3 days',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _softGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: _gold),
                    SizedBox(width: 4),
                    Text(
                      '4.2',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: _line),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 17, color: _gold),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'A standout piece, selected for your next occasion.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFCF8), Color(0xFFF7F0E7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9DCCB)),
      ),
      child: const Row(
        children: [
          _InfoIcon(icon: Icons.calendar_month_outlined),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Made for your moment',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose your dates when you continue to booking.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: _gold, size: 13),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SELECT YOUR SIZE',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showSizeGuide(),
                style: TextButton.styleFrom(
                  foregroundColor: _gold,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 25),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Size guide',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(sizes.length, (index) {
              final selected = selectedSize == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == sizes.length - 1 ? 0 : 9),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected ? _ink : _cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? _ink : _line),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selectedSize = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Center(
                            child: Text(
                              sizes[index],
                              style: TextStyle(
                                color: selected ? Colors.white : _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showSizeGuide() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Size guide',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the size that usually fits you best. For exact measurements, please check the product label or contact the store.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              const Text(
                'Available sizes:  S   M   L   XL',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_outlined, color: _gold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The details matter',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Explore the images up close, then choose your size and continue when you are ready.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        border: const Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showActionMessage('Schedule trial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Schedule Trial',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                flex: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gold, Color(0xFF9E713F)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.24),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showActionMessage('Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(String image) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _FullScreenImage(
            imageUrl: _imageUrl(image, width: 1600),
          ),
        ),
      ),
    );
  }

  Widget _similarProducts() {
    final rawKeys = widget.product['collectionKeys'];
    if (rawKeys is! List || rawKeys.isEmpty) return const SizedBox.shrink();

    final collectionKey = rawKeys.first;
    final branch = (widget.product['branch'] ?? '7007').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.025),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOU MAY ALSO LOVE',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 9,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Similar pieces',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 21,
                          letterSpacing: -0.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: _gold, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 280,
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(branch)
                  .collection('products')
                  .where('collectionKeys', arrayContains: collectionKey)
                  .limit(10)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Similar products are unavailable right now.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, index) => Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 18 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _line),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs
                    .where((doc) => doc.id != widget.productId)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No similar products yet',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 18 : 12,
                        right: index == docs.length - 1 ? 18 : 0,
                      ),
                      child: SizedBox(
                        width: 160,
                        child: ProductCard(
                          product: doc.data(),
                          productId: doc.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? child;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = _ink,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: _ink.withOpacity(0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 43,
          height: 43,
          child: Center(
            child: child ?? Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;

  const _InfoIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9DCCB)),
      ),
      child: Icon(icon, color: _gold, size: 19),
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  final bool showError;

  const _GalleryPlaceholder({this.showError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EBE4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showError ? Icons.image_not_supported_outlined : Icons.image_outlined,
              size: 38,
              color: _gold.withOpacity(0.65),
            ),
            const SizedBox(height: 8),
            const Text(
              'PRODUCT IMAGE',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(
                      color: _gold,
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
              child: _GlassIconButton(
                icon: Icons.close_rounded,
                iconColor: Colors.white,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
