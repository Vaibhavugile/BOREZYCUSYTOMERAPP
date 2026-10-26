import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import 'partner_payment_details_screen.dart';

/// Partner-facing booking history for connected products.
///
/// Reads connected-product booking subcollections only to discover receipt
/// numbers. All booking/customer/payment details then come from the single
/// matching branch payment document for each unique receipt number.
class PartnerPaymentsScreen extends StatefulWidget {
  const PartnerPaymentsScreen({super.key});

  @override
  State<PartnerPaymentsScreen> createState() => _PartnerPaymentsScreenState();
}

class _PartnerPaymentsScreenState extends State<PartnerPaymentsScreen> {
  static const Color _background = Color(0xFFFCF9F5);
  static const Color _ink = Color(0xFF29221E);
  static const Color _gold = Color(0xFFC5A46D);
  static const Color _muted = Color(0xFF81766D);
  static const Color _line = Color(0xFFECE2D5);
  static const Color _softGold = Color(0xFFF5EBDD);

  bool _loading = true;
  String? _error;
  String _selectedTab = 'All';
  String _shareFilter = 'All shares';
  String _search = '';
  List<_PartnerBooking> _bookings = [];
  int _activeRevenueProductCount = 0;
  String _partnerPhone = '';

  bool _isActiveRevenueShareProduct(Map<String, dynamic> product) {
    String normalise(dynamic value) => (value ?? '')
        .toString().trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final model = normalise(product['partnershipType'] ?? product['preferredModel'] ??
        product['partnershipModel'] ?? product['partnerModel'] ?? product['preferredPartnershipModel']);
    final hasCreditNote = product['lastCreditNoteId'] != null ||
        product['creditNoteCustomerId'] != null || product['lastCreditNoteAmount'] != null ||
        product['creditNoteCustomerMobile'] != null;
    if (model == 'credit_note') return false;
    if (model.isNotEmpty && model != 'revenue_share') return false;
    // An explicit revenue_share selection takes precedence over old credit-note
    // history fields left on the product by a previous partnership model.
    if (model.isEmpty && hasCreditNote) return false;
    final activeFlag = product['isPartnershipActive'] ?? product['partnershipActive'] ?? product['isActivePartner'];
    if (activeFlag == false) return false;
    final status = normalise(product['partnershipStatus'] ?? product['partnershipState'] ?? product['partnerStatus']);
    if ({'inactive', 'paused', 'suspended', 'ended', 'terminated', 'rejected', 'declined', 'disabled', 'removed'}.contains(status)) return false;
    // Legacy records without a model are included unless marked as credit-note.
    return true;
  }

  String get _branch => TenantConfig.branchCode.trim();
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (_branch.isEmpty) throw Exception('Branch configuration is missing.');
      final phone = (await UserHelper.getPhone())?.trim();
      if (phone == null || phone.isEmpty) {
        throw Exception('Please sign in with your registered mobile number.');
      }
      _partnerPhone = phone;

      _directCustomerData = null;
      final customerDocs = await _findCustomerDocs(phone);
      final customerDataMaps = <Map<String, dynamic>>[
        ...customerDocs.map((doc) => doc.data()),
        if (_directCustomerData != null) _directCustomerData!,
      ];
      final productIds = <String>{};
      final productCodes = <String>{};
      final productNames = <String, String>{};
      final productById = <String, Map<String, dynamic>>{};

      for (final data in customerDataMaps) {
        final ids = data['partnerProductIds'];
        if (ids is List) {
          productIds.addAll(ids.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
        }
        final links = data['partnerProducts'];
        if (links is List) {
          for (final item in links) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            final id = (map['productId'] ?? '').toString().trim();
            final code = (map['productCode'] ?? map['partnerProductCode'] ?? map['code'] ?? '').toString().trim();
            if (id.isNotEmpty) productIds.add(id);
            if (code.isNotEmpty) productCodes.add(code);
            if (id.isNotEmpty && (map['productName'] ?? '').toString().trim().isNotEmpty) {
              productNames[id] = map['productName'].toString();
            }
          }
        }
      }

      // Include products whose product-side partnership fields point at this partner.
      // These are targeted equality queries; no full products collection scan.
      final branchProducts = _db.collection('products').doc(_branch).collection('products');
      for (final field in ['partnerMobile', 'partnerPhone']) {
        try {
          final snap = await branchProducts.where(field, isEqualTo: phone).limit(200).get();
          for (final doc in snap.docs) productIds.add(doc.id);
        } catch (_) {
          // A missing optional/legacy field should not block other discovery paths.
        }
      }

      await Future.wait(productIds.map((id) async {
        try {
          final doc = await branchProducts.doc(id).get();
          if (doc.exists) {
            final data = doc.data() ?? <String, dynamic>{};
            productById[id] = data;
            for (final rawCode in [data['partnerProductCode'], data['productCode'], data['productCodeValue'], data['code']]) {
              final code = (rawCode ?? '').toString().trim();
              if (code.isNotEmpty) productCodes.add(code);
            }
            final name = (data['productName'] ?? data['name'] ?? data['dressName'] ?? productNames[id] ?? 'Connected dress').toString();
            productNames[id] = name;
          }
        } catch (_) {}
      }));
      // Revenue reporting only includes active revenue-share products.
      final activeRevenueIds = productById.entries
          .where((entry) => _isActiveRevenueShareProduct(entry.value))
          .map((entry) => entry.key).toSet();
      productIds.retainAll(activeRevenueIds);
      productCodes.clear();
      productNames.removeWhere((key, _) => !activeRevenueIds.contains(key));
      for (final id in productIds) {
        final product = productById[id] ?? <String, dynamic>{};
        for (final rawCode in [product['partnerProductCode'], product['productCode'], product['productCodeValue'], product['code']]) {
          final code = (rawCode ?? '').toString().trim();
          if (code.isNotEmpty) productCodes.add(code);
        }
      }
      _activeRevenueProductCount = productIds.length;

