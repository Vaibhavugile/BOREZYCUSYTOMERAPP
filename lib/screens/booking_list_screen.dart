import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'BookingDetailsScreen.dart';
import '../services/tenant_config.dart';
import '../services/user_helper.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen>
    with TickerProviderStateMixin {
  // Premium cream / champagne / espresso palette.
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);
  static const Color _white = Colors.white;

  int selectedTab = 0;
  late Future<String?> _phoneFuture;
  Future<QuerySnapshot<Map<String, dynamic>>>? _paymentsFuture;
  String? _loadedPhone;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _phoneFuture = UserHelper.getPhone();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _paymentsFuture = null;
    _loadedPhone = null;
    _phoneFuture = UserHelper.getPhone();
    if (mounted) setState(() {});
    try {
      await _phoneFuture;
    } catch (_) {
      // The screen's FutureBuilder presents the relevant error state.
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  bool matchStage(String stage) {
    if (selectedTab == 0) {
      return stage == 'Booking' || stage == 'pickupPending';
    }
    if (selectedTab == 1) {
      return stage == 'pickup' ||
          stage == 'returnPending' ||
          stage == 'return';
    }
    return stage == 'successful' ||
        stage == 'cancelled' ||
        stage == 'postponed';
  }

  Color stageColor(String stage) {
    switch (stage) {
      case 'Booking':
      case 'pickupPending':
        return const Color(0xFFB87931);
      case 'pickup':
      case 'returnPending':
      case 'return':
        return const Color(0xFF5279A6);
      case 'successful':
        return const Color(0xFF43856A);
      case 'cancelled':
        return const Color(0xFFB85B55);
      case 'postponed':
        return const Color(0xFF8C72A7);
      default:
        return _muted;
    }
  }

  String stageLabel(String stage) {
    switch (stage) {
      case 'pickupPending':
        return 'Pickup pending';
      case 'pickup':
        return 'Picked up';
      case 'returnPending':
        return 'Return pending';
      case 'return':
        return 'Returned';
      case 'successful':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'postponed':
        return 'Postponed';
      default:
        return stage.isEmpty ? 'Booking' : stage;
    }
  }

  DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _money(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is num) {
      return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
    }
    return '₹$amount';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _productsFrom(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.map(_asMap).toList();
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'successful':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'postponed':
        return Icons.event_busy_rounded;
      case 'pickup':
        return Icons.local_shipping_rounded;
      case 'return':
        return Icons.assignment_turned_in_rounded;
      case 'returnPending':
        return Icons.inventory_2_rounded;
      default:
        return Icons.event_available_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<String?>(
                future: _phoneFuture,
                builder: (context, phoneSnap) {
                  if (phoneSnap.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  }
                  if (phoneSnap.hasError) {
                    return _buildMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Couldn’t load your bookings',
                      subtitle: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _refresh,
                    );
                  }
                  final phone = phoneSnap.data?.trim();
                  if (phone == null || phone.isEmpty) {
                    return _buildMessage(
                      icon: Icons.calendar_month_rounded,
                      title: 'No bookings yet',
                      subtitle: 'Your rental bookings will appear here.',
                    );
                  }

                  if (_loadedPhone != phone || _paymentsFuture == null) {
                    _loadedPhone = phone;
                    _paymentsFuture = FirebaseFirestore.instance
                        .collection('products')
                        .doc(TenantConfig.branchCode)
                        .collection('payments')
                        .where('contact', isEqualTo: phone)
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .get();
                  }

                  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: _paymentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoading();
                      }
                      if (snapshot.hasError) {
                        return _buildMessage(
                          icon: Icons.cloud_off_rounded,
                          title: 'Unable to fetch bookings',
                          subtitle:
                              'Please try again in a moment. Your booking data has not been changed.',
                          actionLabel: 'Retry',
                          onAction: _refresh,
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = docs.where((doc) {
                        final stage =
                            (doc.data()['bookingStage'] ?? '').toString();
                        return matchStage(stage);
                      }).toList();

                      return RefreshIndicator(
                        color: _gold,
                        backgroundColor: _white,
                        onRefresh: _refresh,
                        child: filteredDocs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                                children: [
                                  _buildEmptyTab(),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 32),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredDocs[index];
                                  return _buildAnimatedCard(
                                    index: index,
                                    data: doc.data(),
                                  );
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: AnimatedBuilder(
        animation: _introController,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_introController.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _softGold,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _line),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: _gold,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR JOURNEY',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _line),
              ),
              child: IconButton(
                tooltip: 'Refresh bookings',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, color: _ink, size: 21),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    const labels = ['Upcoming', 'Current', 'Past'];
    const icons = [
      Icons.event_available_rounded,
      Icons.local_shipping_rounded,
      Icons.history_rounded,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBE4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line.withOpacity(0.85)),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final active = selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (selectedTab != index) {
                    setState(() => selectedTab = index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: active ? _white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _ink.withOpacity(0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[index],
                        size: 15,
                        color: active ? _gold : _muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? _ink : _muted,
                            fontSize: 12,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required Map<String, dynamic> data,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${data['receiptNumber'] ?? index}-$selectedTab'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index.clamp(0, 6) * 65).toInt()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _BookingCard(
        data: data,
        formatDate: formatDate,
        stageColor: stageColor,
        stageLabel: stageLabel,
        stageIcon: _stageIcon,
        productsFrom: _productsFrom,
        dateFrom: _dateFrom,
        money: _money,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(booking: data),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: List.generate(3, (index) {
        return Container(
          height: 235,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _skeleton(78, 98, radius: 16),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeleton(100, 22, radius: 20),
                        const SizedBox(height: 12),
                        _skeleton(145, 17),
                        const SizedBox(height: 9),
                        _skeleton(90, 13),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 18),
              _skeleton(210, 14),
              const Spacer(),
              _skeleton(double.infinity, 1),
              const SizedBox(height: 14),
              _skeleton(double.infinity, 18),
            ],
          ),
        );
      }),
    );
  }

  Widget _skeleton(double width, double height, {double radius = 8}) {
    return Container(
      width: width.isInfinite ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmptyTab() {
    final titles = [
      'Nothing planned yet',
      'No active rentals',
      'Your history starts here',
    ];
    final descriptions = [
      'When you book your next look, you’ll find all the details here.',
      'Your active pickups and returns will appear here.',
      'Completed and previous bookings will be kept here for you.',
    ];
    final icons = [
      Icons.calendar_month_rounded,
      Icons.local_shipping_outlined,
      Icons.auto_stories_rounded,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _softGold,
                border: Border.all(color: _line),
              ),
              child: Icon(icons[selectedTab], size: 42, color: _gold),
            ),
            const SizedBox(height: 24),
            Text(
              titles[selectedTab],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                descriptions[selectedTab],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_down_rounded, color: _gold, size: 16),
                  SizedBox(width: 7),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _softGold,
              ),
              child: Icon(icon, color: _gold, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: _white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                child: Text(actionLabel),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.data,
    required this.formatDate,
    required this.stageColor,
    required this.stageLabel,
    required this.stageIcon,
    required this.productsFrom,
    required this.dateFrom,
    required this.money,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final String Function(DateTime) formatDate;
  final Color Function(String) stageColor;
  final String Function(String) stageLabel;
  final IconData Function(String) stageIcon;
  final List<Map<String, dynamic>> Function(dynamic) productsFrom;
  final DateTime? Function(dynamic) dateFrom;
  final String Function(dynamic) money;
  final VoidCallback onTap;

  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _softGold = Color(0xFFF7F0E7);

  @override
  Widget build(BuildContext context) {
    final stage = (data['bookingStage'] ?? 'Booking').toString();
    final receipt = (data['receiptNumber'] ?? 'Booking').toString();
    final amount = money(data['totalAmount']);
    final pickup = dateFrom(data['pickupDate']);
    final returnDate = dateFrom(data['returnDate']);
    final products = productsFrom(data['products']);
    final image = products.isNotEmpty
        ? (products.first['imageUrl'] ?? '').toString()
        : '';
    final codes = products
        .map((p) => (p['productCode'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toList();
    final color = stageColor(stage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _line.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'booking-image-$receipt',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: SizedBox(
                          width: 91,
                          height: 112,
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return _imagePlaceholder();
                                  },
                                )
                              : _imagePlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(stageIcon(stage), size: 13, color: color),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    stageLabel(stage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            receipt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${products.length} ${products.length == 1 ? 'item' : 'items'} booked',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: _gold,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'View details',
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                if (codes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ...codes.take(3).map(
                            (code) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F6F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _line),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      if (codes.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _softGold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${codes.length - 3} more',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 19),
                _BookingTimeline(stage: stage),
                const SizedBox(height: 16),
                Container(height: 1, color: _line),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: _muted,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        pickup != null && returnDate != null
                            ? '${formatDate(pickup)} – ${formatDate(returnDate)}'
                            : 'Dates not available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amount,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
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

  Widget _imagePlaceholder() {
    return Container(
      color: _softGold,
      child: const Center(
        child: Icon(Icons.checkroom_rounded, color: _gold, size: 30),
      ),
    );
  }
}

class _BookingTimeline extends StatelessWidget {
  const _BookingTimeline({required this.stage});

  final String stage;

  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _ink = Color(0xFF29221F);

  @override
  Widget build(BuildContext context) {
    const stages = [
      'Booked',
      'Pickup',
      'Picked up',
      'Return',
      'Returned',
      'Done',
    ];

    int currentIndex;
    switch (stage) {
      case 'pickupPending':
        currentIndex = 1;
        break;
      case 'pickup':
        currentIndex = 2;
        break;
      case 'returnPending':
        currentIndex = 3;
        break;
      case 'return':
        currentIndex = 4;
        break;
      case 'successful':
        currentIndex = 5;
        break;
      case 'cancelled':
      case 'postponed':
        currentIndex = 0;
        break;
      default:
        currentIndex = 0;
    }

    final isStopped = stage == 'cancelled' || stage == 'postponed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOOKING PROGRESS',
          style: TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(stages.length, (index) {
              final completed = index <= currentIndex;
              final active = index == currentIndex && !isStopped;
              final progressColor = isStopped
                  ? const Color(0xFFB85B55)
                  : _gold;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutBack,
                          width: active ? 27 : 23,
                          height: active ? 27 : 23,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed ? progressColor : Colors.white,
                            border: Border.all(
                              color: completed ? progressColor : _line,
                              width: active ? 2 : 1.4,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: progressColor.withOpacity(0.23),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : const [],
                          ),
                          child: completed
                              ? Icon(
                                  index == currentIndex && !isStopped
                                      ? Icons.circle
                                      : Icons.check_rounded,
                                  size: index == currentIndex && !isStopped
                                      ? 7
                                      : 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          stages[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: completed ? _ink : _muted,
                            fontSize: 9,
                            fontWeight:
                                completed ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != stages.length - 1)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 23,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 19),
                      decoration: BoxDecoration(
                        color: index < currentIndex ? progressColor : _line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        if (isStopped) ...[
          const SizedBox(height: 7),
          Text(
            stage == 'cancelled' ? 'This booking was cancelled.' : 'This booking was postponed.',
            style: TextStyle(
              color: isStopped ? const Color(0xFFB85B55) : _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
