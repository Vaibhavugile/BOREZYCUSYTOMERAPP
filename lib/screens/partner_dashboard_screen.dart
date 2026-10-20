import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import 'dress_history_screen.dart';
import 'rent_your_dress_screen.dart';
import 'partner_bookings_screen.dart';
import 'partner_payments_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() =>
      _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  static const Color _background = Color(0xFFFCF9F5);
  static const Color _ink = Color(0xFF29221E);
  static const Color _gold = Color(0xFFC5A46D);
  static const Color _muted = Color(0xFF81766D);
  static const Color _line = Color(0xFFECE2D5);
  static const Color _softGold = Color(0xFFF5EBDD);

  String? _branchCode;
  String? _phone;
  bool _loadingIdentity = true;
  String? _identityError;
  int _selectedTab = 0;
  Future<Map<String, dynamic>>? _partnerStatsFuture;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    try {
      final branch = TenantConfig.branchCode.trim();
      final phone = await UserHelper.getPhone();

      if (!mounted) return;

      if (branch.isEmpty) {
        setState(() {
          _identityError = 'Branch configuration is missing.';
          _loadingIdentity = false;
        });
        return;
      }

      if (phone == null || phone.trim().isEmpty) {
        setState(() {
          _identityError =
              'Please sign in with your registered mobile number to open Partner Studio.';
          _loadingIdentity = false;
        });
        return;
      }

      setState(() {
        _branchCode = branch;
        _phone = phone.trim();
        _loadingIdentity = false;
        _partnerStatsFuture = _loadPartnerStats();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _identityError = 'Unable to load your account. Please try again.';
        _loadingIdentity = false;
      });
    }
  }

  CollectionReference<Map<String, dynamic>>? get _requestsCollection {
    if (_branchCode == null) return null;
    return FirebaseFirestore.instance
        .collection('products')
        .doc(_branchCode)
        .collection('dressRentalRequests');
  }

  Query<Map<String, dynamic>>? get _myRequests {
    if (_requestsCollection == null || _phone == null) return null;
    return _requestsCollection!
        .where('ownerPhone', isEqualTo: _phone);
  }


  String _normalisePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  double _asAmount(dynamic value) {
    if (value is num) return value.toDouble();
    final cleaned = (value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  Future<Map<String, dynamic>> _loadPartnerStats() async {
    final branch = _branchCode;
    final rawPhone = (_phone ?? '').trim();
    if (branch == null || rawPhone.isEmpty) {
      return <String, dynamic>{
        'connectedCount': 0,
        'activeCount': 0,
        'revenueShareCount': 0,
        'creditCount': 0,
        'totalCredit': 0.0,
        'creditBalance': 0.0,
      };
    }

    final db = FirebaseFirestore.instance;
    final customersRef = db.collection('customers').doc(branch).collection('users');
    final productsRef = db.collection('products').doc(branch).collection('products');
    final normalPhone = _normalisePhone(rawPhone);
    final phoneVariants = <String>{rawPhone, normalPhone}
      ..removeWhere((value) => value.isEmpty);

    // Resolve only this partner's profile; do not scan the customer collection.
    final identityFutures = <Future<dynamic>>[
      customersRef.doc(rawPhone).get(),
      if (normalPhone != rawPhone) customersRef.doc(normalPhone).get(),
      for (final value in phoneVariants) ...[
        customersRef.where('mobileNumber', isEqualTo: value).limit(5).get(),
        customersRef.where('phone', isEqualTo: value).limit(5).get(),
        customersRef.where('mobile', isEqualTo: value).limit(5).get(),
      ],
    ];
    final identityResults = await Future.wait(identityFutures);
    final customerDocs = <String, Map<String, dynamic>>{};
    for (final result in identityResults) {
      if (result is DocumentSnapshot<Map<String, dynamic>> && result.exists) {
        customerDocs[result.id] = <String, dynamic>{
          ...?result.data(),
          '_customerDocId': result.id,
        };
      } else if (result is QuerySnapshot<Map<String, dynamic>>) {
        for (final doc in result.docs) {
          customerDocs[doc.id] = <String, dynamic>{
            ...doc.data(),
            '_customerDocId': doc.id,
          };
        }
      }
    }

    final ownCustomer = customerDocs.values.cast<Map<String, dynamic>?>().firstWhere(
      (customer) {
        if (customer == null) return false;
        final customerPhone = _normalisePhone(
          (customer['mobileNumber'] ?? customer['phone'] ?? customer['mobile'] ?? '').toString(),
        );
        return customerPhone == normalPhone ||
            customer['_customerDocId'] == rawPhone ||
            customer['_customerDocId'] == normalPhone;
      },
      orElse: () => customerDocs[rawPhone] ?? customerDocs[normalPhone],
    );

    final linkedProfiles = <String, Map<String, dynamic>>{};
    final linkedIds = <String>{};
    final rawLinks = ownCustomer?['partnerProducts'] ??
        ownCustomer?['connectedProducts'] ??
        ownCustomer?['connectedProductIds'] ??
        ownCustomer?['partnerProductIds'] ??
        ownCustomer?['productIds'];

    // Credit-note-only dresses may not be present in partnerProducts.
    // Include the latest dress explicitly linked on the customer profile.
    final latestCreditProductId =
        (ownCustomer?['lastCreditNoteProductId'] ?? '').toString().trim();
    if (latestCreditProductId.isNotEmpty) linkedIds.add(latestCreditProductId);

    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is String && item.trim().isNotEmpty) {
          linkedIds.add(item.trim());
        } else if (item is Map) {
          final link = Map<String, dynamic>.from(item);
          final id = (link['productId'] ?? link['id'] ??
                  link['relatedProductId'] ?? link['productDocId'] ?? '')
              .toString()
              .trim();
          if (id.isNotEmpty) {
            linkedIds.add(id);
            linkedProfiles[id] = link;
          }
        }
      }
    }

    // Also find products linked from the product side using indexed, customer-specific queries.
    final customerId = (ownCustomer?['_customerDocId'] ?? rawPhone).toString();
    final productQueryFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      // Partnership-linked products.
      productsRef.where('partnerMobile', isEqualTo: rawPhone).limit(100).get(),
      if (normalPhone != rawPhone)
        productsRef.where('partnerMobile', isEqualTo: normalPhone).limit(100).get(),
      productsRef.where('partnerId', isEqualTo: customerId).limit(100).get(),
      // Credit-note-only products use separate fields and are not guaranteed
      // to have partnerId/partnerMobile or to appear in partnerProducts.
      productsRef.where('creditNoteCustomerId', isEqualTo: customerId).limit(100).get(),
      productsRef.where('lastCreditNoteCustomerId', isEqualTo: customerId).limit(100).get(),
      productsRef.where('creditNoteCustomerMobile', isEqualTo: rawPhone).limit(100).get(),
      productsRef.where('lastCreditNoteMobile', isEqualTo: rawPhone).limit(100).get(),
      if (normalPhone != rawPhone) ...[
        productsRef.where('creditNoteCustomerMobile', isEqualTo: normalPhone).limit(100).get(),
        productsRef.where('lastCreditNoteMobile', isEqualTo: normalPhone).limit(100).get(),
      ],
    ];
    final productQueryResults = await Future.wait(productQueryFutures);
    final connectedProducts = <String, Map<String, dynamic>>{};

    // Read directly linked product IDs, not the entire products collection.
    final directProductResults = await Future.wait(
      linkedIds.map((id) => productsRef.doc(id).get()),
    );
    for (final doc in directProductResults) {
      if (doc.exists) connectedProducts[doc.id] = <String, dynamic>{...?doc.data()};
    }
    for (final result in productQueryResults) {
      for (final doc in result.docs) {
        connectedProducts[doc.id] = <String, dynamic>{...doc.data()};
      }
    }

    var revenueShareCount = 0;
    var creditProductCount = 0;
    for (final entry in connectedProducts.entries) {
      final product = entry.value;
      final link = linkedProfiles[entry.key] ?? <String, dynamic>{};
      final model = (product['partnershipType'] ??
              product['preferredModel'] ??
              product['partnershipModel'] ??
              product['partnerModel'] ??
              product['preferredPartnershipModel'] ??
              link['partnershipType'] ??
              link['preferredModel'] ??
              link['partnershipModel'] ??
              link['partnerModel'] ??
              '')
          .toString()
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');
      bool hasValue(dynamic value) =>
          value != null && value.toString().trim().isNotEmpty;
      final hasCreditLink = hasValue(product['lastCreditNoteId']) ||
          hasValue(product['creditNoteCustomerId']) ||
          hasValue(product['lastCreditNoteCustomerId']) ||
          hasValue(product['creditNoteCustomerMobile']) ||
          hasValue(product['lastCreditNoteMobile']) ||
          hasValue(product['lastCreditNoteAmount']);
      if (model == 'revenue_share' || (model.isEmpty && !hasCreditLink)) {
        revenueShareCount++;
      } else if (model == 'credit_note' || hasCreditLink) {
        creditProductCount++;
      }
    }

    // Credit history is read from this customer's own subcollection only.
    // Sum ADD/credit-addition events once; do not sum mirrored product/branch copies.
    var totalCredit = 0.0;
    var creditCount = 0;
    if (ownCustomer != null) {
      final customerIdForHistory = (ownCustomer['_customerDocId'] ?? rawPhone).toString();
      final history = await customersRef
          .doc(customerIdForHistory)
          .collection('creditNotes')
          .get();
      for (final doc in history.docs) {
        final data = doc.data();
        final type = (data['entryType'] ?? data['type'] ?? '').toString().toLowerCase();
        if (type == 'credit_addition' || type == 'add') {
          final amount = _asAmount(data['amount'] ?? data['creditAmount']);
          if (amount > 0) {
            totalCredit += amount;
            creditCount++;
          }
        }
      }
      // Older profiles may not have history entries; retain a visible fallback.
      if (totalCredit == 0) {
        totalCredit = _asAmount(ownCustomer['totalCreditAmount'] ??
            ownCustomer['lastCreditNoteAmount']);
      }
    }

    return <String, dynamic>{
      // Every uniquely linked product counts as an active partnership here,
      // including credit-note-only products. The map deduplicates query results.
      'connectedCount': connectedProducts.length,
      'activeCount': connectedProducts.length,
      'revenueShareCount': revenueShareCount,
      'creditCount': creditCount,
      'creditProductCount': creditProductCount,
      'totalCredit': totalCredit,
      'creditBalance': _asAmount(ownCustomer?['creditBalance']),
    };
  }

  String _formatMoney(dynamic value) {
    final amount = _asAmount(value);
    return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  Widget _buildConnectedSummary() {
    final future = _partnerStatsFuture;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: const Text(
              'Connected product summary is temporarily unavailable.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
                ),
                SizedBox(width: 10),
                Text('Loading connected products and credits…',
                    style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        final connected = stats['activeCount'] as int? ??
            stats['connectedCount'] as int? ?? 0;
        final revenue = stats['revenueShareCount'] as int? ?? 0;
        final creditProducts = stats['creditProductCount'] as int? ?? 0;
        final totalCredit = stats['totalCredit'] ?? 0;
        final balance = stats['creditBalance'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _softGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: _gold),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE PARTNERSHIPS',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                            )),
                        SizedBox(height: 3),
                        Text('Revenue-share + credit-note dresses',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ),
                  Text('$connected',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      )),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'Each connected dress is counted once, including credit-note partnerships.',
                style: TextStyle(color: _muted, fontSize: 10, height: 1.45),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _summaryMiniMetric(
                      icon: Icons.percent_rounded,
                      title: 'Revenue share',
                      value: '$revenue',
                      tint: const Color(0xFFE8F3EA),
                      foreground: const Color(0xFF35704B),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _summaryMiniMetric(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Credit-note dresses',
                      value: '$creditProducts',
                      tint: const Color(0xFFF5EBDD),
                      foreground: const Color(0xFF926A2F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _summaryMiniMetric(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Total credit added',
                      value: _formatMoney(totalCredit),
                      tint: const Color(0xFFEAF0FA),
                      foreground: const Color(0xFF496C9B),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _summaryMiniMetric(
                      icon: Icons.savings_outlined,
                      title: 'Current credit balance',
                      value: _formatMoney(balance),
                      tint: const Color(0xFFF0EAF8),
                      foreground: const Color(0xFF7555A3),
                    ),
                  ),
                ],
              ),
              if ((stats['creditCount'] as int? ?? 0) > 0) ...[
                const SizedBox(height: 9),
                Text(
                  '${stats['creditCount']} credit addition${stats['creditCount'] == 1 ? '' : 's'} recorded',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _summaryMiniMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color tint,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normaliseStatus(dynamic raw) {
    final status = (raw ?? 'submitted')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (['pending', 'new', 'submitted'].contains(status)) return 'submitted';
    if (['reviewing', 'in_review', 'under_review', 'processing']
        .contains(status)) return 'under_review';
    if (['offer_sent', 'offer_ready', 'awaiting_owner', 'offer_pending']
        .contains(status)) return 'offer_sent';
    if (['approved', 'accepted', 'active', 'listed'].contains(status)) {
      return 'approved';
    }
    if (['declined', 'rejected', 'not_approved'].contains(status)) {
      return 'rejected';
    }
    if (['completed', 'rented', 'returned'].contains(status)) {
      return 'completed';
    }
    return status;
  }

  int _countStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String status,
  ) {
    return docs.where((doc) {
      return _normaliseStatus(doc.data()['status']) == status;
    }).length;
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DressHistoryScreen(),
      ),
    );
  }

  void _openListDress() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RentYourDressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        leading: _selectedTab == 0
            ? null
            : IconButton(
                tooltip: 'Back to overview',
                onPressed: () => setState(() => _selectedTab = 0),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'D O R',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'PARTNER STUDIO',
              style: TextStyle(
                color: _muted,
                fontSize: 8,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Partner information',
            onPressed: _showPartnerInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loadingIdentity
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _identityError != null
              ? _buildError()
              : IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildDashboardTab(),
                    _buildDressesTab(),
                    _buildBookingsTab(),
                    _buildEarningsTab(),
                  ],
                ),
    );
  }

  Widget _buildDashboardTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _myRequests!.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final submitted = _countStatus(docs, 'submitted');
        final underReview = _countStatus(docs, 'under_review');
        final approved = _countStatus(docs, 'approved');

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildHero(total),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your partner overview',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _gold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            _buildConnectedSummary(),
            const SizedBox(height: 13),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 1.12,
              children: [
                _metricCard(
                  title: 'My dresses',
                  value: '$total',
                  subtitle: 'Total submissions',
                  icon: Icons.checkroom_outlined,
                  color: const Color(0xFF926A2F),
                  tint: const Color(0xFFFAF0DB),
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                _metricCard(
                  title: 'Under review',
                  value: '$underReview',
                  subtitle: 'Being reviewed',
                  icon: Icons.manage_search_rounded,
                  color: const Color(0xFF496C9B),
                  tint: const Color(0xFFEAF0FA),
                  onTap: _openHistory,
                ),
                _metricCard(
                  title: 'Submitted',
                  value: '$submitted',
                  subtitle: 'Awaiting review',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF926A2F),
                  tint: const Color(0xFFFAF0DB),
                  onTap: _openHistory,
                ),
                _metricCard(
                  title: 'Approved',
                  value: '$approved',
                  subtitle: 'Approved dresses',
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF35704B),
                  tint: const Color(0xFFE8F3EA),
                  onTap: _openHistory,
                ),
              ],
            ),
            const SizedBox(height: 25),
            _sectionHeading('Quick actions', 'Manage your wardrobe'),
            const SizedBox(height: 13),
            _actionTile(
              icon: Icons.add_a_photo_outlined,
              title: 'List a new dress',
              subtitle: 'Submit photos and partnership preference',
              onTap: _openListDress,
            ),
            const SizedBox(height: 10),
            _actionTile(
              icon: Icons.history_rounded,
              title: 'Dress history',
              subtitle: 'View submissions and review statuses',
              onTap: _openHistory,
            ),
            const SizedBox(height: 10),
            _actionTile(
              icon: Icons.calendar_month_outlined,
              title: 'Booking history',
              subtitle: 'View rental bookings for approved dresses',
              onTap: () => setState(() => _selectedTab = 2),
            ),
            const SizedBox(height: 10),
            _actionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Billing and payments',
              subtitle: 'View bill-wise breakdowns and your share from each rental',
              onTap: () => setState(() => _selectedTab = 3),
            ),
            const SizedBox(height: 20),
            _buildCommercialNote(),
          ],
        );
      },
    );
  }

  Widget _buildDressesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _myRequests!.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _simpleState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your dresses',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(() {}),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];
            final aMillis = aDate is Timestamp
                ? aDate.millisecondsSinceEpoch
                : 0;
            final bMillis = bDate is Timestamp
                ? bDate.millisecondsSinceEpoch
                : 0;
            return bMillis.compareTo(aMillis);
          });

        if (docs.isEmpty) {
          return _simpleState(
            icon: Icons.checkroom_outlined,
            title: 'Your wardrobe starts here',
            message:
                'List your first dress and track its review progress here.',
            actionLabel: 'List a dress',
            onAction: _openListDress,
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            _sectionHeading('YOUR COLLECTION', 'My dresses'),
            const SizedBox(height: 7),
            const Text(
              'Every submission, with its latest status.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 17),
            ...docs.map((doc) {
              final data = doc.data();
              final urls = data['imageUrls'] is List
                  ? (data['imageUrls'] as List).whereType<String>().toList()
                  : <String>[];
              final status = _statusLabel(data['status']);
              final name = (data['dressName'] ?? 'Untitled dress').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _openHistory,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 76,
                              height: 88,
                              color: _softGold,
                              child: urls.isNotEmpty &&
                                      Uri.tryParse(urls.first)?.hasAbsolutePath == true &&
                                      (Uri.tryParse(urls.first)?.hasScheme ?? false)
                                  ? Image.network(
                                      urls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: _softGold,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.checkroom_outlined,
                                          color: _gold,
                                          size: 28,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.checkroom_outlined,
                                      color: _gold,
                                      size: 28,
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
                                const SizedBox(height: 5),
                                Text(
                                  '${data['category'] ?? 'Uncategorised'} · ${data['size'] ?? 'Size not set'}',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                _statusChip(status),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openListDress,
              icon: const Icon(Icons.add_rounded),
              label: const Text('List another dress'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return const PartnerBookingsScreen();
  }

  Widget _buildEarningsTab() {
    return const PartnerPaymentsScreen();
  }

  Widget _buildHero(int total) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [Color(0xFF30251F), Color(0xFF70543E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -9,
            top: -10,
            child: Icon(
              Icons.diamond_outlined,
              size: 100,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'YOUR PARTNER SPACE',
                  style: TextStyle(
                    color: Color(0xFFE8CEA1),
                    fontSize: 9,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your wardrobe.\nYour opportunity.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Manage your dresses, follow rental activity and '
                'keep track of your benefits with Dor.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 12,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  const Icon(
                    Icons.checkroom_outlined,
                    color: Color(0xFFE8CEA1),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$total ${total == 1 ? 'dress submitted' : 'dresses submitted'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _openListDress,
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      backgroundColor: const Color(0xFFE8CEA1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      '+ List dress',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: _muted,
                    size: 15,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String eyebrow, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF997648),
            fontSize: 9,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _softGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF997648), size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    Color foreground = const Color(0xFF926A2F);
    Color background = const Color(0xFFFAF0DB);
    IconData icon = Icons.schedule_rounded;

    switch (label) {
      case 'Under review':
        foreground = const Color(0xFF496C9B);
        background = const Color(0xFFEAF0FA);
        icon = Icons.manage_search_rounded;
        break;
      case 'Offer ready':
        foreground = const Color(0xFF7555A3);
        background = const Color(0xFFF0EAF8);
        icon = Icons.mark_email_read_outlined;
        break;
      case 'Approved':
      case 'Completed':
        foreground = const Color(0xFF35704B);
        background = const Color(0xFFE8F3EA);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'Not approved':
        foreground = const Color(0xFF9B4242);
        background = const Color(0xFFF9EAEA);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(dynamic raw) {
    final status = _normaliseStatus(raw);
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under review';
      case 'offer_sent':
        return 'Offer ready';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Not approved';
      case 'completed':
        return 'Completed';
      default:
        return 'In progress';
    }
  }

  Widget _modulePlaceholder({
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
    required List<_PlaceholderFeature> features,
    required String note,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF30251F), Color(0xFF70543E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFE8CEA1), size: 31),
              const SizedBox(height: 19),
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Color(0xFFE8CEA1),
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        const Text(
          'What you’ll be able to manage',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _actionTile(
              icon: feature.icon,
              title: feature.title,
              subtitle: feature.description,
              onTap: () => _showFeatureInfo(feature.title, note),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _softGold.withOpacity(0.72),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF997648),
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF6F6256),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _line),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _simpleState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _softGold,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: _gold),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return _simpleState(
      icon: Icons.person_off_outlined,
      title: 'Partner Studio unavailable',
      message: _identityError ??
          'We could not verify your account. Please try again.',
      actionLabel: 'Try again',
      onAction: () {
        setState(() {
          _loadingIdentity = true;
          _identityError = null;
        });
        _loadIdentity();
      },
    );
  }

  Widget _buildCommercialNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _softGold.withOpacity(0.72),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Color(0xFF997648),
            size: 19,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your preferred revenue split is 30% to the dress owner '
              'and 70% to Dor, subject to admin confirmation. Credit-note '
              'amounts and payout values will appear only after approval.',
              style: TextStyle(
                color: Color(0xFF6F6256),
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPartnerInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        decoration: const BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
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
              'About Partner Studio',
              style: TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use Partner Studio to submit dresses and follow their '
              'review progress. Dor confirms listing approval, rental '
              'prices, revenue-share terms and credit-note amounts. '
              'Booking, payout and credit-note history will be shown '
              'once those records are available for your account.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureInfo(String title, String note) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _background,
        title: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          note,
          style: const TextStyle(
            color: _muted,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderFeature {
  final IconData icon;
  final String title;
  final String description;

  const _PlaceholderFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
