import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../wishlist/wishlist_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Map product;
  final String productId;

  const ProductCard({
    super.key,
    required this.product,
    required this.productId,
  });

  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);

  String _text(dynamic value) => value?.toString().trim() ?? '';

  int _price(dynamic value) {
    if (value is num) return value.round();
    if (value == null) return 0;
    return int.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final safeId = productId.toString();
    final isLiked = context.select<WishlistProvider, bool>(
      (wishlist) => wishlist.isWishlisted(safeId),
    );
    final wishlist = context.read<WishlistProvider>();

    final name = _text(product['productName']);
    final brand = _text(product['brandName']);
    final productCode = _text(product['productCode']);
    final price = _price(product['price']);

    final dynamic rawImages = product['imageUrls'];
    final image = rawImages is List && rawImages.isNotEmpty
        ? _text(rawImages.first)
        : '';

    // Do not invent a sale price, discount or rating when the product data
    // does not contain those values.
    final rating = product['rating'];
    final ratingText = rating == null ? '' : _text(rating);
    final discount = _price(product['discountPercent']);
    final originalPrice = _price(product['originalPrice']);

    return Semantics(
      button: true,
      label: [
        brand,
        name,
        if (price > 0) '₹$price',
      ].where((part) => part.isNotEmpty).join(', '),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 360),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, animation, secondaryAnimation) =>
                    ProductDetailScreen(
                  product: product,
                  productId: productId,
                ),
                transitionsBuilder: (_, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.035),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line.withOpacity(0.9)),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.035),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(
                  imageUrl: image,
                  brand: brand,
                  isWishlisted: isLiked,
                  ratingText: ratingText,
                  onWishlistTap: () => wishlist.toggleById(safeId, product),
                ),
                Expanded(
                  child: Padding(
                   padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (brand.isNotEmpty || productCode.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  brand.isNotEmpty ? brand.toUpperCase() : 'COLLECTION',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB68A52),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.35,
                                  ),
                                ),
                              ),
                              if (productCode.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    productCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 6),
                        Text(
                          name.isEmpty ? 'Untitled product' : name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF29221F),
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _PriceBlock(
                                price: price,
                                originalPrice: originalPrice,
                                discountPercent: discount,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF29221F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                color: Color(0xFFE0BD8D),
                                size: 17,
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
        ),
      ),
    );
  }
}

class _ProductImage extends StatefulWidget {
  final String imageUrl;
  final String brand;
  final bool isWishlisted;
  final String ratingText;
  final VoidCallback onWishlistTap;

  const _ProductImage({
    required this.imageUrl,
    required this.brand,
    required this.isWishlisted,
    required this.ratingText,
    required this.onWishlistTap,
  });

  static const Color _ink = Color(0xFF29221F);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _softGold = Color(0xFFF7F0E7);

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF29221F);
  late final AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0.86,
      upperBound: 1.16,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWishlisted != widget.isWishlisted && widget.isWishlisted) {
      _heartController.forward(from: 0.86).then((_) {
        if (mounted) _heartController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.95,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'product-card-image-${widget.imageUrl}-${widget.brand}',
            child: widget.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 350),
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x26000000),
                  Colors.transparent,
                  Color(0x24000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB68A52),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'CURATED',
                    style: TextStyle(
                      color: Color(0xFF29221F),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 9,
            right: 9,
            child: Material(
              color: Colors.white.withOpacity(0.95),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onWishlistTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: ScaleTransition(
                      scale: _heartController,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          widget.isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(widget.isWishlisted),
                          color: widget.isWishlisted ? const Color(0xFFB94E55) : _ink,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.ratingText.isNotEmpty)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFB68A52)),
                    const SizedBox(width: 3),
                    Text(
                      widget.ratingText,
                      style: const TextStyle(
                        color: Color(0xFF29221F),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _ProductImage._softGold,
      child: const Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 34,
          color: _ProductImage._gold,
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final int price;
  final int originalPrice;
  final int discountPercent;

  const _PriceBlock({
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
  });

  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);

  @override
  Widget build(BuildContext context) {
    final hasOriginal = originalPrice > price && price >= 0;
    final hasDiscount = discountPercent > 0 && discountPercent <= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RENTAL PRICE',
          style: TextStyle(
            color: _muted.withOpacity(0.95),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          runSpacing: 2,
          children: [
            Text(
              '₹$price',
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (hasOriginal)
              Text(
                '₹$originalPrice',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (hasDiscount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$discountPercent% OFF',
              style: const TextStyle(
                color: _gold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
