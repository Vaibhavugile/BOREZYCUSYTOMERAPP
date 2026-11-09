import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    this.initialPaymentId,
    this.initialReceiptNumber,
    this.initialBranchCode,
  });

  final String? initialPaymentId;
  final String? initialReceiptNumber;
  final String? initialBranchCode;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with TickerProviderStateMixin {
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);

  late Future<String?> _phoneFuture;
  Future<List<_ReviewProduct>>? _reviewsFuture;
  String? _loadedPhone;
  late final AnimationController _introController;
  bool _notificationAutoOpenAttempted = false;

  @override
  void initState() {
    super.initState();
    _phoneFuture = UserHelper.getPhone();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
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
    _reviewsFuture = null;
    _loadedPhone = null;
    _phoneFuture = UserHelper.getPhone();
    if (mounted) setState(() {});
    try {
      await _phoneFuture;
    } catch (_) {}
  }

  Future<List<_ReviewProduct>> _loadReviews(String phone) async {
    final branchCode = TenantConfig.branchCode;
    final payments = await FirebaseFirestore.instance
        .collection('products')
        .doc(branchCode)
        .collection('payments')
        .where('contact', isEqualTo: phone)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final eligible = payments.docs.where((doc) {
      final stage = (doc.data()['bookingStage'] ?? '').toString();
      return stage == 'return' || stage == 'successful';
    }).toList();

    final results = await Future.wait(eligible.map((paymentDoc) async {
      final payment = paymentDoc.data();
      final rawProducts = payment['products'];
      final products = rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final reviewDocs = currentUid == null
          ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
          : (await paymentDoc.reference
                  .collection('reviews')
                  .where('customerUid', isEqualTo: currentUid)
                  .get())
              .docs;

      final submittedIndices = <int>{};
      for (final reviewDoc in reviewDocs) {
        final review = reviewDoc.data();
        if (review['status'] == 'submitted') {
          final index = review['productIndex'];
          if (index is int) submittedIndices.add(index);
          if (index is num) submittedIndices.add(index.toInt());
        }
      }

      final receipt = (payment['receiptNumber'] ?? paymentDoc.id).toString();
      final stage = (payment['bookingStage'] ?? '').toString();
      final date = _dateFrom(payment['createdAt']);

      return List<_ReviewProduct>.generate(products.length, (index) {
        final product = products[index];
        return _ReviewProduct(
          branchCode: branchCode,
          paymentId: paymentDoc.id,
          customerPhone: phone,
          receiptNumber: receipt,
          bookingStage: stage,
          bookingDate: date,
          productIndex: index,
          productName: (product['productName'] ?? 'Rental item').toString(),
          productCode:
              (product['productCode'] ?? product['productId'] ?? '').toString(),
          imageUrl: (product['imageUrl'] ?? '').toString(),
          isReviewed: submittedIndices.contains(index),
        );
      });
    }));

    return results.expand((items) => items).toList();
  }

  void _scheduleNotificationAutoOpen(List<_ReviewProduct> items) {
    final paymentId = widget.initialPaymentId?.trim() ?? '';
    final receiptNumber = widget.initialReceiptNumber?.trim() ?? '';
    final branchCode = widget.initialBranchCode?.trim() ?? '';

    if (_notificationAutoOpenAttempted ||
        (paymentId.isEmpty && receiptNumber.isEmpty)) {
      return;
    }

    _notificationAutoOpenAttempted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (branchCode.isNotEmpty && branchCode != TenantConfig.branchCode) {
        _showNotificationMessage(
          'This notification belongs to a different branch.',
        );
        return;
      }

      // Prefer the Firestore payment document ID. Use receipt number only
      // for older/test notifications that do not carry paymentId.
      final matches = items.where((item) {
        if (paymentId.isNotEmpty) return item.paymentId == paymentId;
        return receiptNumber.isNotEmpty &&
            item.receiptNumber.toLowerCase() == receiptNumber.toLowerCase();
      }).toList();

      if (matches.isEmpty) {
        _showNotificationMessage(
          'We could not find this booking in your eligible reviews. Pull down to refresh.',
        );
        return;
      }

      final pending = matches.where((item) => !item.isReviewed).toList();
      final target = pending.isNotEmpty ? pending.first : matches.first;

      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => _ReviewComposerScreen(item: target),
        ),
      );

      if (submitted == true && mounted) {
        await _refresh();
      }
    });
  }

  void _showNotificationMessage(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ink,
          ),
        );
    });
  }

  DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Completed booking';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
            Expanded(
              child: FutureBuilder<String?>(
                future: _phoneFuture,
                builder: (context, phoneSnapshot) {
                  if (phoneSnapshot.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  if (phoneSnapshot.hasError) {
                    return _message(
                      icon: Icons.wifi_off_rounded,
                      title: 'Couldn’t load your reviews',
                      subtitle: 'Check your connection and try again.',
                      action: _refresh,
                    );
                  }

                  final phone = phoneSnapshot.data?.trim();
                  if (phone == null || phone.isEmpty) {
                    return _message(
                      icon: Icons.lock_outline_rounded,
                      title: 'Sign in to review',
                      subtitle:
                          'Sign in with your mobile number to see your completed rentals and share product reviews.',
                    );
                  }

                  if (_loadedPhone != phone || _reviewsFuture == null) {
                    _loadedPhone = phone;
                    _reviewsFuture = _loadReviews(phone);
                  }

                  return FutureBuilder<List<_ReviewProduct>>(
                    future: _reviewsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _loading();
                      }
                      if (snapshot.hasError) {
                        return _message(
                          icon: Icons.cloud_off_rounded,
                          title: 'Unable to load completed rentals',
                          subtitle:
                              'Please try again. Your booking information has not been changed.',
                          action: _refresh,
                        );
                      }

                      final items = snapshot.data ?? [];
                      _scheduleNotificationAutoOpen(items);
                      if (items.isEmpty) {
                        return RefreshIndicator(
                          color: _gold,
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 55, 24, 40),
                            children: [
                              _emptyState(),
                            ],
                          ),
                        );
                      }

                      final pending = items.where((e) => !e.isReviewed).length;
                      return RefreshIndicator(
                        color: _gold,
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
                          children: [
                            _summary(pending, items.length),
                            const SizedBox(height: 18),
                            ...items.map((item) => _productCard(item)),
                          ],
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
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: AnimatedBuilder(
        animation: _introController,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_introController.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _softGold,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _line),
              ),
              child: const Icon(Icons.rate_review_rounded,
                  color: _gold, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR EXPERIENCE',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Product Reviews',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
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
              child: IconButton(
                tooltip: 'Refresh reviews',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, color: _ink, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(int pending, int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF342923), Color(0xFF5A4535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFE6C18D), size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending == 0 ? 'You’re all caught up' : '$pending reviews to share',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total product${total == 1 ? '' : 's'} from returned and completed bookings',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.rate_review_outlined,
              color: Color(0xFFE6C18D), size: 25),
        ],
      ),
    );
  }

  Widget _productCard(_ReviewProduct item) {
    final color = item.isReviewed ? const Color(0xFF43856A) : _gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 78,
                height: 96,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (item.productCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${item.productCode}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    '${item.receiptNumber}  •  ${_dateLabel(item.bookingDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 9.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        item.isReviewed
                            ? Icons.check_circle_rounded
                            : Icons.rate_review_outlined,
                        size: 13,
                        color: color,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.isReviewed ? 'In-app review saved' : 'Share your experience',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: item.isReviewed
                        ? Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6F1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Text(
                              'Thank you!',
                              style: TextStyle(
                                color: Color(0xFF43856A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _ink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            onPressed: () async {
                              final submitted = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => _ReviewComposerScreen(item: item),
                                ),
                              );
                              if (submitted == true && mounted) {
                                await _refresh();
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Review on Google',
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w800)),
                                SizedBox(width: 5),
                                Icon(Icons.open_in_new_rounded, size: 13),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _softGold,
      child: const Center(
        child: Icon(Icons.checkroom_rounded, color: _gold, size: 28),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: _softGold,
            shape: BoxShape.circle,
            border: Border.all(color: _line),
          ),
          child: const Icon(Icons.reviews_outlined, color: _gold, size: 42),
        ),
        const SizedBox(height: 22),
        const Text(
          'Your reviews start here',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Once a rental is returned or completed, its products will appear here so you can share your experience.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
        ),
        const SizedBox(height: 18),
        const Text(
          'Only returned and successful bookings are eligible.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _loading() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: List.generate(
        4,
        (_) => Container(
          height: 132,
          margin: const EdgeInsets.only(bottom: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    Future<void> Function()? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _softGold,
              ),
              child: Icon(icon, color: _gold, size: 35),
            ),
            const SizedBox(height: 19),
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
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(
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
}

class _ReviewProduct {
  const _ReviewProduct({
    required this.branchCode,
    required this.paymentId,
    required this.customerPhone,
    required this.receiptNumber,
    required this.bookingStage,
    required this.bookingDate,
    required this.productIndex,
    required this.productName,
    required this.productCode,
    required this.imageUrl,
    required this.isReviewed,
  });

  final String branchCode;
  final String paymentId;
  final String customerPhone;
  final String receiptNumber;
  final String bookingStage;
  final DateTime? bookingDate;
  final int productIndex;
  final String productName;
  final String productCode;
  final String imageUrl;
  final bool isReviewed;
}

class _ReviewComposerScreen extends StatefulWidget {
  const _ReviewComposerScreen({required this.item});

  final _ReviewProduct item;

  @override
  State<_ReviewComposerScreen> createState() => _ReviewComposerScreenState();
}

class _ReviewComposerScreenState extends State<_ReviewComposerScreen> {
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);
  static const String _fallbackGoogleReviewUrl =
      'https://g.page/r/CR4cURMFIRA7EAE/review';

  final _reviewController = TextEditingController();
  int _rating = 5;
  String _language = 'English';
  bool _generating = false;
  bool _openingGoogle = false;
  bool _hasGeneratedDraft = false;
  String _googleReviewUrl = _fallbackGoogleReviewUrl;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
        ),
      );
  }

  Future<void> _generateReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please sign in to generate a review.');
      return;
    }
    if (widget.item.customerPhone.trim().isEmpty) {
      _showMessage('Your mobile number was not found. Please sign in again.');
      return;
    }

    setState(() {
      _generating = true;
      _hasGeneratedDraft = false;
    });

    try {
      final callable = _functions.httpsCallable(
        'generateProductReview',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );
      final result = await callable.call({
        'branchCode': widget.item.branchCode,
        'customerPhone': widget.item.customerPhone,
        'receiptNumber': widget.item.receiptNumber,
        'productIndex': widget.item.productIndex,
        'rating': _rating,
        'language': _language,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final generated = (data['generatedReview'] ?? '').toString().trim();
      if (generated.isEmpty) {
        throw Exception('The review generator returned an empty draft. Please try again.');
      }

      _reviewController.text = generated;
      final returnedUrl = (data['googleReviewUrl'] ?? '').toString().trim();
      if (returnedUrl.startsWith('https://')) {
        _googleReviewUrl = returnedUrl;
      }

      if (mounted) {
        setState(() => _hasGeneratedDraft = true);
        _showMessage('Your review draft is ready. Read it before sharing.');
      }
    } on FirebaseFunctionsException catch (error) {
      _showMessage(error.message ?? 'Could not generate the review. Please try again.');
    } catch (error) {
      _showMessage('Could not generate the review: $error');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copyAndOpenGoogle() async {
    final reviewText = _reviewController.text.trim();
    if (!_hasGeneratedDraft || reviewText.length < 8) {
      _showMessage('Generate your review draft first.');
      return;
    }

    setState(() => _openingGoogle = true);
    try {
      await Clipboard.setData(ClipboardData(text: reviewText));
      final opened = await launchUrl(
        Uri.parse(_googleReviewUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Review copied. Google could not be opened; use the Open Google button below.');
        return;
      }
      _showMessage('Review copied. Paste it into Google, check it, and publish if it reflects your experience.');
    } catch (error) {
      _showMessage('Review copied, but Google could not be opened. Please try the Google button again.');
    } finally {
      if (mounted) setState(() => _openingGoogle = false);
    }
  }

  Future<void> _openGoogleOnly() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_googleReviewUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) _showMessage('Could not open the Google review page.');
    } catch (_) {
      _showMessage('Could not open the Google review page.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Share your DOR experience',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _productSummary(item),
            const SizedBox(height: 20),
            _sectionLabel('YOUR HONEST RATING'),
            const SizedBox(height: 9),
            _ratingSelector(),
            const SizedBox(height: 20),
            _sectionLabel('REVIEW LANGUAGE'),
            const SizedBox(height: 9),
            _languageSelector(),
            const SizedBox(height: 22),
            Container(
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _softGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: _gold, size: 19),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your review draft',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_hasGeneratedDraft)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF43856A), size: 19),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We’ll prepare a draft from your completed rental, product name and selected rating. No feedback form is needed.',
                    style: TextStyle(color: _muted, fontSize: 11.5, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: OutlinedButton.icon(
                      onPressed: _generating || _openingGoogle ? null : _generateReview,
                      icon: _generating
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _gold),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _generating ? 'Creating your review...' : (_hasGeneratedDraft ? 'Regenerate review' : 'Generate my review'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _gold, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (_hasGeneratedDraft) ...[
                    const SizedBox(height: 17),
                    _sectionLabel('PREVIEW · YOU CAN EDIT THIS DRAFT'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      minLines: 5,
                      maxLines: 9,
                      maxLength: 1800,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {},
                      decoration: InputDecoration(
                        hintText: 'Your generated review will appear here.',
                        filled: true,
                        fillColor: _cream,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _gold, width: 1.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _openingGoogle ? null : _copyAndOpenGoogle,
                        icon: _openingGoogle
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.content_copy_rounded, size: 18),
                        label: Text(
                          _openingGoogle ? 'Opening Google...' : 'Copy & open Google review',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _ink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Center(
                      child: TextButton.icon(
                        onPressed: _openingGoogle ? null : _openGoogleOnly,
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('Open Google review page'),
                        style: TextButton.styleFrom(
                          foregroundColor: _gold,
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _softGold,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE9DCC9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _gold, size: 17),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Please read the draft before posting. Edit anything that does not match your real experience. Google will ask you to confirm and publish the review; this app cannot post it or verify that it was submitted.',
                      style: TextStyle(color: _ink, fontSize: 10.5, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productSummary(_ReviewProduct item) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 74,
              height: 90,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETED RENTAL',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 9,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Booking ${item.receiptNumber}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _softGold,
      child: const Icon(Icons.checkroom_rounded, color: _gold, size: 28),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _ratingSelector() {
    const labels = ['Poor', 'Fair', 'Good', 'Great', 'Excellent'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _rating;
              return GestureDetector(
                onTap: () => setState(() {
                  _rating = value;
                  _hasGeneratedDraft = false;
                }),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: selected ? _gold : const Color(0xFFD8D1C8),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            labels[_rating - 1],
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageSelector() {
    const languages = ['English', 'Hindi', 'Marathi', 'Hinglish'];
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: languages.map((language) {
        final selected = _language == language;
        return ChoiceChip(
          label: Text(language),
          selected: selected,
          onSelected: (_) => setState(() {
            _language = language;
            _hasGeneratedDraft = false;
          }),
          selectedColor: _softGold,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? _gold : _line),
          labelStyle: TextStyle(
            color: selected ? _ink : _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        );
      }).toList(),
    );
  }
}