      final found = <String, _PartnerBooking>{};
      final payments = _db.collection('products').doc(_branch).collection('payments');

      // Step 1: read the booking subcollections under connected products only
      // to discover receipt numbers and which connected products match them.
      // Do not use these subcollection documents as the booking detail source.
      final receiptReferences = <String, Map<String, dynamic>>{};
      for (final productId in productIds) {
        final product = productById[productId] ?? <String, dynamic>{};
        final productCode = (product['partnerProductCode'] ?? product['productCode'] ?? product['code'] ?? '').toString().trim();
        final productName = productNames[productId] ?? 'Connected dress';

        try {
          QuerySnapshot<Map<String, dynamic>> snap;
          try {
            snap = await branchProducts.doc(productId).collection('bookings')
                .orderBy('createdAt', descending: true).limit(500).get();
          } catch (_) {
            snap = await branchProducts.doc(productId).collection('bookings').limit(500).get();
          }

          for (final bookingDoc in snap.docs) {
            final bookingData = bookingDoc.data();
            final receipt = (bookingData['receiptNumber'] ?? '').toString().trim();
            // Your confirmed booking schema stores receiptNumber in each
            // product's bookings subcollection. Ignore records without it.
            if (receipt.isEmpty) continue;

            final refs = receiptReferences.putIfAbsent(receipt, () => <String, dynamic>{});
            final linked = (refs['partnerMatchedProducts'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                <Map<String, dynamic>>[];
            if (!linked.any((item) => item['productId'] == productId)) {
              linked.add({
                'productId': productId,
                'productCode': productCode.isNotEmpty ? productCode : (bookingData['productCode'] ?? '').toString(),
                'productName': (bookingData['productName'] ?? productName).toString(),
                'quantity': bookingData['quantity'] ?? 1,
                'price': bookingData['price'] ?? 0,
                'imageUrl': product['imageUrl'] ?? product['imageURL'] ?? bookingData['imageUrl'] ?? '',
              });
            }
            refs['partnerMatchedProducts'] = linked;
          }
        } catch (_) {
          // Continue if one connected product's bookings cannot be read.
        }
      }

      // Step 2: read each unique payment document by its exact receipt number.
      // This payment document is the source of truth for every displayed field.
      // No collection-wide payment query and no per-field candidate lookups.
      for (final entry in receiptReferences.entries) {
        final receipt = entry.key;
        final refs = entry.value;
        try {
          final paymentSnap = await payments.doc(receipt).get();
          if (!paymentSnap.exists) continue;

          final paymentData = Map<String, dynamic>.from(paymentSnap.data()!);
          paymentData['receiptNumber'] = receipt;
          paymentData['partnerMatchedProducts'] =
              refs['partnerMatchedProducts'] ?? <Map<String, dynamic>>[];

          final booking = _PartnerBooking.fromData(
            paymentData,
            paymentSnap.id,
            productIds,
            productCodes,
          );
          if (booking != null) {
            booking.data['partnerMobile'] = _partnerPhone;
            found[booking.key] = booking;
          }
        } catch (_) {
          // Skip this receipt if its payment document cannot be read.
        }
      }

      // Reconcile DOR payouts to each bill using the saved bill-wise allocations.
      // This powers both the booking-card badge and the paid/pending filters.
      try {
        final settlementSnap = await _db.collection('products').doc(_branch)
            .collection('partnerSettlements')
            .where('partnerMobile', isEqualTo: phone).get();
        for (final booking in found.values) {
          double allocatedPaid = 0;
          final receipt = booking.receipt;
          final productRows = booking.products;
          final ids = productRows.map((p) => (p['productId'] ?? p['id'] ?? p['productDocId'] ?? '').toString().trim()).where((v) => v.isNotEmpty).toSet();
          final codes = productRows.map((p) => (p['productCode'] ?? p['partnerProductCode'] ?? p['code'] ?? p['sku'] ?? '').toString().trim()).where((v) => v.isNotEmpty).toSet();
          for (final settlementDoc in settlementSnap.docs) {
            final settlement = settlementDoc.data();
            final status = (settlement['status'] ?? 'paid').toString().trim().toLowerCase();
            if (!['paid', 'completed', 'success', 'successful'].contains(status)) continue;
            final allocations = settlement['allocations'];
            if (allocations is! List) continue;
            for (final raw in allocations) {
              if (raw is! Map) continue;
              final allocation = Map<String, dynamic>.from(raw);
              final allocationReceipt = (allocation['receiptNumber'] ?? allocation['receiptNo'] ?? allocation['billNumber'] ?? '').toString().trim();
              if (allocationReceipt != receipt) continue;
              final pid = (allocation['productId'] ?? allocation['productDocId'] ?? allocation['id'] ?? '').toString().trim();
              final code = (allocation['productCode'] ?? allocation['code'] ?? allocation['sku'] ?? '').toString().trim();
              final matchesProduct = (pid.isNotEmpty && ids.contains(pid)) || (code.isNotEmpty && codes.contains(code)) || ((pid.isEmpty && code.isEmpty) && ids.isEmpty && codes.isEmpty);
              if (!matchesProduct) continue;
              final amount = allocation['amount'];
              allocatedPaid += amount is num ? amount.toDouble() : (double.tryParse((amount ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0);
            }
          }
          final pending = (booking.partnerRevenue - allocatedPaid).clamp(0.0, double.infinity).toDouble();
          final shareStatus = booking.partnerRevenue <= 0.009
              ? 'unavailable'
              : pending <= 0.009
                  ? 'paid'
                  : allocatedPaid > 0.009
                      ? 'partial'
                      : 'pending';
          booking.data['partnerPayoutPaid'] = allocatedPaid;
          booking.data['partnerPayoutPending'] = pending;
          booking.data['partnerPayoutStatus'] = shareStatus;
        }
      } catch (_) {
        // Keep the booking list available if settlement history cannot be read.
        for (final booking in found.values) {
          booking.data.putIfAbsent('partnerPayoutPaid', () => 0.0);
          booking.data.putIfAbsent('partnerPayoutPending', () => booking.partnerRevenue);
          booking.data.putIfAbsent('partnerPayoutStatus', () => 'pending');
        }
      }

      final sorted = found.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _bookings = sorted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _findCustomerDocs(String phone) async {
    final users = _db.collection('customers').doc(_branch).collection('users');
    final results = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final direct = await users.doc(phone).get();
    if (direct.exists) {
      // Direct reads are also followed by field queries to support non-phone document IDs.
      // Convert via queries below; the direct document is included in a separate map later.
    }
    for (final field in ['mobileNumber', 'phone', 'mobile']) {
      try {
        final snap = await users.where(field, isEqualTo: phone).limit(20).get();
        for (final doc in snap.docs) results[doc.id] = doc;
      } catch (_) {}
    }
    if (direct.exists) {
      // A direct document lookup can be used to read partner links even if its phone field differs.
      final data = direct.data() ?? <String, dynamic>{};
      final links = data['partnerProducts'];
      final ids = data['partnerProductIds'];
      if ((links is List && links.isNotEmpty) || (ids is List && ids.isNotEmpty)) {
        // Snapshot type conversion isn't exposed from DocumentSnapshot; the query results are
        // sufficient in the usual schema. Direct doc's links are merged through a local copy.
        _directCustomerData = data;
      }
    }
    final docs = results.values.toList();
    if (_directCustomerData != null && docs.every((d) => d.id != phone)) {
      // If the direct document has links but wasn't returned by a phone-field query,
      // we still need its IDs. Store it via a small adapter in the caller is cumbersome;
      // the direct data is merged into a synthetic map below instead.
    }
    return docs;
  }

  Map<String, dynamic>? _directCustomerData;

  List<Map<String, dynamic>> _matchedProducts(
    Map<String, dynamic> booking,
    Set<String> productIds,
    Set<String> productCodes,
    Map<String, String> productNames,
  ) {
    final matches = <Map<String, dynamic>>[];
    final rawProducts = booking['products'];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is! Map) continue;
        final product = Map<String, dynamic>.from(item);
        final id = (product['productId'] ?? product['id'] ?? product['productDocId'] ?? '').toString().trim();
        final code = (product['productCode'] ?? product['code'] ?? '').toString().trim();
        if ((id.isNotEmpty && productIds.contains(id)) || (code.isNotEmpty && productCodes.contains(code))) {
          final enriched = Map<String, dynamic>.from(product);
          if (id.isNotEmpty) enriched['productId'] = id;
          if (code.isNotEmpty) enriched['productCode'] = code;
          if ((enriched['productName'] ?? '').toString().isEmpty && id.isNotEmpty) {
            enriched['productName'] = productNames[id] ?? 'Connected dress';
          }
          matches.add(enriched);
        }
      }
    }
    final topId = (booking['productId'] ?? '').toString().trim();
    final topCode = (booking['productCode'] ?? '').toString().trim();
    if ((topId.isNotEmpty && productIds.contains(topId)) || (topCode.isNotEmpty && productCodes.contains(topCode))) {
      matches.add({
        'productId': topId,
        'productCode': topCode,
        'productName': booking['productName'] ?? productNames[topId] ?? 'Connected dress',
        'imageUrl': booking['imageUrl'] ?? '',
      });
    }
    return matches;
  }

  String _normaliseStage(dynamic value) => (value ?? 'Booking').toString().trim().toLowerCase();

  bool _matchesTab(_PartnerBooking booking) {
    final stage = _normaliseStage(booking.stage);
    if (_selectedTab == 'Upcoming') return ['booking', 'pickupPending'.toLowerCase(), 'confirmed', 'pending'].contains(stage);
    if (_selectedTab == 'Current') return ['pickup', 'returnPending'.toLowerCase(), 'return', 'ongoing', 'in_progress'].contains(stage);
    if (_selectedTab == 'Past') return ['successful', 'completed', 'cancelled', 'postponed', 'returned'].contains(stage);
    return true;
  }

  Color _stageColor(String stage) {
    switch (_normaliseStage(stage)) {
      case 'successful':
      case 'completed':
      case 'returned':
        return const Color(0xFF35704B);
      case 'cancelled':
        return const Color(0xFFAD4545);
      case 'pickup':
      case 'returnpending':
      case 'return':
      case 'ongoing':
        return const Color(0xFF496C9B);
      default:
        return const Color(0xFF926A2F);
    }
  }

  DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _shortDate(DateTime value) => value.millisecondsSinceEpoch == 0
      ? 'Date not set'
      : '${value.day}/${value.month}/${value.year}';

  String _money(dynamic value) {
    if (value == null) return '₹0';
    if (value is num) return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
    final parsed = num.tryParse(value.toString());
    return '₹${parsed == null ? value : parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _bookings.where((booking) {
      if (!_matchesTab(booking)) return false;
      final payoutStatus = (booking.data['partnerPayoutStatus'] ?? 'pending').toString();
      if (_shareFilter == 'Paid' && payoutStatus != 'paid') return false;
      if (_shareFilter == 'Part-paid' && payoutStatus != 'partial') return false;
      if (_shareFilter == 'Pending' && payoutStatus != 'pending') return false;
      final q = _search.trim().toLowerCase();
      if (q.isEmpty) return true;
      return booking.receipt.toLowerCase().contains(q) ||
          booking.customerName.toLowerCase().contains(q) ||
          booking.productLabels.toLowerCase().contains(q) ||
          booking.stage.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('D O R', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 2),
            Text('BILLING & PAYMENTS', style: TextStyle(fontSize: 8, color: _muted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadBookings, tooltip: 'Refresh bookings', icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _state(icon: Icons.cloud_off_outlined, title: 'Could not load payments', message: _error!, action: 'Try again', onTap: _loadBookings)
              : RefreshIndicator(
                  color: _gold,
                  onRefresh: _loadBookings,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                    children: [
                      _hero(visible.length),
                      const SizedBox(height: 18),
                      _summaryRow(),
                      const SizedBox(height: 18),
                      _payoutHistorySection(),
                      const SizedBox(height: 18),
                      TextField(
                        onChanged: (value) => setState(() => _search = value),
                        decoration: InputDecoration(
                          hintText: 'Search receipt, customer or dress code',
                          prefixIcon: const Icon(Icons.search_rounded, color: _muted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _gold, width: 1.4)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _tabs(),
                      const SizedBox(height: 12),
                      _shareStatusFilters(),
                      const SizedBox(height: 17),
                      Row(children: [
                        const Expanded(child: Text('Bill-wise payment history', style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800))),
                        Text('${visible.length} found', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 12),
                      if (visible.isEmpty)
                        _emptyState()
                      else
                        ...visible.map((booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _bookingCard(booking),
                            )),
                      const SizedBox(height: 8),
                      Text(
                        'Revenue is calculated only for active revenue-share dresses: 30% owner share and 70% DOR share after allocated rental discount. Credit-note partnerships are excluded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted.withOpacity(.9), fontSize: 10, height: 1.5),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _hero(int visibleCount) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(colors: [Color(0xFF30251F), Color(0xFF70543E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: _ink.withOpacity(.12), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Stack(children: [
          Positioned(right: -4, top: -10, child: Icon(Icons.calendar_month_rounded, size: 92, color: Colors.white.withOpacity(.07))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: const Text('YOUR BILLING OVERVIEW', style: TextStyle(color: Color(0xFFE8CEA1), fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800))),
            const SizedBox(height: 17),
            const Text('Every bill,\nclearly accounted.', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Only active revenue-share dresses are included. Credit-note partnerships are excluded from this revenue view.', style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 12, height: 1.55)),
            const SizedBox(height: 18),
            Row(children: [const Icon(Icons.checkroom_outlined, color: Color(0xFFE8CEA1), size: 18), const SizedBox(width: 8), Text('$_activeRevenueProductCount active revenue dresses', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)), const Spacer(), Text('$visibleCount bookings', style: const TextStyle(color: Color(0xFFE8CEA1), fontWeight: FontWeight.w800, fontSize: 12))]),
          ]),
        ]),
      );

  Widget _summaryRow() {
    final upcoming = _bookings.where((b) => _matchesByTab(b, 'Upcoming')).length;
    final current = _bookings.where((b) => _matchesByTab(b, 'Current')).length;
    final past = _bookings.where((b) => _matchesByTab(b, 'Past')).length;
    final totalPartnerShare = _bookings.fold<double>(0, (sum, booking) => sum + booking.partnerRevenue);
    return Column(children: [
      Row(children: [
        Expanded(child: _miniMetric('Upcoming', '$upcoming', Icons.event_available_outlined, const Color(0xFF926A2F), const Color(0xFFFAF0DB))),
        const SizedBox(width: 9),
        Expanded(child: _miniMetric('Current', '$current', Icons.local_laundry_service_outlined, const Color(0xFF496C9B), const Color(0xFFEAF0FA))),
        const SizedBox(width: 9),
        Expanded(child: _miniMetric('Past', '$past', Icons.history_rounded, const Color(0xFF35704B), const Color(0xFFE8F3EA))),
      ]),
      const SizedBox(height: 10),
      _miniMetric('YOUR TOTAL SHARE · 30%', _money(totalPartnerShare), Icons.account_balance_wallet_outlined, const Color(0xFF237653), const Color(0xFFE6F4EC), fullWidth: true),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _miniMetric('PAID TO YOU', _money(_bookings.fold<double>(0, (sum, b) => sum + _readMoney(b.data['partnerPayoutPaid']))), Icons.verified_rounded, const Color(0xFF237653), const Color(0xFFE6F4EC))),
        const SizedBox(width: 9),
        Expanded(child: _miniMetric('SHARE STILL PENDING', _money(_bookings.fold<double>(0, (sum, b) => sum + _readMoney(b.data['partnerPayoutPending']))), Icons.hourglass_bottom_rounded, const Color(0xFF9A6A19), const Color(0xFFFFF3D9))),
      ]),
    ]);
  }

  double _readMoney(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0;
  }

  Widget _shareStatusFilters() {
    const options = ['All shares', 'Paid', 'Part-paid', 'Pending'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FILTER BY YOUR SHARE STATUS', style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((option) {
        final selected = _shareFilter == option;
        final color = option == 'Paid' ? const Color(0xFF237653) : option == 'Pending' ? const Color(0xFFAD4545) : option == 'Part-paid' ? const Color(0xFF9A6A19) : _ink;
        return ChoiceChip(
          label: Text(option, style: TextStyle(color: selected ? Colors.white : color, fontSize: 11, fontWeight: FontWeight.w800)),
          selected: selected,
          onSelected: (_) => setState(() => _shareFilter = option),
          selectedColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? color : _line),
          showCheckmark: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        );
      }).toList()),
    ]);
  }

  bool _matchesByTab(_PartnerBooking booking, String tab) {
    final stage = _normaliseStage(booking.stage);
    if (tab == 'Upcoming') return ['booking', 'pickuppending', 'confirmed', 'pending'].contains(stage);
    if (tab == 'Current') return ['pickup', 'returnpending', 'return', 'ongoing', 'in_progress'].contains(stage);
    if (tab == 'Past') return ['successful', 'completed', 'cancelled', 'postponed', 'returned'].contains(stage);
    return true;
  }

  Widget _miniMetric(String title, String value, IconData icon, Color color, Color tint, {bool fullWidth = false}) => Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 31, height: 31, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)), const SizedBox(height: 9), Text(value, style: const TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(title, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700))]),
      );

  Widget _tabs() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _softGold,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: ['All', 'Upcoming', 'Current', 'Past'].map((tab) {
            final selected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _ink.withOpacity(.05),
                              blurRadius: 7,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    tab,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _ink : _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _bookingCard(_PartnerBooking booking) {
    final color = _stageColor(booking.stage);
    final first = booking.products.isEmpty ? <String, dynamic>{} : booking.products.first;
    final image = (first['imageUrl'] ?? first['image'] ?? '').toString();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerPaymentDetailsScreen(booking: booking.data))),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: _line), boxShadow: [BoxShadow(color: _ink.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(13), child: Container(width: 72, height: 86, color: _softGold, child: image.isNotEmpty ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.checkroom_outlined, color: _gold, size: 28)) : const Icon(Icons.checkroom_outlined, color: _gold, size: 28))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, runSpacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(30)), child: Text(booking.stage.isEmpty ? 'Payment' : booking.stage, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800))), if (booking.matchedProductCount > 1) Text('${booking.matchedProductCount} of your dresses', style: const TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Text(booking.receipt.isEmpty ? 'Bill ${booking.id}' : booking.receipt, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(booking.customerName.isEmpty ? 'Customer bill' : booking.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                const SizedBox(height: 6),
                Text(booking.productLabels, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                _paymentBadge(booking.data),
              ])),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _line),
            const SizedBox(height: 11),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Icon(Icons.calendar_today_outlined, color: _muted, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text('${_shortDate(booking.pickup)}  →  ${_shortDate(booking.returnDate)}', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFE6F4EC), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFB8DEC8))), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('YOUR SHARE · 30%', style: TextStyle(color: Color(0xFF237653), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .35)),
                const SizedBox(height: 3),
                Text(_money(booking.partnerRevenue), style: const TextStyle(color: Color(0xFF175B3B), fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const Text('Before payout allocation', style: TextStyle(color: Color(0xFF47745B), fontSize: 9, fontWeight: FontWeight.w700)),
              ])),
            ]),
            const SizedBox(height: 10),
            _sharePayoutBadge(booking),
            if (booking.codes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: booking.codes.take(4).map((code) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: _softGold.withOpacity(.7), borderRadius: BorderRadius.circular(8)), child: Text(code, style: const TextStyle(color: Color(0xFF80633D), fontSize: 9, fontWeight: FontWeight.w800)))).toList()),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _sharePayoutBadge(_PartnerBooking booking) {
    final status = (booking.data['partnerPayoutStatus'] ?? 'pending').toString();
    final paid = _readMoney(booking.data['partnerPayoutPaid']);
    final pending = _readMoney(booking.data['partnerPayoutPending'] ?? booking.partnerRevenue);
    final fullyPaid = status == 'paid';
    final partial = status == 'partial';
    final color = fullyPaid ? const Color(0xFF237653) : partial ? const Color(0xFF9A6A19) : const Color(0xFFAD4545);
    final tint = fullyPaid ? const Color(0xFFE6F4EC) : partial ? const Color(0xFFFFF3D9) : const Color(0xFFFCEAEA);
    final label = fullyPaid ? 'YOUR SHARE PAID' : partial ? 'YOUR SHARE PARTIALLY PAID' : status == 'unavailable' ? 'SHARE NOT CALCULATED' : 'YOUR SHARE PENDING';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(.22))),
      child: Row(children: [
        Icon(fullyPaid ? Icons.check_circle_rounded : partial ? Icons.timelapse_rounded : Icons.hourglass_bottom_rounded, color: color, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .35)),
          const SizedBox(height: 3),
          Text('Paid to you: ${_money(paid)}  ·  Still due: ${_money(pending)}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }

  Widget _paymentBadge(Map<String, dynamic> data) {
    final user = data['userDetails'] is Map ? Map<String, dynamic>.from(data['userDetails'] as Map) : <String, dynamic>{};
    double readNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse((value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0;
    }
    final paid = readNum(data['amountPaid'] ?? data['amountpaid'] ?? user['amountPaid'] ?? user['amountpaid']);
    final balance = readNum(data['balance'] ?? user['balance']);
    final rawStatus = (data['paymentStatus'] ?? data['paymentstatus'] ?? data['paymentState'] ?? '').toString().toLowerCase();
    final bool fullyPaid = ['paid', 'completed', 'success', 'successful', 'settled'].contains(rawStatus) || (balance <= 0 && paid > 0);
    final bool partial = !fullyPaid && (paid > 0 || rawStatus.contains('partial'));
    final label = fullyPaid ? 'CUSTOMER PAID' : partial ? 'CUSTOMER PART-PAID' : 'CUSTOMER PAYMENT DUE';
    final color = fullyPaid ? const Color(0xFF237653) : partial ? const Color(0xFF9A6A19) : const Color(0xFFAD4545);
    final tint = fullyPaid ? const Color(0xFFE6F4EC) : partial ? const Color(0xFFFFF3D9) : const Color(0xFFFCEAEA);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .25)));
  }

  Widget _payoutHistorySection() {
    final mobile = _partnerPhone.trim();
    if (mobile.isEmpty || _branch.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('products').doc(_branch)
          .collection('partnerSettlements')
          .where('partnerMobile', isEqualTo: mobile)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _infoPanel('Payout history', 'Payout history could not be loaded. Check access to partnerSettlements.', Icons.info_outline_rounded);
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) => _asDate(b.data()['recordedAt'] ?? b.data()['createdAt'])
              .compareTo(_asDate(a.data()['recordedAt'] ?? a.data()['createdAt'])));
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: _softGold, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_wallet_outlined, color: _gold)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PAYOUT HISTORY', style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
                SizedBox(height: 3), Text('Payments from DOR', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w900)),
              ])),
              Text('${docs.length}', style: const TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              const Text('No payout records have been recorded for your mobile number yet.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5))
            else
              ...docs.map((doc) {
                final d = doc.data();
                final proof = (d['screenshotUrl'] ?? d['proofUrl'] ?? d['paymentScreenshot'] ?? '').toString().trim();
                final amount = _money(d['amount'] ?? 0);
                final status = (d['status'] ?? 'recorded').toString();
                final method = (d['method'] ?? d['paymentMethod'] ?? '—').toString().replaceAll('_', ' ');
                final ref = (d['reference'] ?? d['transactionReference'] ?? '').toString();
                final when = _asDate(d['recordedAt'] ?? d['createdAt']);
                return Container(
                  margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF35704B), size: 20), const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(amount, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3), Text('${_shortDate(when)} · ${method.isEmpty ? '—' : method}', style: const TextStyle(color: _muted, fontSize: 10)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE8F3EA), borderRadius: BorderRadius.circular(20)), child: Text(status, style: const TextStyle(color: Color(0xFF35704B), fontSize: 9, fontWeight: FontWeight.w800))),
                    ]),
                    if (ref.isNotEmpty) ...[const SizedBox(height: 7), Text('Reference: $ref', style: const TextStyle(color: _muted, fontSize: 10))],
                    if ((d['notes'] ?? '').toString().trim().isNotEmpty) ...[const SizedBox(height: 5), Text(d['notes'].toString(), style: const TextStyle(color: _muted, fontSize: 10, height: 1.4))],
                    if (d['allocations'] is List && (d['allocations'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('BILL-WISE ALLOCATION', style: TextStyle(color: _muted, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      ...((d['allocations'] as List).whereType<Map>().map((raw) {
                        final allocation = Map<String, dynamic>.from(raw);
                        final bill = (allocation['receiptNumber'] ?? allocation['receiptNo'] ?? allocation['bookingId'] ?? 'Bill').toString();
                        final allocated = _money(allocation['amount'] ?? 0);
                        return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.receipt_long_outlined, color: _gold, size: 16), const SizedBox(width: 7), Expanded(child: Text(bill, style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w700))), Text(allocated, style: const TextStyle(color: Color(0xFF237653), fontSize: 12, fontWeight: FontWeight.w900))]));
                      })),
                    ],
                    if (proof.isNotEmpty) ...[const SizedBox(height: 10), InkWell(onTap: () => _showProofImage(context, proof, 'Payout proof'), borderRadius: BorderRadius.circular(12), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(proof, width: 78, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 78, height: 72, color: _softGold, child: const Icon(Icons.broken_image_outlined, color: _gold)))), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Payment screenshot / proof', style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Tap to view full image', style: TextStyle(color: _muted, fontSize: 10))])), const Icon(Icons.open_in_full_rounded, color: _gold, size: 18)]))],
                  ]),
                );
              }),
          ]),
        );
      },
    );
  }

  DateTime _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _infoPanel(String title, String message, IconData icon) => Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
    child: Row(children: [Icon(icon, color: _gold), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(message, style: const TextStyle(color: _muted, fontSize: 11))]))]),
  );

  void _showProofImage(BuildContext context, String url, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 280,
                    child: Center(
                      child: Text(
                        'Unable to load screenshot',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)), child: Column(children: [Container(width: 66, height: 66, decoration: const BoxDecoration(color: _softGold, shape: BoxShape.circle), child: const Icon(Icons.event_note_rounded, color: _gold, size: 30)), const SizedBox(height: 15), const Text('No payment records yet', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 7), const Text('Bills containing your active revenue-share dresses will appear here.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12, height: 1.6)), const SizedBox(height: 14), OutlinedButton.icon(onPressed: _loadBookings, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh'))]));

  Widget _state({required IconData icon, required String title, required String message, required String action, required VoidCallback onTap}) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 74, height: 74, decoration: const BoxDecoration(color: _softGold, shape: BoxShape.circle), child: Icon(icon, color: _gold, size: 32)), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12, height: 1.6)), const SizedBox(height: 18), ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white), child: Text(action))])));
}

