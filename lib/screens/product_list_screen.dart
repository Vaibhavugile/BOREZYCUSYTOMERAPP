import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';
import 'product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/home_provider.dart';
import 'wishlist_screen.dart';

const Color _ink = Color(0xFF29221F);
const Color _muted = Color(0xFF8E857D);
const Color _gold = Color(0xFFB68A52);
const Color _line = Color(0xFFECE5DC);
const Color _cream = Color(0xFFFAF8F5);
const Color _softGold = Color(0xFFF7F0E7);

class ProductListScreen extends StatefulWidget {
  final String title;
  final String collectionKey;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.collectionKey,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  final List<DocumentSnapshot> products = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;
  bool hasMore = true;
  bool isFirstLoad = true;
  bool searchOpen = false;
  String selectedSort = 'Newest';
  String selectedBrand = 'All brands';
  String searchQuery = '';
  DocumentSnapshot? lastDoc;
  String? loadError;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || isLoading || !hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 260) {
      fetchProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    if (isLoading || !hasMore) return;
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final home = Provider.of<HomeProvider>(context, listen: false);
      final subs = home.subCollections
          .where((e) => e['collectionId'] == widget.collectionKey)
          .toList();
      final keys = subs.map((e) => '${e['collectionId']}_${e['id']}').toList();
      if (keys.isEmpty) keys.add(widget.collectionKey);

      Query query = FirebaseFirestore.instance
          .collection('products')
          .doc(TenantConfig.branchCode)
          .collection('products')
          .where('collectionKeys', arrayContainsAny: keys);

      if (selectedSort == 'Price Low To High') {
        query = query.orderBy('price');
      } else if (selectedSort == 'Price High To Low') {
        query = query.orderBy('price', descending: true);
      }

      query = query.limit(20);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc!);

      final snap = await query.get();
      if (!mounted) return;

      setState(() {
        if (snap.docs.isNotEmpty) {
          lastDoc = snap.docs.last;
          products.addAll(snap.docs);
        }
        if (snap.docs.length < 20) hasMore = false;
        isLoading = false;
        isFirstLoad = false;
      });
      if (_entranceController.status == AnimationStatus.dismissed) {
        _entranceController.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isFirstLoad = false;
        loadError = 'We couldn’t load products right now.';
      });
    }
  }

  Future<void> resetAndFetch() async {
    if (mounted) {
      setState(() {
        products.clear();
        lastDoc = null;
        hasMore = true;
        isFirstLoad = true;
        loadError = null;
      });
    }
    await fetchProducts();
  }

  List<MapEntry<DocumentSnapshot, Map<String, dynamic>>> get visibleProducts {
    final query = searchQuery.trim().toLowerCase();
    final list = <MapEntry<DocumentSnapshot, Map<String, dynamic>>>[];
    for (final doc in products) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final brand = (data['brandName'] ?? '').toString();
      final code = (data['productCode'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty &&
          !name.contains(query) &&
          !brand.toLowerCase().contains(query) &&
          !code.contains(query)) {
        continue;
      }
      if (selectedBrand != 'All brands' && brand != selectedBrand) continue;
      list.add(MapEntry(doc, data));
    }
    return list;
  }

  List<String> get availableBrands {
    final values = products
        .map((doc) {
          final data = doc.data() as Map?;
          return (data?['brandName'] ?? '').toString().trim();
        })
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All brands', ...values];
  }

  void _toggleSearch() {
    setState(() {
      searchOpen = !searchOpen;
      if (!searchOpen) {
        searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void showSortSheet() {
    const sorts = ['Newest', 'Price Low To High', 'Price High To Low'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Sort your edit',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Find your next favourite piece.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ...sorts.map((sort) {
                final selected = selectedSort == sort;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected ? _softGold : Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        if (selectedSort == sort) return;
                        setState(() => selectedSort = sort);
                        await resetAndFetch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected ? _gold : _line,
                            width: selected ? 1.3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sort,
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected ? _gold : _muted,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void showFilterSheet() {
    var temporaryBrand = selectedBrand;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Refine your style',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a brand to narrow your selection.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BRAND',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableBrands.map((brand) {
                    final selected = temporaryBrand == brand;
                    return ChoiceChip(
                      label: Text(brand),
                      selected: selected,
                      onSelected: (_) =>
                          setSheetState(() => temporaryBrand = brand),
                      backgroundColor: Colors.white,
                      selectedColor: _softGold,
                      labelStyle: TextStyle(
                        color: selected ? _ink : _muted,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(color: selected ? _gold : _line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() => temporaryBrand = 'All brands');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: _line),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => selectedBrand = temporaryBrand);
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleProducts;
    final wishlistCount =
        context.select<WishlistProvider, int>((w) => w.wishlistIds.length);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        titleSpacing: 10,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: searchOpen
              ? TextField(
                  key: const ValueKey('product-search'),
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search this collection',
                    hintStyle: TextStyle(color: _muted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
              : Column(
                  key: const ValueKey('collection-title'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'THE CURATED COLLECTION',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 8,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          _RoundIconButton(
            icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _WishlistButton(count: wishlistCount, onTap: _openWishlist),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _gold,
        backgroundColor: Colors.white,
        onRefresh: resetAndFetch,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 17),
                child: _CollectionHero(
                  title: widget.title,
                  count: visible.length,
                  hasFilter: selectedBrand != 'All brands',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedBrand == 'All brands'
                            ? 'DISCOVER THE EDIT'
                            : selectedBrand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    Text(
                      isFirstLoad ? 'CURATING…' : '${visible.length} PIECES',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isFirstLoad)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => const _ProductSkeleton(),
                    childCount: 6,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.57,
                  ),
                ),
              )
            else if (loadError != null && products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'A little pause',
                  subtitle: loadError!,
                  buttonText: 'Try again',
                  onTap: resetAndFetch,
                ),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.auto_awesome_outlined,
                  title: searchQuery.isNotEmpty
                      ? 'No pieces found'
                      : 'A fresh edit is coming',
                  subtitle: searchQuery.isNotEmpty
                      ? 'Try another name, brand or product code.'
                      : 'There are no products in this collection yet.',
                  buttonText: searchQuery.isNotEmpty ? 'Clear search' : null,
                  onTap: searchQuery.isNotEmpty
                      ? () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        }
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= visible.length) {
                        return const _LoadingProductCard();
                      }
                      final entry = visible[index];
                      return AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          final delay = (index % 6) * 0.07;
                          final progress = Curves.easeOutCubic.transform(
                            ((_entranceController.value - delay) /
                                    (1 - delay))
                                .clamp(0.0, 1.0),
                          );
                          return Opacity(
                            opacity: progress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - progress)),
                              child: child,
                            ),
                          );
                        },
                        child: _ProductCard(
                          product: entry.value,
                          productId: entry.key.id,
                          index: index,
                        ),
                      );
                    },
                    childCount: visible.length + (hasMore ? 1 : 0),
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 17,
                    childAspectRatio: 0.535,
                  ),
                ),
              ),
            if (loadError != null && products.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: TextButton.icon(
                    onPressed: fetchProducts,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Could not load more. Tap to retry.'),
                    style: TextButton.styleFrom(foregroundColor: _gold),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          border: const Border(top: BorderSide(color: _line)),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.035),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(
                  child: _BottomAction(
                    icon: Icons.swap_vert_rounded,
                    label: 'SORT',
                    detail: selectedSort == 'Newest'
                        ? 'Newest first'
                        : selectedSort == 'Price Low To High'
                            ? 'Price: low to high'
                            : 'Price: high to low',
                    onTap: showSortSheet,
                  ),
                ),
                Container(width: 1, height: 32, color: _line),
                Expanded(
                  child: _BottomAction(
                    icon: Icons.tune_rounded,
                    label: 'FILTER',
                    detail: selectedBrand == 'All brands'
                        ? 'Refine selection'
                        : selectedBrand,
                    active: selectedBrand != 'All brands',
                    onTap: showFilterSheet,
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

class _CollectionHero extends StatelessWidget {
  final String title;
  final int count;
  final bool hasFilter;

  const _CollectionHero({
    required this.title,
    required this.count,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF8), Color(0xFFF3E8D9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D9C5)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -13,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 90,
              color: _gold.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 1,
                    color: _gold,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SELECTED FOR YOU',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                hasFilter
                    ? 'A more personal selection, just for you.'
                    : 'Discover pieces made to stand out.',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE7D8C5)),
                ),
                child: Text(
                  '$count ${count == 1 ? 'PIECE' : 'PIECES'} TO EXPLORE',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map product;
  final String productId;
  final int index;

  const _ProductCard({
    required this.product,
    required this.productId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isLiked = wishlist.isWishlisted(productId);
    final name = (product['productName'] ?? '').toString();
    final brand = (product['brandName'] ?? '').toString();
    final productCode = (product['productCode'] ?? '').toString();
    final rawPrice = product['price'];
    final price =
        rawPrice == null ? 0 : int.tryParse(rawPrice.toString()) ?? 0;
    final imageList = product['imageUrls'];
    final image =
        imageList is List && imageList.isNotEmpty ? imageList[0].toString() : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                productId: productId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-image-$productId',
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 350),
                            placeholder: (_, __) => const _ImagePlaceholder(),
                            errorWidget: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          )
                        : const _ImagePlaceholder(),
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 10, color: _gold),
                          SizedBox(width: 4),
                          Text(
                            'CURATED',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 8,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: _HeartButton(
                      isLiked: isLiked,
                      onTap: () => wishlist.toggleById(productId, product),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _ink.withOpacity(0.83),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 12, color: Color(0xFFE4BE83)),
                          SizedBox(width: 3),
                          Text(
                            '4.2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      brand.isEmpty ? 'SIGNATURE EDIT' : brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name.isEmpty ? 'Selected piece' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (productCode.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'CODE  $productCode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '₹$price',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (price > 0)
                          Flexible(
                            child: Text(
                              '₹${price + 100}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 2,
                      width: 28,
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const _HeartButton({required this.isLiked, required this.onTap});

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    _scale = Tween<double>(begin: 1, end: 1.28).chain(
      CurveTween(curve: Curves.easeOutBack),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _HeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked && widget.isLiked) {
      _controller.forward(from: 0).then((_) {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: widget.isLiked ? const Color(0xFFB94D50) : _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 39,
          height: 39,
          child: Icon(icon, color: _ink, size: 19),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _WishlistButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 39,
          height: 39,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.favorite_border_rounded,
                  color: _ink, size: 19),
              if (count > 0)
                Positioned(
                  top: 2,
                  right: 1,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
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
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final bool active;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: active ? _softGold : _cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: active ? _gold : _ink, size: 19),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? _gold : _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1ECE5),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 30,
          color: _gold.withOpacity(0.55),
        ),
      ),
    );
  }
}

class _ProductSkeleton extends StatefulWidget {
  const _ProductSkeleton();

  @override
  State<_ProductSkeleton> createState() => _ProductSkeletonState();
}

class _ProductSkeletonState extends State<_ProductSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          const Color(0xFFF0EBE4),
          const Color(0xFFFAF7F2),
          _controller.value,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(color: color),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 8, width: 52, color: color),
                      const SizedBox(height: 10),
                      Container(height: 10, width: 90, color: color),
                      const SizedBox(height: 7),
                      Container(height: 8, width: 65, color: color),
                      const Spacer(),
                      Container(height: 15, width: 55, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingProductCard extends StatelessWidget {
  const _LoadingProductCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _gold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: _softGold,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: _gold),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (buttonText != null && onTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
