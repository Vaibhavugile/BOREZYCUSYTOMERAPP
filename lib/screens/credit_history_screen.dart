import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/tenant_config.dart';

const Color _ink = Color(0xFF29221F);
const Color _muted = Color(0xFF8E857D);
const Color _gold = Color(0xFFB68A52);
const Color _line = Color(0xFFECE5DC);
const Color _cream = Color(0xFFFAF8F5);
const Color _softGold = Color(0xFFF7F0E7);

class CreditHistoryScreen extends StatefulWidget {
  final String mobileNumber;

  const CreditHistoryScreen({
    super.key,
    required this.mobileNumber,
  });

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen>
    with TickerProviderStateMixin {
  late Future<DocumentSnapshot?> _creditFuture;
  late final AnimationController _entranceController;
  final ScrollController _scrollController = ScrollController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _creditFuture = _fetchCreditDoc();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot?> _fetchCreditDoc() async {
    final query = await FirebaseFirestore.instance
        .collection('products')
        .doc(TenantConfig.branchCode)
        .collection('creditNotes')
        .where('mobileNumber', isEqualTo: widget.mobileNumber)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  Future<void> _refresh() async {
    setState(() {
      _creditFuture = _fetchCreditDoc();
    });
    await _creditFuture;
  }

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    final amount = _amount(value);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _CircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WALLET & CREDITS',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Credit history',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _CircleAction(
              icon: Icons.refresh_rounded,
              onTap: _refresh,
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _creditFuture,
        builder: (context, creditSnap) {
          if (creditSnap.connectionState == ConnectionState.waiting) {
            return const _WalletLoading();
          }
          if (creditSnap.hasError) {
            return _StatusState(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn’t load your wallet',
              message: 'Please check your connection and try again.',
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          if (!creditSnap.hasData || creditSnap.data == null) {
            return _StatusState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Your wallet is waiting',
              message: 'No wallet history was found for this mobile number.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }

          final creditDoc = creditSnap.data!;
          final raw = creditDoc.data();
          final creditData = raw is Map<String, dynamic>
              ? raw
              : <String, dynamic>{};
          final balance = creditData['Balance'] ?? 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .doc(TenantConfig.branchCode)
                .collection('creditNotes')
                .doc(creditDoc.id)
                .collection('history')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, historySnap) {
              if (historySnap.hasError) {
                return _StatusState(
                  icon: Icons.cloud_off_rounded,
                  title: 'History unavailable',
                  message: 'We couldn’t load the transactions. Please try again.',
                  actionLabel: 'Refresh',
                  onAction: _refresh,
                );
              }

              final docs = historySnap.data?.docs ?? [];
              final filteredDocs = docs.where((doc) {
                final type = (doc.data()['type'] ?? '').toString();
                if (_filter == 'Added') return type == 'ADD';
                if (_filter == 'Used') return type != 'ADD';
                return true;
              }).toList();

              if (_entranceController.status == AnimationStatus.dismissed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted &&
                      _entranceController.status == AnimationStatus.dismissed) {
                    _entranceController.forward();
                  }
                });
              }

              return RefreshIndicator(
                color: _gold,
                backgroundColor: Colors.white,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
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
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _WalletBalanceCard(
                          balance: _money(balance),
                          mobileNumber: widget.mobileNumber,
                          transactionCount: docs.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 13),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR ACTIVITY',
                                    style: TextStyle(
                                      color: _gold,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Transaction history',
                                    style: TextStyle(
                                      color: _ink,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _line),
                              ),
                              child: Text(
                                '${filteredDocs.length} records',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 45,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'All activity',
                              selected: _filter == 'All',
                              onTap: () => setState(() => _filter = 'All'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Credits added',
                              selected: _filter == 'Added',
                              onTap: () => setState(() => _filter = 'Added'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Credits used',
                              selected: _filter == 'Used',
                              onTap: () => setState(() => _filter = 'Used'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 15)),
                    if (historySnap.connectionState == ConnectionState.waiting &&
                        !historySnap.hasData)
                      const SliverToBoxAdapter(child: _TransactionSkeletons())
                    else if (filteredDocs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StatusState(
                          icon: Icons.receipt_long_rounded,
                          title: _filter == 'All'
                              ? 'No transactions yet'
                              : 'Nothing in this filter',
                          message: _filter == 'All'
                              ? 'Your credit activity will appear here when your wallet is used.'
                              : 'Try another filter to see your wallet activity.',
                          actionLabel: _filter == 'All' ? null : 'Show all',
                          onAction: _filter == 'All'
                              ? null
                              : () => setState(() => _filter = 'All'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = filteredDocs[index];
                              return _AnimatedTransactionCard(
                                key: ValueKey(doc.id),
                                index: index,
                                data: doc.data(),
                                money: _money,
                              );
                            },
                            childCount: filteredDocs.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final String balance;
  final String mobileNumber;
  final int transactionCount;

  const _WalletBalanceCard({
    required this.balance,
    required this.mobileNumber,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF7),
            Color(0xFFF7EBDD),
            Color(0xFFEBD4B5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7D4BB)),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -18,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 132,
              color: _gold.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR WALLET',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.9,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Available credits',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F3E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 13, color: Color(0xFF347A49)),
                        SizedBox(width: 5),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(0xFF347A49),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  color: Color(0xFF87683E),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.9,
                ),
              ),
              const SizedBox(height: 5),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Text(
                  balance,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 37,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: _gold.withOpacity(0.20)),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      color: Color(0xFF87683E), size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      mobileNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D5232),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 13, color: _gold),
                        const SizedBox(width: 5),
                        Text(
                          '$transactionCount transactions',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}

class _AnimatedTransactionCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final String Function(dynamic) money;

  const _AnimatedTransactionCard({
    super.key,
    required this.index,
    required this.data,
    required this.money,
  });

  @override
  State<_AnimatedTransactionCard> createState() =>
      _AnimatedTransactionCardState();
}

class _AnimatedTransactionCardState extends State<_AnimatedTransactionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    Future<void>.delayed(Duration(milliseconds: (widget.index * 55).clamp(0, 440)),
        () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isAdd = data['type'] == 'ADD';
    final amount = widget.money(data['amount'] ?? 0);
    final balance = widget.money(data['newBalance'] ?? 0);
    final timestamp = data['createdAt'];
    String date = 'Date unavailable';
    if (timestamp is Timestamp) {
      date = DateFormat('dd MMM yyyy • hh:mm a').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      date = DateFormat('dd MMM yyyy • hh:mm a').format(timestamp);
    }
    final note = (data['note'] ?? '').toString().trim();
    final receiptNo = (data['receiptNo'] ?? '').toString().trim();

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.025),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isAdd
                            ? const [Color(0xFFE8F5E9), Color(0xFFD2EBD5)]
                            : const [Color(0xFFFFEFEB), Color(0xFFF8DCD6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isAdd
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: isAdd
                          ? const Color(0xFF347A49)
                          : const Color(0xFFB34D43),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdd ? 'Credits added' : 'Credits used',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          date,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${isAdd ? '+' : '−'}$amount',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isAdd
                            ? const Color(0xFF347A49)
                            : const Color(0xFFB34D43),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 13),
              Container(height: 1, color: _line),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetadataPill(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'Balance $balance',
                    background: _softGold,
                    foreground: const Color(0xFF806039),
                  ),
                  if (receiptNo.isNotEmpty)
                    _MetadataPill(
                      icon: Icons.receipt_outlined,
                      text: receiptNo,
                      background: const Color(0xFFF0F1F3),
                      foreground: _muted,
                    ),
                  _MetadataPill(
                    icon: isAdd
                        ? Icons.add_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    text: isAdd ? 'Credit in' : 'Credit out',
                    background: isAdd
                        ? const Color(0xFFEAF5EC)
                        : const Color(0xFFFFEFEB),
                    foreground: isAdd
                        ? const Color(0xFF347A49)
                        : const Color(0xFFB34D43),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _MetadataPill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _ink : _line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _ink, size: 19),
        ),
      ),
    );
  }
}

class _WalletLoading extends StatefulWidget {
  const _WalletLoading();

  @override
  State<_WalletLoading> createState() => _WalletLoadingState();
}

class _WalletLoadingState extends State<_WalletLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
          const Color(0xFFF0EAE2),
          const Color(0xFFFAF6F0),
          _controller.value,
        )!;
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              height: 235,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 25),
            Container(height: 12, width: 130, color: color),
            const SizedBox(height: 14),
            ...List.generate(
              3,
              (_) => Container(
                height: 130,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionSkeletons extends StatelessWidget {
  const _TransactionSkeletons();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _SkeletonTransaction(),
          SizedBox(height: 12),
          _SkeletonTransaction(),
          SizedBox(height: 12),
          _SkeletonTransaction(),
        ],
      ),
    );
  }
}

class _SkeletonTransaction extends StatelessWidget {
  const _SkeletonTransaction();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _line),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _softGold,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                _SkeletonLine(width: 110),
                SizedBox(height: 12),
                _SkeletonLine(width: 150),
                SizedBox(height: 12),
                _SkeletonLine(width: 85),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: width,
      decoration: BoxDecoration(
        color: _softGold,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: _softGold,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _gold, size: 32),
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
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
