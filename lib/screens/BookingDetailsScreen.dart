import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tenant_config.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with TickerProviderStateMixin {
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);
  static const Color _green = Color(0xFF43856A);
  static const Color _red = Color(0xFFB85B55);

  late final AnimationController _introController;
  late Future<QuerySnapshot<Map<String, dynamic>>> _historyFuture;

  Map<String, dynamic> get booking => widget.booking;
  String get receipt => (booking['receiptNumber'] ?? 'Booking').toString();
  String get stage => (booking['bookingStage'] ?? 'Booking').toString();

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _historyFuture = _fetchPaymentHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchPaymentHistory() {
    return FirebaseFirestore.instance
        .collection('products')
        .doc(TenantConfig.branchCode)
        .collection('payments')
        .doc(receipt)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _fetchPaymentHistory();
    });
    try {
      await _historyFuture;
    } catch (_) {
      // The payment-history section displays its own error state.
    }
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _dateLabel(dynamic value, {bool year = false}) {
    final date = _date(value);
    if (date == null) return 'Not available';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return year
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : '${date.day} ${months[date.month - 1]}';
  }

  String _dateTimeLabel(dynamic value) {
    final date = _date(value);
    if (date == null) return 'Not available';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${_dateLabel(date, year: true)} · ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $suffix';
  }

  String _money(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '₹0';
    if (value is num) {
      return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
    }
    return '₹${value.toString()}';
  }

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    return value.toString();
  }

  List<Map<String, dynamic>> _products() {
    final raw = booking['products'];
    if (raw is! List) return [];
    return raw.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      return <String, dynamic>{};
    }).toList();
  }

  List<Map<String, dynamic>> _attachments() {
    final raw = booking['attachments'];
    if (raw is! List) return [];
    return raw.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      return <String, dynamic>{};
    }).toList();
  }

  Color _stageColor() {
    switch (stage) {
      case 'successful':
        return _green;
      case 'Booking':
      case 'pickupPending':
        return const Color(0xFFB87931);
      case 'pickup':
      case 'returnPending':
      case 'return':
        return const Color(0xFF5279A6);
      case 'cancelled':
        return _red;
      case 'postponed':
        return const Color(0xFF8C72A7);
      default:
        return _gold;
    }
  }

  String _stageLabel() {
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
        return stage;
    }
  }

  IconData _stageIcon() {
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
      default:
        return Icons.event_available_rounded;
    }
  }

  Future<void> _openSupport({required bool whatsapp}) async {
    final phone = TenantConfig.supportPhone.toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final uri = whatsapp
        ? Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent('Hello, I need help with booking $receipt.')}') 
        : Uri(scheme: 'tel', path: '+$phone');
    try {
      final launched = await launchUrl(
        uri,
        mode: whatsapp ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this app on your device.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this app on your device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _date(booking['pickupDate']);
    final returnDate = _date(booking['returnDate']);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _ink, size: 20),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOOKING OVERVIEW',
              style: TextStyle(
                color: _gold,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Booking Details',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton(
              tooltip: 'Refresh details',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: _ink),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomActions(),
      body: RefreshIndicator(
        color: _gold,
        backgroundColor: Colors.white,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _animated(0, _receiptHeader(pickup, returnDate)),
            const SizedBox(height: 16),
            _animated(1, _customerCard()),
            const SizedBox(height: 16),
            _animated(2, _productSection(_products())),
            const SizedBox(height: 16),
            _animated(3, _paymentDetails(booking)),
            const SizedBox(height: 16),
            _animated(4, _paymentHistory()),
            const SizedBox(height: 16),
            _animated(5, _accountSummary(booking)),
            if (_value(booking['specialNote']) != '—') ...[
              const SizedBox(height: 16),
              _animated(6, _noteSection()),
            ],
            const SizedBox(height: 16),
            _animated(7, _attachmentsSection()),
            const SizedBox(height: 16),
            _animated(8, _helpSection()),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    return AnimatedBuilder(
      animation: _introController,
      child: child,
      builder: (context, child) {
        final start = (index * 0.075).clamp(0.0, 0.65).toDouble();
        final t = ((_introController.value - start) / (1 - start))
            .clamp(0.0, 1.0)
            .toDouble();
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _receiptHeader(DateTime? pickup, DateTime? returnDate) {
    final color = _stageColor();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF342A24), Color(0xFF211B18), Color(0xFF49382B)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _gold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -30,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.12), width: 22),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFE0BD8D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'BOOKING RECEIPT',
                      style: TextStyle(
                        color: Color(0xFFE0BD8D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_stageIcon(), color: color, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          _stageLabel().toUpperCase(),
                          style: TextStyle(
                            color: color == const Color(0xFFB87931)
                                ? const Color(0xFFFFD59E)
                                : color == _green
                                    ? const Color(0xFF9FE0BB)
                                    : const Color(0xFFD6C4FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Receipt number',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                receipt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 22),
              Container(height: 1, color: Colors.white.withOpacity(0.13)),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: _heroDate(
                      icon: Icons.login_rounded,
                      label: 'PICKUP',
                      date: pickup,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _heroDate(
                      icon: Icons.logout_rounded,
                      label: 'RETURN',
                      date: returnDate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroDate({
    required IconData icon,
    required String label,
    required DateTime? date,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE0BD8D), size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                date == null ? 'Not set' : _dateLabel(date, year: true),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customerCard() {
    return _sectionCard(
      title: 'Customer details',
      subtitle: 'Your booking information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _infoRow('Customer name', booking['clientName'], icon: Icons.badge_outlined),
          _infoRow('Contact number', booking['contact'], icon: Icons.phone_iphone_rounded),
          _infoRow('Customer by', booking['customerBy'], icon: Icons.person_search_rounded),
          _infoRow('Receipt by', booking['receiptBy'], icon: Icons.receipt_outlined),
          if (_value(booking['alterations']) != '—')
            _infoRow('Alterations', booking['alterations'], icon: Icons.content_cut_rounded),
          if (booking['createdAt'] != null)
            _infoRow(
              'Created on',
              _dateTimeLabel(booking['createdAt']),
              icon: Icons.schedule_rounded,
              last: true,
            ),
        ],
      ),
    );
  }

  Widget _productSection(List<Map<String, dynamic>> products) {
    return _sectionCard(
      title: 'Booked products',
      subtitle: '${products.length} ${products.length == 1 ? 'item' : 'items'} in this booking',
      icon: Icons.checkroom_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _softGold,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${products.length} items',
          style: const TextStyle(
            color: _gold,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: products.isEmpty
          ? const _InlineEmpty(message: 'No product details available.')
          : Column(
              children: products.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final name = _value(product['productName']);
                final image = (product['imageUrl'] ?? '').toString();
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index == products.length - 1 ? 0 : 11,
                  ),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBF9),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: SizedBox(
                          width: 76,
                          height: 91,
                          child: image.isEmpty
                              ? _productPlaceholder()
                              : CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _productPlaceholder(),
                                  errorWidget: (_, __, ___) => _productPlaceholder(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code: ${_value(product['productCode'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${_value(product['quantity'])}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              _money(product['price']),
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      color: _softGold,
      child: const Center(
        child: Icon(Icons.checkroom_rounded, color: _gold, size: 29),
      ),
    );
  }

  Widget _paymentDetails(Map<String, dynamic> payment) {
    return _sectionCard(
      title: 'Payment details',
      subtitle: 'Rent and deposit breakdown',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _amountRow('Grand total rent', payment['grandTotalRent']),
          _amountRow('Discount on rent', payment['discountOnRent']),
          _amountRow('Final rent', payment['finalRent'], emphasis: true),
          const _GoldDivider(),
          _amountRow('Grand total deposit', payment['grandTotalDeposit']),
          _amountRow('Final deposit', payment['finalDeposit'], emphasis: true),
          const _GoldDivider(),
          _amountRow(
            'Amount paid',
            payment['amountPaid'],
            color: _green,
            icon: Icons.check_circle_outline_rounded,
          ),
          _amountRow(
            'Balance due',
            payment['balance'],
            color: _red,
            icon: Icons.pending_actions_rounded,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _paymentHistory() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionCard(
            title: 'Payment history',
            subtitle: 'Loading transactions',
            icon: Icons.history_rounded,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _gold,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _sectionCard(
            title: 'Payment history',
            subtitle: 'Transactions',
            icon: Icons.history_rounded,
            child: _InlineEmpty(
              message: 'Payment history could not be loaded. Pull down to retry.',
              icon: Icons.cloud_off_rounded,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        return _sectionCard(
          title: 'Payment history',
          subtitle: 'Recorded payment transactions',
          icon: Icons.history_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: _softGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${docs.length} records',
              style: const TextStyle(
                color: _gold,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: docs.isEmpty
              ? const _InlineEmpty(message: 'No payments recorded yet.')
              : Column(
                  children: docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value.data();
                    final isRefund = data['type'] == 'depositReturn';
                    final color = isRefund ? _red : _green;
                    final date = _date(data['createdAt']);
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: index == docs.length - 1 ? 0 : 10,
                      ),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFBF9),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isRefund
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRefund
                                      ? 'Deposit refunded'
                                      : 'Payment ${_value(data['paymentNumber'])}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    _value(data['mode']),
                                    if (date != null) _dateLabel(date, year: true),
                                  ].where((s) => s != '—').join(' · '),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isRefund ? '+' : ''}${_money(data['amount'])}',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _accountSummary(Map<String, dynamic> payment) {
    return _sectionCard(
      title: 'Account summary',
      subtitle: 'Current rent and deposit position',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _amountRow('Total rent', payment['finalRent']),
          _amountRow('Rent paid', payment['rentCollected'], color: _green),
          _amountRow('Rent pending', payment['rentPending'], color: _red),
          const _GoldDivider(),
          _amountRow('Total deposit', payment['finalDeposit']),
          _amountRow('Deposit returned', payment['depositReturned'], color: _green),
          _amountRow(
            'Deposit with us',
            payment['depositWithYou'],
            emphasis: true,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _noteSection() {
    return _sectionCard(
      title: 'Special note',
      subtitle: 'Additional booking information',
      icon: Icons.sticky_note_2_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softGold,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Text(
          _value(booking['specialNote']),
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ),
    );
  }

  Widget _attachmentsSection() {
    final attachments = _attachments();
    return _sectionCard(
      title: 'Attachments',
      subtitle: 'Documents and reference images',
      icon: Icons.attach_file_rounded,
      child: attachments.isEmpty
          ? const _InlineEmpty(
              message: 'No attachments have been added to this booking.',
              icon: Icons.folder_open_rounded,
            )
          : Column(
              children: attachments.map((item) {
                final title = _value(item['title']);
                final note = _value(item['note']);
                final rawImages = item['images'];
                final images = rawImages is List
                    ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
                    : <String>[];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBF9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _softGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: _gold,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (note != '—') ...[
                        const SizedBox(height: 10),
                        Text(
                          note,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 13),
                        SizedBox(
                          height: 112,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 9),
                            itemBuilder: (context, index) {
                              final url = images[index];
                              return GestureDetector(
                                onTap: () => _showImage(context, url),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    width: 92,
                                    height: 112,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _productPlaceholder(),
                                    errorWidget: (_, __, ___) => _productPlaceholder(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: _gold),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 250,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpSection() {
    return _sectionCard(
      title: 'Need assistance?',
      subtitle: 'We are here to help with this booking',
      icon: Icons.support_agent_rounded,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'WhatsApp',
              icon: Icons.chat_bubble_outline_rounded,
              primary: true,
              onTap: () => _openSupport(whatsapp: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Call support',
              icon: Icons.call_outlined,
              primary: false,
              onTap: () => _openSupport(whatsapp: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _line)),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.045),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Contact',
                icon: Icons.support_agent_rounded,
                primary: false,
                onTap: () => _openSupport(whatsapp: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Booking receipt',
                icon: Icons.receipt_long_rounded,
                primary: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt details are shown on this screen.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _gold, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    dynamic value, {
    IconData? icon,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: _muted, size: 15),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              _value(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    dynamic value, {
    Color? color,
    bool emphasis = false,
    IconData? icon,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 13),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? _muted, size: 15),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasis ? _ink : _muted,
                fontSize: 11,
                fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              color: color ?? _ink,
              fontSize: emphasis ? 13 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: const Color(0xFFECE5DC))),
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB68A52),
            ),
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFECE5DC))),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String message;
  final IconData icon;

  const _InlineEmpty({
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE5DC)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB68A52), size: 25),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E857D),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  static const Color _ink = Color(0xFF29221F);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: primary ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primary ? _ink : _line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: primary ? const Color(0xFFE0BD8D) : _gold),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary ? Colors.white : _ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
