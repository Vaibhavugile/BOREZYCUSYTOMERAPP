import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import 'dress_history_detail_screen.dart';

class DressHistoryScreen extends StatefulWidget {
  const DressHistoryScreen({super.key});

  @override
  State<DressHistoryScreen> createState() => _DressHistoryScreenState();
}

class _DressHistoryScreenState extends State<DressHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFFF7F3ED);
  static const Color _ink = Color(0xFF251C17);
  static const Color _gold = Color(0xFFB9965A);
  static const Color _muted = Color(0xFF81766D);
  static const Color _line = Color(0xFFE7DED2);
  static const Color _softGold = Color(0xFFF3E8D8);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  String? _phone;
  String? _branchCode;
  String _selectedFilter = 'All';
  bool _loadingIdentity = true;
  String? _identityError;

  static const List<_HistoryFilter> _filters = [
    _HistoryFilter('All', 'All dresses'),
    _HistoryFilter('submitted', 'Submitted'),
    _HistoryFilter('under_review', 'Under review'),
    _HistoryFilter('offer_sent', 'Offer ready'),
    _HistoryFilter('approved', 'Approved'),
    _HistoryFilter('connected', 'Connected'),
    _HistoryFilter('rejected', 'Rejected'),
    _HistoryFilter('completed', 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadIdentity();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              'Please sign in with your registered mobile number to view your dress history.';
          _loadingIdentity = false;
        });
        return;
      }

      setState(() {
        _branchCode = branch;
        _phone = phone.trim();
        _loadingIdentity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _identityError = 'Unable to load your account. Please try again.';
        _loadingIdentity = false;
      });
    }
  }

  Query<Map<String, dynamic>>? get _requestsQuery {
    if (_branchCode == null || _phone == null) return null;

    return FirebaseFirestore.instance
        .collection('products')
        .doc(_branchCode)
        .collection('dressRentalRequests')
        .where('ownerPhone', isEqualTo: _phone)
        .orderBy('createdAt', descending: true);
  }

  String _normaliseStatus(dynamic raw) {
    final status = (raw ?? 'submitted')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    // Support common status names if the admin panel uses a variant.
    if (['pending', 'new', 'submitted'].contains(status)) {
      return 'submitted';
    }
    if (['reviewing', 'in_review', 'under_review', 'processing']
        .contains(status)) {
      return 'under_review';
    }
    if (['offer_sent', 'offer_ready', 'awaiting_owner', 'offer_pending']
        .contains(status)) {
      return 'offer_sent';
    }
    if (['connected', 'partner', 'partnered'].contains(status)) {
      return 'connected';
    }
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

  _StatusStyle _statusStyle(String status) {
    switch (_normaliseStatus(status)) {
      case 'submitted':
        return const _StatusStyle(
          label: 'Submitted',
          color: Color(0xFF926A2F),
          background: Color(0xFFFAF0DB),
          icon: Icons.schedule_rounded,
        );
      case 'under_review':
        return const _StatusStyle(
          label: 'Under review',
          color: Color(0xFF496C9B),
          background: Color(0xFFEAF0FA),
          icon: Icons.manage_search_rounded,
        );
      case 'offer_sent':
        return const _StatusStyle(
          label: 'Offer ready',
          color: Color(0xFF7555A3),
          background: Color(0xFFF0EAF8),
          icon: Icons.mark_email_read_outlined,
        );
      case 'connected':
        return const _StatusStyle(
          label: 'Connected',
          color: Color(0xFF35704B),
          background: Color(0xFFE8F3EA),
          icon: Icons.link_rounded,
        );
      case 'approved':
        return const _StatusStyle(
          label: 'Approved',
          color: Color(0xFF35704B),
          background: Color(0xFFE8F3EA),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'rejected':
        return const _StatusStyle(
          label: 'Not approved',
          color: Color(0xFF9B4242),
          background: Color(0xFFF9EAEA),
          icon: Icons.cancel_outlined,
        );
      case 'completed':
        return const _StatusStyle(
          label: 'Completed',
          color: Color(0xFF35704B),
          background: Color(0xFFE8F3EA),
          icon: Icons.task_alt_rounded,
        );
      default:
        return const _StatusStyle(
          label: 'In progress',
          color: Color(0xFF6F6256),
          background: Color(0xFFF1EDE7),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (_selectedFilter == 'All') return true;
    return _normaliseStatus(data['status']) == _selectedFilter;
  }

  int _countFor(List<Map<String, dynamic>> docs, String status) {
    return docs.where((data) => _normaliseStatus(data['status']) == status).length;
  }

  String _normalisePhone(String value) => value.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^91(?=\d{10}$)'), '');

  int _dateSortValue(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  String _dateLabel(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    return 'Date unavailable';
  }

  String _money(dynamic value) {
    if (value == null) return 'Not confirmed yet';
    if (value is num) {
      return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
    }
    final text = value.toString().trim();
    if (text.isEmpty) return 'Not confirmed yet';
    return text.startsWith('₹') ? text : '₹$text';
  }

  String _partnershipLabel(dynamic value) {
    switch ((value ?? '').toString()) {
      case 'revenue_share':
        return 'Revenue sharing';
      case 'credit_note':
        return 'Dor credit note';
      default:
        return 'Not selected';
    }
  }

  int _reloadToken = 0;

  Future<List<Map<String, dynamic>>> _loadHistoryRecords() async {
    final branch = _branchCode;
    final rawPhone = (_phone ?? '').trim();
    final phone = _normalisePhone(rawPhone);
    if (branch == null || phone.isEmpty) return <Map<String, dynamic>>[];

    final db = FirebaseFirestore.instance;
    final productsRef = db.collection('products').doc(branch).collection('products');
    final customersRef = db.collection('customers').doc(branch).collection('users');
    final branchCreditRef =
        db.collection('products').doc(branch).collection('creditNotes');
    final requestsRef =
        db.collection('products').doc(branch).collection('dressRentalRequests');

    // Resolve this customer only. Never download the complete customers collection.
    final phoneVariants = <String>{rawPhone, phone}..removeWhere((value) => value.isEmpty);
    final customerQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      for (final value in phoneVariants) ...[
        customersRef.where('mobileNumber', isEqualTo: value).limit(5).get(),
        customersRef.where('phone', isEqualTo: value).limit(5).get(),
        customersRef.where('mobile', isEqualTo: value).limit(5).get(),
      ],
    ];
    final identityResults = await Future.wait([
      customersRef.doc(rawPhone).get(),
      customersRef.doc(phone).get(),
      ...customerQueries,
    ]);

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

    final customerById = customerDocs;
    final ownCustomer = customerDocs.values.cast<Map<String, dynamic>?>().firstWhere(
      (customer) {
        if (customer == null) return false;
        final customerPhone = _normalisePhone(
          (customer['mobileNumber'] ?? customer['phone'] ?? customer['mobile'] ?? '').toString(),
        );
        return customerPhone == phone ||
            customer['_customerDocId'] == rawPhone ||
            customer['_customerDocId'] == phone;
      },
      orElse: () => customerDocs[rawPhone] ?? customerDocs[phone],
    );
    final ownCustomerId = (ownCustomer?['_customerDocId'] ?? rawPhone).toString();
    final customerIds = <String>{ownCustomerId, rawPhone, phone}
      ..removeWhere((id) => id.trim().isEmpty);

    final ownCustomerPhones = <String>{phone};
    for (final customer in customerDocs.values) {
      for (final key in ['mobileNumber', 'phone', 'mobile']) {
        final value = _normalisePhone((customer[key] ?? '').toString());
        if (value.isNotEmpty) ownCustomerPhones.add(value);
      }
    }

    final customerProductIds = <String>{};
    final customerPartnerProducts = <String, Map<String, dynamic>>{};
    if (ownCustomer != null) {
      for (final key in [
        'partnerProducts', 'connectedProducts', 'productIds',
        'connectedProductIds', 'dressProductIds',
      ]) {
        final value = ownCustomer[key];
        if (value is List) {
          for (final item in value) {
            if (item is String && item.trim().isNotEmpty) {
              customerProductIds.add(item.trim());
            } else if (item is Map) {
              final id = (item['productId'] ?? item['id'] ??
                      item['relatedProductId'] ?? item['productDocId'] ?? '').toString().trim();
              if (id.isNotEmpty) {
                customerProductIds.add(id);
                customerPartnerProducts[id] = <String, dynamic>{
                  ...Map<String, dynamic>.from(item),
                  'productId': id,
                };
              }
            }
          }
        }
      }
    }

    // Fetch only this customer's requests and only product records that match
    // one of the known customer/partner fields. All independent queries run together.
    final requestQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      requestsRef.where('ownerPhone', isEqualTo: rawPhone)
          .orderBy('createdAt', descending: true).limit(100).get(),
      if (phone != rawPhone)
        requestsRef.where('ownerPhone', isEqualTo: phone)
            .orderBy('createdAt', descending: true).limit(100).get(),
      ...customerIds.map((id) => requestsRef.where('ownerUid', isEqualTo: id).limit(100).get()),
    ];

    final productQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      ...ownCustomerPhones.map((value) =>
          productsRef.where('partnerMobile', isEqualTo: value).limit(100).get()),
      ...ownCustomerPhones.map((value) =>
          productsRef.where('lastCreditNoteMobile', isEqualTo: value).limit(100).get()),
      ...ownCustomerPhones.map((value) =>
          productsRef.where('creditNoteCustomerMobile', isEqualTo: value).limit(100).get()),
      ...customerIds.map((value) =>
          productsRef.where('partnerId', isEqualTo: value).limit(100).get()),
      ...customerIds.map((value) =>
          productsRef.where('lastCreditNoteCustomerId', isEqualTo: value).limit(100).get()),
      ...customerIds.map((value) =>
          productsRef.where('creditNoteCustomerId', isEqualTo: value).limit(100).get()),
      ...customerIds.map((value) =>
          productsRef.where('partner.customerId', isEqualTo: value).limit(100).get()),
    ];

    final creditQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      ...ownCustomerPhones.map((value) =>
          branchCreditRef.where('mobileNumber', isEqualTo: value).limit(200).get()),
      ...ownCustomerPhones.map((value) =>
          branchCreditRef.where('phone', isEqualTo: value).limit(200).get()),
      ...customerIds.map((value) =>
          branchCreditRef.where('customerId', isEqualTo: value).limit(200).get()),
      ...customerIds.map((value) =>
          branchCreditRef.where('customerUid', isEqualTo: value).limit(200).get()),
    ];

    final baseResults = await Future.wait([
      ...requestQueries,
      ...productQueries,
      ...creditQueries,
    ]);

    final requestCount = requestQueries.length;
    final productCount = productQueries.length;
    final requestsSnaps = baseResults.take(requestCount)
        .cast<QuerySnapshot<Map<String, dynamic>>>().toList();
    final productSnaps = baseResults.skip(requestCount).take(productCount).toList();
    final branchCreditSnaps = baseResults.skip(requestCount + productCount)
        .cast<QuerySnapshot<Map<String, dynamic>>>().toList();

    final requestDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snap in requestsSnaps) {
      for (final doc in snap.docs) {
        requestDocs[doc.id] = doc;
      }
    }

    final productDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final result in productSnaps.cast<QuerySnapshot<Map<String, dynamic>>>()) {
      for (final doc in result.docs) {
        productDocs[doc.id] = doc;
      }
    }

    final records = <Map<String, dynamic>>[];
    final requestProductIds = <String>{};
    for (final doc in requestDocs.values) {
      final data = Map<String, dynamic>.from(doc.data());
      final ownerPhone = _normalisePhone(
        (data['ownerPhone'] ?? data['mobileNumber'] ?? data['phone'] ?? '').toString(),
      );
      final ownerId = (data['ownerUid'] ?? data['customerId'] ?? data['ownerId'] ?? '').toString();
      if (!ownCustomerPhones.contains(ownerPhone) &&
          !customerIds.contains(ownerId)) continue;
      data['_recordId'] = doc.id;
      data['_recordType'] = 'request';
      data['dressName'] = data['dressName'] ?? data['name'] ?? 'Untitled dress';
      final linkedProductId =
          (data['productId'] ?? data['connectedProductId'] ?? '').toString().trim();
      if (linkedProductId.isNotEmpty) requestProductIds.add(linkedProductId);
      records.add(data);
    }

    // Add directly linked product docs referenced by the customer's own profile
    // or their submitted requests. These are point reads, not a full products scan.
    for (final productId in {...customerProductIds, ...requestProductIds}) {
      if (productDocs.containsKey(productId)) continue;
      final doc = await productsRef.doc(productId).get();
      if (doc.exists) productDocs[doc.id] = doc;
    }

    final branchCreditEntries = <Map<String, dynamic>>[];
    for (final snap in branchCreditSnaps) {
      for (final doc in snap.docs) {
        final entry = doc.data();
        final entryPhone = _normalisePhone(
          (entry['mobileNumber'] ?? entry['phone'] ?? '').toString(),
        );
        final entryCustomerId =
            (entry['customerId'] ?? entry['customerUid'] ?? '').toString();
        if (ownCustomerPhones.contains(entryPhone) || customerIds.contains(entryCustomerId)) {
          branchCreditEntries.add(<String, dynamic>{
            ...entry,
            '_creditNoteDocId': doc.id,
          });
        }
      }
    }

    // Only inspect per-product credit-note histories for candidate products already
    // linked to this customer. Never loop through every product in the branch.
    final candidateProductIds = <String>{...productDocs.keys, ...customerProductIds, ...requestProductIds};
    final productCreditFutures = candidateProductIds.map((productId) async {
      try {
        final snap = await productsRef.doc(productId).collection('creditNotes').limit(200).get();
        return MapEntry(productId, snap.docs.map((doc) => <String, dynamic>{
          ...doc.data(), '_creditNoteDocId': doc.id,
        }).toList());
      } catch (_) {
        return MapEntry(productId, <Map<String, dynamic>>[]);
      }
    }).toList();

    // Read only this customer's history in parallel with candidate product histories.
    final customerCreditFuture = () async {
      if (ownCustomerId.isEmpty) return <Map<String, dynamic>>[];
      try {
        final snap = await customersRef.doc(ownCustomerId)
            .collection('creditNotes').limit(200).get();
        return snap.docs.map((doc) => <String, dynamic>{
          ...doc.data(), '_creditNoteDocId': doc.id,
        }).toList();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }();
    final histories = await Future.wait([
      Future.wait(productCreditFutures),
      customerCreditFuture,
    ]);
    final productCreditResults = histories[0] as List<MapEntry<String, List<Map<String, dynamic>>>>;
    final customerCreditEntries = histories[1] as List<Map<String, dynamic>>;
    final productCreditsById = <String, List<Map<String, dynamic>>>{
      for (final item in productCreditResults) item.key: item.value,
    };

    bool belongsToCustomer(Map<String, dynamic> entry) {
      final entryPhone = _normalisePhone(
        (entry['mobileNumber'] ?? entry['phone'] ?? entry['customerMobile'] ?? '').toString(),
      );
      final entryCustomerId =
          (entry['customerId'] ?? entry['customerUid'] ?? '').toString();
      return ownCustomerPhones.contains(entryPhone) || customerIds.contains(entryCustomerId);
    }

    for (final productDoc in productDocs.values) {
      if (!productDoc.exists) continue;
      final product = Map<String, dynamic>.from(productDoc.data() ?? {});
      final partner = product['partner'] is Map
          ? Map<String, dynamic>.from(product['partner'] as Map)
          : <String, dynamic>{};
      final linkedCustomerIds = <String>{
        (product['partnerId'] ?? '').toString(),
        (product['lastCreditNoteCustomerId'] ?? '').toString(),
        (product['creditNoteCustomerId'] ?? '').toString(),
        (partner['id'] ?? '').toString(),
        (partner['customerId'] ?? '').toString(),
      }..remove('');
      final linkedPhones = <String>{
        _normalisePhone((product['partnerMobile'] ?? '').toString()),
        _normalisePhone((product['lastCreditNoteMobile'] ?? '').toString()),
        _normalisePhone((product['creditNoteCustomerMobile'] ?? '').toString()),
        _normalisePhone((partner['mobile'] ?? '').toString()),
        _normalisePhone((partner['phone'] ?? '').toString()),
      }..remove('');

      final ownCreditEntries = productCreditsById[productDoc.id] ?? <Map<String, dynamic>>[];
      final profilePartner = customerPartnerProducts[productDoc.id] ?? <String, dynamic>{};
      bool explicitlyReferencesProduct(Map<String, dynamic> entry) {
        final relatedId = (entry['relatedProductId'] ?? entry['productId'] ??
            entry['dressProductId'] ?? '').toString();
        final relatedCode = (entry['relatedProductCode'] ?? entry['productCode'] ??
            entry['dressCode'] ?? '').toString();
        final productCode = (product['productCode'] ?? product['code'] ??
            product['itemCode'] ?? '').toString();
        return relatedId == productDoc.id ||
            (relatedCode.isNotEmpty && productCode.isNotEmpty && relatedCode == productCode);
      }

      final productCreditMatches = ownCreditEntries.where((entry) {
        final type = (entry['entryType'] ?? entry['type'] ?? '').toString().toLowerCase();
        final isAddition = type == 'credit_addition' || type == 'add' ||
            type == 'credit' || type == 'credit_added';
        // Product subcollection itself scopes the dress; still require the customer's identity.
        return isAddition && belongsToCustomer(entry);
      }).toList();
      final customerCreditMatches = customerCreditEntries.where((entry) =>
          belongsToCustomer(entry) && explicitlyReferencesProduct(entry)).toList();
      final branchCreditMatches = branchCreditEntries.where((entry) =>
          belongsToCustomer(entry) && explicitlyReferencesProduct(entry)).toList();

      final productPartnerLinked =
          linkedCustomerIds.any(customerIds.contains) ||
          linkedPhones.any(ownCustomerPhones.contains);
      final hasCreditLink = productCreditMatches.isNotEmpty ||
          customerCreditMatches.isNotEmpty || branchCreditMatches.isNotEmpty;
      if (!productPartnerLinked && !hasCreditLink &&
          !customerProductIds.contains(productDoc.id) &&
          !requestProductIds.contains(productDoc.id)) continue;

      // The product's own history is authoritative. Customer and branch histories
      // mirror the same event, so adding all three would double/triple-count credit.
      final creditEntries = productCreditMatches.isNotEmpty
          ? productCreditMatches
          : (customerCreditMatches.isNotEmpty ? customerCreditMatches : branchCreditMatches);
      final creditTotal = creditEntries.fold<double>(0, (sum, entry) {
        final amount = entry['amount'] ?? entry['creditAmount'] ?? entry['Balance'];
        if (amount is num) return sum + amount.toDouble();
        return sum + (double.tryParse((amount ?? '').toString()) ?? 0);
      });
      final imageValue = product['imageUrls'] ?? product['images'];
      final images = imageValue is List
          ? imageValue.whereType<String>().toList()
          : <String>[];
      final connected = <String, dynamic>{
        ...product,
        '_recordId': productDoc.id,
        '_recordType': 'connected',
        '_isCreditNotePartner': hasCreditLink,
        '_creditNoteCount': creditEntries.length,
        '_creditNoteTotal': creditTotal,
        'partnerCommissionPercentage': product['partnerCommissionPercentage'] ??
            profilePartner['commissionPercentage'] ??
            profilePartner['partnerCommissionPercentage'],
        'productCode': product['productCode'] ?? product['partnerProductCode'] ??
            profilePartner['productCode'] ?? profilePartner['productCode'],
        'dressName': product['productName'] ?? product['name'] ??
            product['dressName'] ?? 'Connected dress',
        'category': product['category'] ?? product['type'] ?? 'Dress',
        'size': product['size'] ?? product['dressSize'] ?? 'Not specified',
        'condition': product['condition'] ?? 'Not specified',
        'imageUrls': images.isNotEmpty
            ? images
            : (product['imageUrl'] is String ? [product['imageUrl']] : <String>[]),
        'createdAt': product['partnershipCreatedAt'] ??
            product['createdAt'] ?? product['updatedAt'],
        'status': 'connected',
        'preferredModel': product['preferredModel'] ??
            (hasCreditLink ? 'credit_note' : 'revenue_share'),
        'approvedRentalPrice': product['rent'] ?? product['rentalPrice'] ??
            product['price'] ?? product['approvedRentalPrice'],
        'approvedCreditAmount': product['creditAmount'] ??
            product['approvedCreditAmount'] ?? (hasCreditLink ? creditTotal : null),
        '_linkedCustomerIds': linkedCustomerIds.toList(),
      };
      connected['partnerCommissionPercentage'] ??= profilePartner['commissionPercentage'];
      connected['partnershipStatus'] ??= profilePartner['partnershipStatus'] ?? 'active';

      records.removeWhere((record) =>
          record['_recordType'] == 'request' &&
          (record['productId'] ?? record['connectedProductId'] ?? '').toString() == productDoc.id);
      records.removeWhere((record) =>
          record['_recordType'] == 'connected' && record['_recordId'] == productDoc.id);
      records.add(connected);
    }

    // Always surface the customer's own partnerProducts links. This is the source
    // of truth written by ProductPartnerPage; do not depend only on product-side
    // partnerMobile/partnerId queries, which may not match legacy records.
    for (final entry in customerPartnerProducts.entries) {
      final productId = entry.key;
      final alreadyAdded = records.any((record) =>
          record['_recordType'] == 'connected' && record['_recordId'] == productId);
      if (alreadyAdded) continue;
      final profile = entry.value;
      final linkedProduct = productDocs[productId];
      final product = linkedProduct?.data() ?? <String, dynamic>{};
      final merged = <String, dynamic>{...profile, ...product};
      final imageValue = merged['imageUrls'] ?? merged['images'];
      final images = imageValue is List
          ? imageValue.whereType<String>().toList()
          : <String>[];
      records.add(<String, dynamic>{
        ...merged,
        '_recordId': productId,
        '_recordType': 'connected',
        '_isCreditNotePartner': false,
        '_creditNoteCount': 0,
        '_creditNoteTotal': 0.0,
        'partnerCommissionPercentage': merged['partnerCommissionPercentage'] ??
            merged['commissionPercentage'],
        'dressName': merged['productName'] ?? merged['productName'] ??
            merged['dressName'] ?? merged['name'] ?? 'Connected dress',
        'category': merged['category'] ?? 'Dress',
        'size': merged['size'] ?? merged['dressSize'] ?? 'Not specified',
        'condition': merged['condition'] ?? 'Not specified',
        'imageUrls': images.isNotEmpty ? images :
            (merged['imageUrl'] is String ? [merged['imageUrl']] : <String>[]),
        'createdAt': merged['assignedAt'] ?? merged['partnershipCreatedAt'] ??
            merged['createdAt'] ?? merged['updatedAt'],
        'status': 'connected',
        'partnershipStatus': merged['partnershipStatus'] ?? 'active',
        'preferredModel': merged['preferredModel'] ?? 'revenue_share',
        'approvedRentalPrice': merged['rent'] ?? merged['rentalPrice'] ??
            merged['price'] ?? merged['approvedRentalPrice'],
      });
    }

    records.sort((a, b) =>
        _dateSortValue(b['createdAt']).compareTo(_dateSortValue(a['createdAt'])));
    return records;
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
        centerTitle: true,
        title: const Column(
          children: [
            Text('D O R', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 3.5)),
            SizedBox(height: 2),
            Text('MY DRESS HISTORY', style: TextStyle(color: _muted, fontSize: 8, letterSpacing: 1.7, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: _loadingIdentity
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _identityError != null
              ? _buildError(_identityError!)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    key: ValueKey(_reloadToken),
                    future: _loadHistoryRecords(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildError('We could not load your dress history. Please check your connection and try again.',
                            onRetry: () => setState(() => _reloadToken++));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: _gold));
                      }
                      final records = snapshot.data ?? <Map<String, dynamic>>[];
                      final filtered = records.where(_matchesFilter).toList();
                      return RefreshIndicator(
                        color: _gold,
                        onRefresh: () async {
                          setState(() => _reloadToken++);
                          await Future<void>.delayed(const Duration(milliseconds: 450));
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
                          children: [
                            _buildHero(records.length),
                            const SizedBox(height: 18),
                            _buildSummary(records),
                            const SizedBox(height: 25),
                            _buildFilterHeading(),
                            const SizedBox(height: 13),
                            _buildFilters(records),
                            const SizedBox(height: 20),
                            Row(children: [
                              const Expanded(child: Text('Your dress history', style: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800))),
                              Text('${filtered.length} ${filtered.length == 1 ? 'dress' : 'dresses'}', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 14),
                            if (filtered.isEmpty) _buildEmptyState()
                            else ...filtered.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildDressCard(context, entry.value['_recordId'].toString(), entry.value, entry.key),
                            )),
                            const SizedBox(height: 8),
                            _buildFooterNote(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildHero(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        gradient: const LinearGradient(
          colors: [Color(0xFF211914), Color(0xFF493629), Color(0xFF785B3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: -5,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: Icon(
              Icons.diamond_outlined,
              size: 98,
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
                  'YOUR DOR JOURNEY',
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
                'Every dress has\na story.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.13,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Your submissions, connected pieces and partnership terms — '
                'beautifully organised in one place.',
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
                    Icons.inventory_2_outlined,
                    color: Color(0xFFE8CEA1),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '$total ${total == 1 ? 'dress submitted' : 'dresses submitted'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSummary(List<Map<String, dynamic>> docs) {
    final submitted = _countFor(docs, 'submitted');
    final review = _countFor(docs, 'under_review');
    final approved = _countFor(docs, 'approved');

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.schedule_rounded,
            label: 'Submitted',
            count: submitted,
            tint: const Color(0xFFFAF0DB),
            iconColor: const Color(0xFF926A2F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.manage_search_rounded,
            label: 'In review',
            count: review,
            tint: const Color(0xFFEAF0FA),
            iconColor: const Color(0xFF496C9B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Approved',
            count: approved,
            tint: const Color(0xFFE8F3EA),
            iconColor: const Color(0xFF35704B),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required int count,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line.withOpacity(0.8)),
        boxShadow: [BoxShadow(color: _ink.withOpacity(0.035), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 13),
          Text(
            '$count',
            style: const TextStyle(
              color: _ink,
              fontSize: 25,
              letterSpacing: -0.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeading() {
    return const Text(
      'Explore by status',
      style: TextStyle(
        color: _ink,
        fontSize: 15,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFilters(List<Map<String, dynamic>> docs) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter.value;
          final count = filter.value == 'All'
              ? docs.length
              : _countFor(docs, filter.value);

          return InkWell(
            onTap: () => setState(() => _selectedFilter = filter.value),
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: selected ? _ink : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected ? _ink : _line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: selected ? Colors.white : _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.16)
                          : _softGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

  Widget _buildDressCard(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
    int index,
  ) {
    final status = _normaliseStatus(data['status']);
    final style = _statusStyle(status);
    final urls = (data['imageUrls'] is List)
        ? (data['imageUrls'] as List)
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList()
        : <String>[];
    final name = (data['dressName'] ?? data['productName'] ?? data['name'] ?? 'Untitled dress').toString();
    final category = (data['category'] ?? 'Category not set').toString();
    final date = _dateLabel(data['createdAt']);
    final isConnected = data['_recordType'] == 'connected';
    final String model = isConnected
        ? _partnershipLabel(
            data['partnershipType'] ??
                data['preferredModel'] ??
                (data['_isCreditNotePartner'] == true ? 'credit_note' : 'revenue_share'),
          ).toUpperCase()
        : _partnershipLabel(data['preferredModel']);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + (index.clamp(0, 5) * 65)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        shadowColor: _ink.withOpacity(0.07),
        child: InkWell(
          onTap: () => _showDressDetails(context, requestId, data),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line.withOpacity(0.85)),
              boxShadow: [BoxShadow(color: _ink.withOpacity(0.025), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dressThumbnail(urls),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 15,
                                height: 1.3,
                                letterSpacing: -0.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$category  ·  ${data['size'] ?? 'Size not set'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 9),
                            _statusChip(style),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _muted,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: _line),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: _muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF80633C),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (isConnected || data['offerAccepted'] == true ||
                    data['approvedRentalPrice'] != null ||
                    data['approvedCreditAmount'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 16, color: _gold),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                isConnected ? 'Connected dress details' : 'Commercial terms',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (data['offerAccepted'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ACCEPTED',
                                  style: TextStyle(
                                    color: Color(0xFF35704B),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        if (isConnected && (data['rent'] != null || data['rentalPrice'] != null || data['price'] != null || data['approvedRentalPrice'] != null))
                          _compactTermRow('Rental price', _money(data['rent'] ?? data['rentalPrice'] ?? data['price'] ?? data['approvedRentalPrice'])),
                        if (isConnected && data['deposit'] != null)
                          _compactTermRow('Deposit', _money(data['deposit'])),
                        if (isConnected && data['partnerCommissionPercentage'] != null)
                          _compactTermRow('Your partnership commission', '${data['partnerCommissionPercentage']}%'),
                        if (isConnected && data['productCode'] != null)
                          _compactTermRow('Dress code', data['productCode'].toString()),
                        if (isConnected && data['_isCreditNotePartner'] == true)
                          _compactTermRow('Credit-note entries', '${data['_creditNoteCount'] ?? 0}'),
                        if (isConnected && data['_isCreditNotePartner'] == true)
                          _compactTermRow('Total credit given for this dress', _money(data['_creditNoteTotal'])),
                        if (data['approvedRentalPrice'] != null && !isConnected)
                          _compactTermRow(
                            'Approved rental price',
                            _money(data['approvedRentalPrice']),
                          ),
                        if (data['approvedCreditAmount'] != null && !isConnected)
                          _compactTermRow(
                            'Approved credit',
                            _money(data['approvedCreditAmount']),
                          ),
                        if (data['ownerSharePercent'] != null)
                          _compactTermRow(
                            'Your revenue share',
                            '${data['ownerSharePercent']}%',
                          ),
                        if (data['dorSharePercent'] != null)
                          _compactTermRow(
                            'Dor revenue share',
                            '${data['dorSharePercent']}%',
                          ),
                      ],
                    ),
                  ),
                ],
                if (status == 'offer_sent') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAF8),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFF7555A3),
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dor has updated your offer. Tap to view details.',
                            style: TextStyle(
                              color: Color(0xFF7555A3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'rejected' &&
                    (data['adminNotes'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note: ${data['adminNotes']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9B4242),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactTermRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dressThumbnail(List<String> urls) {
    return Container(
      width: 98,
      height: 118,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _softGold,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.14)),
      ),
      child: urls.isEmpty
          ? const Icon(
              Icons.checkroom_outlined,
              size: 34,
              color: _gold,
            )
          : Image.network(
              urls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: _gold,
                  size: 28,
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _gold,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(_StatusStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              style.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isAll = _selectedFilter == 'All';
    final filterLabel = _filters
        .firstWhere(
          (filter) => filter.value == _selectedFilter,
          orElse: () => const _HistoryFilter('All', 'All dresses'),
        )
        .label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: _softGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              color: _gold,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isAll ? 'Your dress story starts here' : 'No $filterLabel dresses',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            isAll
                ? 'Once you submit a dress to Dor, it will appear here '
                    'with its latest review status.'
                : 'There are no dress submissions with this status yet. '
                    'Try another filter to see your other dresses.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.65,
            ),
          ),
          if (!isAll) ...[
            const SizedBox(height: 17),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 'All'),
              child: const Text(
                'Show all dresses',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softGold.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF997648),
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Status and commercial terms reflect the latest information '
              'saved by Dor. Rental prices and credit amounts are only '
              'confirmed when approved by the team.',
              style: TextStyle(
                color: Color(0xFF6F6256),
                fontSize: 10,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFF9EAEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFF9B4242),
                size: 31,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'We couldn’t load your history',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 19,
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
                height: 1.6,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ] else if (!_loadingIdentity) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _identityError = null;
                    _loadingIdentity = true;
                  });
                  _loadIdentity();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDressDetails(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DressHistoryDetailScreen(
          branchCode: _branchCode ?? '',
          recordId: requestId,
          record: Map<String, dynamic>.from(data),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String status, Map<String, dynamic> data) {
    final steps = <_TimelineStep>[
      const _TimelineStep(
        title: 'Request submitted',
        description: 'Your dress details were sent to Dor.',
      ),
      const _TimelineStep(
        title: 'Review by Dor',
        description: 'The team checks the dress and its details.',
      ),
      const _TimelineStep(
        title: 'Terms and decision',
        description: 'Dor confirms approval and applicable terms.',
      ),
    ];

    final normal = _normaliseStatus(status);
    final activeIndex = switch (normal) {
      'submitted' => 0,
      'under_review' => 1,
      'offer_sent' => 2,
      'approved' || 'completed' => 3,
      'rejected' => 2,
      _ => 0,
    };

    return Column(
      children: List.generate(steps.length, (index) {
        final completed = index < activeIndex;
        final active = index == activeIndex;
        final rejectedHere = normal == 'rejected' && index == 2;
        final color = rejectedHere
            ? const Color(0xFF9B4242)
            : (completed || active ? _gold : const Color(0xFFD8CFC4));

        return Padding(
          padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed || active ? color : Colors.transparent,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Icon(
                        rejectedHere
                            ? Icons.close_rounded
                            : completed
                                ? Icons.check_rounded
                                : active
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                        color: completed || active
                            ? Colors.white
                            : const Color(0xFFD8CFC4),
                        size: active && !rejectedHere ? 9 : 15,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        height: 34,
                        width: 1.5,
                        color: completed
                            ? _gold
                            : const Color(0xFFE3DACE),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rejectedHere ? 'Review decision' : steps[index].title,
                        style: TextStyle(
                          color: active || completed ? _ink : _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rejectedHere
                            ? 'This submission was not approved.'
                            : steps[index].description,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _HistoryFilter {
  final String value;
  final String label;

  const _HistoryFilter(this.value, this.label);
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusStyle({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });
}

class _TimelineStep {
  final String title;
  final String description;

  const _TimelineStep({
    required this.title,
    required this.description,
  });
}
