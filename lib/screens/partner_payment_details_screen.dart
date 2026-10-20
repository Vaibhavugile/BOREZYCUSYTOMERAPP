import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tenant_config.dart';

/// Premium partner payment detail view. The receipt's payment document is the source
/// of truth; all product lines on that receipt are shown, not just the partner's.
class PartnerPaymentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const PartnerPaymentDetailsScreen({super.key, required this.booking});

  static const _bg = Color(0xFFFAF7F2);
  static const _ink = Color(0xFF29221E);
  static const _gold = Color(0xFFC5A46D);
  static const _muted = Color(0xFF81766D);
  static const _line = Color(0xFFECE2D5);

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0;
  }
  String _money(num value) => '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
  String _str(Map data, List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }
  List<Map<String, dynamic>> _lines(Map<String, dynamic> payment) {
    final raw = payment['productsSummary'] ?? payment['products'] ?? payment['items'];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _str(booking, ['receiptNumber', 'receiptNo', 'paymentReceiptNumber']);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Payment details', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: _bg, foregroundColor: _ink, elevation: 0),
      body: receipt.isEmpty
          ? const Center(child: Text('Receipt number is missing.'))
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('products').doc(TenantConfig.branchCode).collection('payments').doc(receipt).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return _message('Could not load payment details', snapshot.error.toString());
                if (!snapshot.hasData || !snapshot.data!.exists) return _message('Payment not found', 'No payment document was found for receipt $receipt.');
                final payment = Map<String, dynamic>.from(snapshot.data!.data()!);
                final user = payment['userDetails'] is Map ? Map<String, dynamic>.from(payment['userDetails']) : <String, dynamic>{};
                final lines = _lines(payment);
                final totalDiscount = _num(payment['discountOnRent'] ?? payment['discountonrent'] ?? user['discountOnRent'] ?? user['discountonrent']);
                final explicitLineDiscounts = lines.any((p) =>
                    ['discountOnRent', 'rentDiscount', 'discount', 'discountAmount'].any((k) => p[k] != null));
                final selectedProductsRaw = booking['partnerMatchedProducts'] ?? booking['products'] ?? const [];
                final selectedProducts = selectedProductsRaw is List ? selectedProductsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
                bool isPartnerLine(Map<String, dynamic> p) {
                  final id = _str(p, ['productId', 'id', 'productDocId']);
                  final code = _str(p, ['productCode', 'partnerProductCode', 'code', 'sku']);
                  final name = _str(p, ['productName', 'name', 'dressName', 'title']);
                  return selectedProducts.any((selected) {
                    final sid = _str(selected, ['productId', 'id', 'productDocId']);
                    final scode = _str(selected, ['productCode', 'partnerProductCode', 'code', 'sku']);
                    final sname = _str(selected, ['productName', 'name', 'dressName', 'title']);
                    if (id.isNotEmpty && sid.isNotEmpty) return id == sid;
                    if (code.isNotEmpty && scode.isNotEmpty) return code.toLowerCase() == scode.toLowerCase();
                    return name.isNotEmpty && sname.isNotEmpty && name.toLowerCase() == sname.toLowerCase();
                  });
                }
                final lineRows = <Map<String, dynamic>>[];
                double grossTotal = 0;
                for (final p in lines) {
                  final qty = _num(p['quantity'] ?? p['qty']).clamp(1, 9999).toDouble();
                  final unitRent = _num(p['rent'] ?? p['baseRent'] ?? p['price'] ?? p['finalRent'] ?? p['finalrent']);
                  final explicitBase = _num(p['totalRent'] ?? p['grossRent']);
                  final gross = explicitBase > 0 ? explicitBase : unitRent * qty;
                  grossTotal += gross;
                  lineRows.add({'product': p, 'qty': qty, 'base': gross, 'isPartner': isPartnerLine(p)});
                }
                for (final row in lineRows) {
                  final p = row['product'] as Map<String, dynamic>;
                  final rawLineDiscount = p['discountOnRent'] ?? p['rentDiscount'] ?? p['discountAmount'] ?? p['discount'];
                  final gross = row['base'] as double;
                  // Keep the list and details calculation consistent:
                  // explicit line discounts take precedence; otherwise split
                  // the receipt-level discount in proportion to gross rent.
                  final discount = explicitLineDiscounts
                      ? (rawLineDiscount != null ? _num(rawLineDiscount) : 0.0)
                      : (grossTotal > 0 ? totalDiscount * gross / grossTotal : 0.0);
                  final net = (gross - discount).clamp(0.0, double.infinity).toDouble();
                  row.addAll({'discount': discount, 'net': net, 'partner': row['isPartner'] == true ? net * .30 : 0.0, 'dor': row['isPartner'] == true ? net * .70 : 0.0});
                }
                final baseTotal = lineRows.fold<double>(0, (s, r) => s + (r['base'] as double));
                final lineDiscountTotal = lineRows.fold<double>(0, (s, r) => s + (r['discount'] as double));
                final netTotal = lineRows.fold<double>(0, (s, r) => s + (r['net'] as double));
                final partnerRows = lineRows.where((r) => r['isPartner'] == true).toList();
                final partnerBase = partnerRows.fold<double>(0, (s, r) => s + (r['base'] as double));
                final partnerDiscount = partnerRows.fold<double>(0, (s, r) => s + (r['discount'] as double));
                final partnerNet = partnerRows.fold<double>(0, (s, r) => s + (r['net'] as double));
                // Receipt-level fallback is shown for context only; never split the full bill when the selected product is not identified.
                final fallbackBase = _num(payment['grandTotalRent'] ?? payment['grandtotalrent'] ?? payment['finalRent'] ?? payment['finalrent']);
                final fallbackDiscount = totalDiscount;
                final base = partnerRows.isNotEmpty ? partnerBase : (lineRows.isEmpty ? fallbackBase : 0.0);
                final discount = partnerRows.isNotEmpty ? partnerDiscount : (lineRows.isEmpty ? fallbackDiscount : 0.0);
                final net = partnerRows.isNotEmpty ? partnerNet : (lineRows.isEmpty ? _num(payment['finalRent'] ?? payment['finalrent'] ?? (fallbackBase - fallbackDiscount)) : 0.0);
                final partner = net * .30;
                final dor = net * .70;
                final name = _str(user, ['name', 'customerName'], _str(payment, ['clientName', 'customerName', 'name'], 'Customer'));
                final phone = _str(user, ['contact', 'phone', 'mobile'], _str(payment, ['contact', 'phone', 'mobile'], '—'));
                final stage = _str(user, ['stage'], _str(payment, ['bookingStage', 'stage', 'status'], 'Booking'));
                return RefreshIndicator(
                  onRefresh: () async {
                    (context as Element).markNeedsBuild();
                    await Future<void>.delayed(const Duration(milliseconds: 150));
                  },
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
                    _hero(receipt, stage, name, phone),
                    const SizedBox(height: 14),
                    _section('Your earnings from this booking', Icons.account_balance_wallet_outlined, [
                      if (partnerRows.isEmpty && lineRows.isNotEmpty) const Text('Could not match your connected product to a product line on this receipt. The full bill is shown below, but no 30% / 70% split is applied to other products.', style: TextStyle(color: _muted, height: 1.5)),
                      _metric('Connected product base rent', _money(base)), _metric('Discount on connected product', '− ${_money(discount)}', valueColor: const Color(0xFFB66B52)),
                      _metric('Net rent after discount (share calculation basis)', _money(net)),
                      const SizedBox(height: 10),
                      Container(width: double.infinity, padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE7F5EC), Color(0xFFF4FBF6)]), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFB9DEC8))), child: Row(children: [Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFD0EBDD), shape: BoxShape.circle), child: const Icon(Icons.savings_outlined, color: Color(0xFF237653), size: 23)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR SHARE · 30%', style: TextStyle(color: Color(0xFF237653), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(_money(partner), style: const TextStyle(color: Color(0xFF175B3B), fontSize: 29, fontWeight: FontWeight.w900)), const SizedBox(height: 3), const Text('Your share from this bill, after applicable rent discount', style: TextStyle(color: Color(0xFF47745B), fontSize: 10, height: 1.4)), const SizedBox(height: 9), Row(children: [const Expanded(child: Text('Share basis · net rent', style: TextStyle(color: Color(0xFF47745B), fontSize: 10, fontWeight: FontWeight.w700)),), Text(_money(net), style: const TextStyle(color: Color(0xFF47745B), fontSize: 12, fontWeight: FontWeight.w800))])]))])),
                      const SizedBox(height: 8), const Text('Your revenue is calculated after the applicable rent discount. Customer deposit is not included.', style: TextStyle(color: _muted, fontSize: 11, height: 1.4)),
                    ]),
                    const SizedBox(height: 14),
                    _section('All products on this receipt', Icons.checkroom_outlined, [
                      if (lineRows.isEmpty) const Text('This payment document has no productsSummary/products/items list. Receipt-level rent totals are shown above.', style: TextStyle(color: _muted, height: 1.5)),
                      ...lineRows.map((r) => _productLine(r)),
                      if (lineRows.isNotEmpty) ...[
                        const Divider(height: 24), _metric('Entire bill base rent (context only)', _money(baseTotal)), _metric('Entire bill discount', '− ${_money(lineDiscountTotal)}'), _metric('Entire bill net rent', _money(netTotal), strong: true),
                      ],
                    ]),
                    const SizedBox(height: 14),
                    _section('Customer payment status', Icons.verified_outlined, [
                      Builder(builder: (context) {
                        final paid = _num(payment['amountPaid'] ?? payment['amountpaid'] ?? user['amountPaid'] ?? user['amountpaid']);
                        final balance = _num(payment['balance'] ?? user['balance']);
                        final raw = _str(payment, ['paymentStatus', 'paymentstatus', 'paymentState'], _str(user, ['paymentStatus', 'paymentstatus', 'paymentState'])).toLowerCase();
                        final isPaid = ['paid', 'completed', 'success', 'successful', 'settled'].contains(raw) || (balance <= 0 && paid > 0);
                        final isPartial = !isPaid && (paid > 0 || raw.contains('partial'));
                        final label = isPaid ? 'CUSTOMER PAYMENT COMPLETE' : isPartial ? 'CUSTOMER PARTIALLY PAID' : 'CUSTOMER PAYMENT DUE';
                        final color = isPaid ? const Color(0xFF237653) : isPartial ? const Color(0xFF9A6A19) : const Color(0xFFAD4545);
                        final tint = isPaid ? const Color(0xFFE6F4EC) : isPartial ? const Color(0xFFFFF3D9) : const Color(0xFFFCEAEA);
                        return Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.25))), child: Row(children: [Icon(isPaid ? Icons.check_circle_rounded : isPartial ? Icons.timelapse_rounded : Icons.pending_actions_rounded, color: color, size: 24), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: .4)), const SizedBox(height: 4), Text('Paid by customer: ${_money(paid)}  ·  Balance: ${_money(balance)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11))]))]));
                      }),
                      const SizedBox(height: 12),
                      _row('Receipt number', receipt), _row('Booking stage', stage), _row('Amount paid', _money(_num(payment['amountPaid'] ?? payment['amountpaid'] ?? user['amountPaid'] ?? user['amountpaid']))),
                      _row('Balance', _money(_num(payment['balance']))), _row('Deposit', _money(_num(payment['finalDeposit'] ?? payment['finaldeposite'] ?? payment['grandTotalDeposit']))),
                      _row('Pickup', _date(payment['pickupDate'] ?? payment['startDate'])), _row('Return', _date(payment['returnDate'] ?? payment['endDate'])),
                    ]),
                    const SizedBox(height: 14),
                    _section('Your payout status', Icons.account_balance_wallet_outlined, [
                      _partnerPayoutSection(receipt, partner, booking),
                    ]),
                    const SizedBox(height: 14),
                    _section('Payment screenshot & proof', Icons.image_outlined, [
                      Builder(builder: (context) {
                        final proof = _str(payment, ['paymentProofImage', 'screenshotUrl', 'paymentScreenshot', 'screenshot', 'proofUrl', 'image']);
                        final method = _str(payment, ['paymentMethod', 'paymentMode', 'mode', 'method'], '—');
                        final reference = _str(payment, ['transactionReference', 'reference', 'utr', 'transactionId', 'paymentReference'], '—');
                        final status = _str(payment, ['paymentStatus', 'status'], '—');
                        final notes = _str(payment, ['paymentNotes', 'notes', 'adminNotes']);
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _row('Payment method', method),
                          _row('Transaction reference', reference),
                          _row('Payment status', status),
                          if (notes.isNotEmpty) _row('Notes', notes),
                          const SizedBox(height: 10),
                          if (proof.isNotEmpty)
                            InkWell(onTap: () => _showImage(context, proof, 'Payment screenshot'), borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(proof, width: 94, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 94, height: 100, color: _line, child: const Icon(Icons.broken_image_outlined, color: _gold)))), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('View payment screenshot', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 12)), SizedBox(height: 5), Text('Tap the image to open full screen', style: TextStyle(color: _muted, fontSize: 10))])), const Icon(Icons.open_in_full_rounded, color: _gold)])))
                          else const Text('No screenshot is attached to the main payment document.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
                        ]);
                      }),
                    ]),
                    const SizedBox(height: 14),
                    _section('Payment transactions & history', Icons.history, [
                      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('products').doc(TenantConfig.branchCode).collection('payments').doc(receipt).collection('transactions').orderBy('createdAt', descending: true).get(),
                        builder: (context, tx) {
                          if (tx.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                          if (tx.hasError) return Text('Could not load transactions: ${tx.error}', style: const TextStyle(color: _muted));
                          if (!tx.hasData || tx.data!.docs.isEmpty) return const Text('No transactions recorded for this receipt.', style: TextStyle(color: _muted));
                          return Column(children: tx.data!.docs.map((doc) {
                            final d = doc.data();
                            final proof = _str(d, ['paymentProofImage', 'screenshotUrl', 'paymentScreenshot', 'screenshot', 'proofUrl', 'image']);
                            final isRefund = _str(d, ['type']).toLowerCase().contains('refund') || _str(d, ['type']).toLowerCase().contains('return');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
                              child: Column(children: [
                                ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: isRefund ? const Color(0xFFF9EAEA) : const Color(0xFFE9F2EC), child: Icon(isRefund ? Icons.keyboard_return_rounded : Icons.payments_outlined, color: isRefund ? const Color(0xFFAD4545) : const Color(0xFF397A60))), title: Text(_str(d, ['type', 'paymentNumber'], 'Payment'), style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), subtitle: Text('${_str(d, ['mode', 'paymentMode', 'method'], '—')}  •  ${_date(d['createdAt'])}${_str(d, ['reference', 'transactionReference', 'utr']).isNotEmpty ? '\nRef: ${_str(d, ['reference', 'transactionReference', 'utr'])}' : ''}', style: const TextStyle(color: _muted, fontSize: 11)), trailing: Text(_money(_num(d['amount'])), style: const TextStyle(fontWeight: FontWeight.w900, color: _ink))),
                                if (proof.isNotEmpty) InkWell(onTap: () => _showImage(context, proof, 'Transaction proof'), borderRadius: BorderRadius.circular(10), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(proof, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: _line, child: const Icon(Icons.broken_image_outlined, color: _gold)))), const SizedBox(width: 10), const Expanded(child: Text('Payment screenshot / proof · Tap to enlarge', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700))), const Icon(Icons.open_in_full_rounded, color: _gold, size: 18)])),
                              ]),
                            );
                          }).toList());
                        },
                      ),
                    ]),
                  ]),
                );
              },
            ),
    );
  }

  Widget _partnerPayoutSection(String receipt, double earned, Map<String, dynamic> booking) {
    final mobile = _str(booking, ['partnerMobile', 'partnerPhone', 'ownerMobile', 'ownerPhone']);
    if (mobile.isEmpty) {
      return const Text('Your payout status is not linked to this account yet. Please ask DOR to verify your registered mobile number.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').doc(TenantConfig.branchCode).collection('partnerSettlements').where('partnerMobile', isEqualTo: mobile).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Payout history could not be loaded.', style: TextStyle(color: _muted, fontSize: 11));
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()));
        final productRowsRaw = booking['partnerMatchedProducts'] ?? booking['products'] ?? const [];
        final productRows = productRowsRaw is List ? productRowsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
        final productIds = productRows.map((p) => _str(p, ['productId', 'id', 'productDocId'])).where((v) => v.isNotEmpty).toSet();
        final productCodes = productRows.map((p) => _str(p, ['productCode', 'code', 'sku'])).where((v) => v.isNotEmpty).toSet();
        final matched = <Map<String, dynamic>>[];
        double paid = 0;
        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final status = _str(data, ['status'], 'paid').toLowerCase();
          if (!['paid', 'completed'].contains(status)) continue;
          final allocations = data['allocations'];
          if (allocations is! List) continue;
          for (final raw in allocations) {
            if (raw is! Map) continue;
            final a = Map<String, dynamic>.from(raw);
            final allocationReceipt = _str(a, ['receiptNumber', 'receiptNo']);
            final pid = _str(a, ['productId', 'productDocId', 'id']);
            final code = _str(a, ['productCode', 'code']);
            final isThisBooking = allocationReceipt == receipt && ((pid.isNotEmpty && productIds.contains(pid)) || (code.isNotEmpty && productCodes.contains(code)) || (productIds.isEmpty && productCodes.isEmpty));
            if (isThisBooking) {
              paid += _num(a['amount']);
              matched.add({'settlement': data, 'allocation': a});
            }
          }
        }
        final pending = (earned - paid).clamp(0.0, double.infinity).toDouble();
        final isPaid = earned > 0 && pending <= .009;
        final isPartial = paid > .009 && !isPaid;
        final color = isPaid ? const Color(0xFF237653) : isPartial ? const Color(0xFF9A6A19) : const Color(0xFFAD4545);
        final tint = isPaid ? const Color(0xFFE6F4EC) : isPartial ? const Color(0xFFFFF3D9) : const Color(0xFFFCEAEA);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(isPaid ? Icons.check_circle_rounded : isPartial ? Icons.timelapse_rounded : Icons.hourglass_bottom_rounded, color: color), const SizedBox(width: 8), Expanded(child: Text(isPaid ? 'YOUR PAYOUT IS FULLY PAID' : isPartial ? 'YOUR PAYOUT IS PARTIALLY PAID' : 'YOUR PAYOUT IS PENDING', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)))]),
            const SizedBox(height: 12), _metric('Your earned share', _money(earned)), _metric('Paid to you by DOR', _money(paid), valueColor: const Color(0xFF237653)), _metric('Still payable to you', _money(pending), strong: true, valueColor: pending > .009 ? color : const Color(0xFF237653)),
          ])),
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 12), const Text('BILL-WISE PAYOUT ALLOCATIONS · PAID TO YOU', style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            ...matched.map((entry) {
              final settlement = entry['settlement'] as Map<String, dynamic>;
              final allocation = entry['allocation'] as Map<String, dynamic>;
              final ref = _str(settlement, ['reference', 'transactionReference'], 'No reference');
              final method = _str(settlement, ['method', 'paymentMethod'], 'Payment').replaceAll('_', ' ');
              return Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)), child: Row(children: [const Icon(Icons.verified_rounded, color: Color(0xFF237653), size: 21), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('+ ${_money(_num(allocation['amount']))}', style: const TextStyle(color: Color(0xFF237653), fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Allocated to bill $receipt · $method', style: const TextStyle(color: _muted, fontSize: 10)),
              Text('Reference: $ref', style: const TextStyle(color: _muted, fontSize: 10)), Text(_date(settlement['recordedAt'] ?? settlement['createdAt']), style: const TextStyle(color: _muted, fontSize: 10))])), const Text('PAID', style: TextStyle(color: Color(0xFF237653), fontSize: 9, fontWeight: FontWeight.w900))]));
            }),
          ],
          if (matched.isEmpty) const Padding(padding: EdgeInsets.only(top: 9), child: Text('No payout has been allocated to this booking yet.', style: TextStyle(color: _muted, fontSize: 11, height: 1.4))),
        ]);
      },
    );
  }

  void _showImage(BuildContext context, String url, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 260,
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

  Widget _hero(String receipt, String stage, String name, String phone) => Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF332821), Color(0xFF66503A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _ink.withOpacity(.14), blurRadius: 18, offset: const Offset(0, 7))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('PARTNER BOOKING', style: TextStyle(color: Color(0xFFE4CFA8), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(receipt, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 13), Row(children: [const Icon(Icons.person_outline, color: Colors.white70, size: 17), const SizedBox(width: 7), Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(30)), child: Text(stage, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))]), const SizedBox(height: 5), Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12))]));
  Widget _section(String title, IconData icon, List<Widget> children) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line), boxShadow: [BoxShadow(color: _ink.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 35, height: 35, decoration: BoxDecoration(color: const Color(0xFFF4EBDD), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: _gold, size: 19)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)))]), const SizedBox(height: 15), ...children]));
  Widget _metric(String label, String value, {bool strong = false, Color? valueColor}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: strong ? _ink : _muted, fontSize: 12, fontWeight: strong ? FontWeight.w800 : FontWeight.w500))), Text(value, style: TextStyle(color: valueColor ?? _ink, fontSize: strong ? 16 : 13, fontWeight: FontWeight.w900))]));
  Widget _splitCard(String title, String percent, double amount, Color color) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.22))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(percent, style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(_money(amount), style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900))]));
  Widget _productLine(Map<String, dynamic> row) { final p = row['product'] as Map<String, dynamic>; final name = _str(p, ['productName', 'name', 'dressName', 'title'], 'Product'); final code = _str(p, ['productCode', 'code', 'sku'], '—'); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 3), Text('Code: $code  •  Qty: ${row['qty']}', style: const TextStyle(color: _muted, fontSize: 11)), const SizedBox(height: 10), _metric('Base rent', _money(row['base'] as double)), _metric('Discount', '− ${_money(row['discount'] as double)}', valueColor: const Color(0xFFB66B52)), _metric('Net rent', _money(row['net'] as double), strong: true), if (row['isPartner'] == true) ...[const Divider(height: 18), _metric('YOUR SHARE · 30%', _money(row['partner'] as double), strong: true, valueColor: const Color(0xFF237653))] else const Padding(padding: EdgeInsets.only(top: 8), child: Text('Not part of this partner revenue split', style: TextStyle(color: _muted, fontSize: 11, fontStyle: FontStyle.italic)))])); }
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800)))]));
  Widget _message(String title, String body) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.receipt_long_outlined, size: 40, color: _gold), const SizedBox(height: 12), Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: _muted))])));
  String _date(dynamic value) { DateTime? d; if (value is Timestamp) d = value.toDate(); else if (value is DateTime) d = value; else if (value is String) d = DateTime.tryParse(value); if (d == null) return '—'; return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'; }
}