class _PartnerBooking {
  final String key;
  final String id;
  final String receipt;
  final String stage;
  final String customerName;
  final DateTime pickup;
  final DateTime returnDate;
  final DateTime createdAt;
  final dynamic amount;
  final double partnerRevenue;
  final double dorRevenue;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic> data;

  _PartnerBooking({required this.key, required this.id, required this.receipt, required this.stage, required this.customerName, required this.pickup, required this.returnDate, required this.createdAt, required this.amount, required this.partnerRevenue, required this.dorRevenue, required this.products, required this.data});

  List<String> get codes => products.map((p) => (p['productCode'] ?? p['code'] ?? '').toString().trim()).where((v) => v.isNotEmpty).toSet().toList();
  String get productLabels => products.map((p) => (p['productName'] ?? p['name'] ?? 'Connected dress').toString()).toSet().join(', ');
  int get matchedProductCount => products.length;

  static _PartnerBooking? fromData(Map<String, dynamic> source, String id, Set<String> connectedIds, Set<String> connectedCodes) {
    final data = Map<String, dynamic>.from(source);
    final rawProducts = data['partnerMatchedProducts'] ?? data['products'];
    final products = <Map<String, dynamic>>[];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is! Map) continue;
        final p = Map<String, dynamic>.from(item);
        final pid = (p['productId'] ?? p['id'] ?? p['productDocId'] ?? '').toString().trim();
        final code = (p['productCode'] ?? p['code'] ?? '').toString().trim();
        if ((pid.isNotEmpty && connectedIds.contains(pid)) || (code.isNotEmpty && connectedCodes.contains(code)) || data['partnerMatchedProducts'] != null) {
          products.add(p);
        }
      }
    }
    final topId = (data['productId'] ?? '').toString().trim();
    final topCode = (data['productCode'] ?? '').toString().trim();
    if (products.isEmpty && ((topId.isNotEmpty && connectedIds.contains(topId)) || (topCode.isNotEmpty && connectedCodes.contains(topCode)))) {
      products.add({'productId': topId, 'productCode': topCode, 'productName': data['productName'] ?? 'Connected dress', 'imageUrl': data['imageUrl'] ?? ''});
    }
    if (products.isEmpty) return null;

    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final userDetails = data['userDetails'] is Map
        ? Map<String, dynamic>.from(data['userDetails'] as Map)
        : <String, dynamic>{};

    final receipt = (data['receiptNumber'] ?? data['receiptNo'] ??
            data['paymentReceiptNumber'] ?? data['bookingNumber'] ?? data['bookingId'] ?? id)
        .toString();
    // In this app, the booking subcollection stores the current stage inside
    // userDetails.stage; the payment receipt can store it as bookingStage/stage.
    final stage = (userDetails['stage'] ?? data['bookingStage'] ??
            data['stage'] ?? data['status'] ?? 'Booking')
        .toString();
    final pickup = date(data['pickupDate'] ?? data['startDate']);
    final returned = date(data['returnDate'] ?? data['endDate']);
    final created = date(data['createdAt']);
    final customerName = (userDetails['name'] ?? data['clientName'] ??
            data['clientname'] ?? data['customerName'] ?? data['name'] ?? '')
        .toString();
    final amount = data['finalRent'] ?? data['finalrent'] ??
        data['grandTotalRent'] ?? userDetails['finalrent'] ??
        userDetails['grandTotalRent'] ?? data['totalAmount'] ??
        data['totalamounttobepaid'] ?? userDetails['totalamounttobepaid'] ??
        data['amount'] ?? 0;

    // Partner revenue is calculated only from the partner's matched revenue
    // products, not from the full multi-product receipt total.
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse((value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0;
    }

    final allSummaryRaw = data['productsSummary'] ?? data['products'] ?? data['items'];
    final allSummary = <Map<String, dynamic>>[];
    if (allSummaryRaw is List) {
      for (final item in allSummaryRaw) {
        if (item is Map) allSummary.add(Map<String, dynamic>.from(item));
      }
    }

    final totalDiscount = number(
      data['discountOnRent'] ?? data['discountonrent'] ??
      userDetails['discountOnRent'] ?? userDetails['discountonrent'] ?? 0,
    );

    // Match PartnerBookingsScreen: divide the bill-level rental discount
    // equally across all product lines, then allocate the matched partner
    // products' equal shares to this partner.
    final totalProductLines = allSummary.isNotEmpty ? allSummary.length : products.length;
    final discountPerProduct =
        totalProductLines > 0 ? totalDiscount / totalProductLines : 0.0;

    double matchedGrossRent = 0;
    var matchedSummaryCount = 0;
    for (final partnerProduct in products) {
      final partnerId = (partnerProduct['productId'] ?? partnerProduct['id'] ?? '').toString().trim();
      final partnerCode = (partnerProduct['productCode'] ?? partnerProduct['code'] ?? '').toString().trim();
      Map<String, dynamic>? summary;
      for (final candidate in allSummary) {
        final candidateId = (candidate['productId'] ?? candidate['id'] ?? candidate['productDocId'] ?? '').toString().trim();
        final candidateCode = (candidate['productCode'] ?? candidate['code'] ?? '').toString().trim();
        if ((partnerId.isNotEmpty && candidateId == partnerId) ||
            (partnerCode.isNotEmpty && candidateCode == partnerCode)) {
          summary = candidate;
          break;
        }
      }

      if (summary != null) {
        final rent = number(summary['rent'] ?? summary['price'] ?? summary['finalRent'] ?? summary['finalrent']);
        final quantity = number(summary['quantity'] ?? 1);
        // Legacy productsSummary stores per-unit rent and quantity.
        matchedGrossRent += rent * (quantity > 0 ? quantity : 1);
        matchedSummaryCount++;
      } else {
        final rent = number(partnerProduct['rent'] ?? partnerProduct['price'] ?? partnerProduct['finalRent'] ?? partnerProduct['finalrent']);
        final quantity = number(partnerProduct['quantity'] ?? 1);
        matchedGrossRent += rent * (quantity > 0 ? quantity : 1);
      }
    }

    // If the receipt has product lines, allocate one equal discount share for
    // every matched line. If no bill summary exists, use the matched products
    // as the fallback line count, matching PartnerBookingsScreen behavior.
    final allocatedDiscount = (allSummary.isNotEmpty && matchedSummaryCount > 0)
        ? discountPerProduct * matchedSummaryCount
        : (allSummary.isEmpty ? discountPerProduct * products.length : 0.0);
    final netMatchedRent = (matchedGrossRent - allocatedDiscount).clamp(0.0, double.infinity).toDouble();
    // Current partnership split: product owner/partner receives 30%; DOR keeps 70%.
    final partnerRevenue = netMatchedRent * 0.30;
    final dorRevenue = netMatchedRent * 0.70;

    // Normalize fields for the existing BookingDetailsScreen and partner UI.
    data['receiptNumber'] = receipt;
    data['bookingStage'] = stage;
    data['stage'] = stage;
    data['products'] = products;
    data['clientName'] = customerName;
    data['contact'] = userDetails['contact'] ?? data['contact'] ?? '';
    data['grandTotalRent'] = data['grandTotalRent'] ?? userDetails['grandTotalRent'] ?? 0;
    data['discountOnRent'] = data['discountOnRent'] ?? userDetails['discountOnRent'] ?? 0;
    data['finalRent'] = data['finalRent'] ?? userDetails['finalrent'] ?? 0;
    data['grandTotalDeposit'] = data['grandTotalDeposit'] ?? userDetails['grandTotalDeposit'] ?? 0;
    data['finalDeposit'] = data['finalDeposit'] ?? userDetails['finaldeposite'] ?? 0;
    data['amountPaid'] = data['amountPaid'] ?? userDetails['amountpaid'] ?? 0;
    data['balance'] = data['balance'] ?? userDetails['balance'] ?? 0;
    data['specialNote'] = data['specialNote'] ?? userDetails['specialnote'] ?? '';
    data['customerBy'] = data['customerBy'] ?? userDetails['customerby'] ?? '';
    data['receiptBy'] = data['receiptBy'] ?? userDetails['receiptby'] ?? '';
    data.putIfAbsent('totalAmount', () => amount);
    data.putIfAbsent('pickupDate', () => Timestamp.fromDate(pickup));
    data.putIfAbsent('returnDate', () => Timestamp.fromDate(returned));

    data['partnerRevenue'] = partnerRevenue;
    data['dorRevenue'] = dorRevenue;
    data['dorRevenueSharePercent'] = 70;
    data['partnerMatchedGrossRent'] = matchedGrossRent;
    data['partnerMatchedNetRent'] = netMatchedRent;
    data['partnerAllocatedDiscount'] = allocatedDiscount;
    return _PartnerBooking(key: receipt.isNotEmpty ? receipt : id, id: id, receipt: receipt, stage: stage, customerName: customerName, pickup: pickup, returnDate: returned, createdAt: created, amount: amount, partnerRevenue: partnerRevenue, dorRevenue: dorRevenue, products: products, data: data);
  }
}
