import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tenant_config.dart';

/// Premium partner detail view. The receipt's payment document is the source
/// of truth; all product lines on that receipt are shown, not just the partner's.
class PartnerBookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const PartnerBookingDetailsScreen({super.key, required this.booking});

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
      appBar: AppBar(title: const Text('Booking breakdown', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: _bg, foregroundColor: _ink, elevation: 0),
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
                final explicitLineDiscounts = lines.any((p) => ['discountOnRent', 'rentDiscount', 'discount', 'discountAmount'].any((k) => p[k] != null));
                // Common bill discount is split equally across all product lines.
                // When line-level discounts are present, use that breakdown only
                // to avoid deducting the same discount a second time.
                final commonDiscountPerLine = lines.isNotEmpty && !explicitLineDiscounts
                    ? totalDiscount / lines.length
                    : 0.0;
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
                  // Common bill discount is shared equally, not proportionally by rent.
                  // Prefer explicit product discounts when present to avoid double deduction.
                  final discount = explicitLineDiscounts
                      ? _num(rawLineDiscount)
                      : commonDiscountPerLine;
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
                  onRefresh: () async { (context as Element).markNeedsBuild(); },
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
                    _hero(receipt, stage, name, phone),
                    const SizedBox(height: 14),
                    _section('Your connected product revenue', Icons.account_balance_wallet_outlined, [
                      if (partnerRows.isEmpty && lineRows.isNotEmpty) const Text('Could not match your connected product to a product line on this receipt. The full bill is shown below, but no 30% / 70% split is applied to other products.', style: TextStyle(color: _muted, height: 1.5)),
                      _metric('Connected product base rent', _money(base)), _metric('Discount on connected product', '− ${_money(discount)}', valueColor: const Color(0xFFB66B52)),
                      _metric('Connected product net rent', _money(net), strong: true),
                      const Divider(height: 24),
                      Row(children: [Expanded(child: _splitCard('Partner / Owner', '30%', partner, const Color(0xFF397A60))), const SizedBox(width: 10), Expanded(child: _splitCard('DOR revenue', '70%', dor, _gold))]),
                      const SizedBox(height: 8), const Text('Revenue split is calculated from net rent after discount. Deposit is excluded from this rent split.', style: TextStyle(color: _muted, fontSize: 11, height: 1.4)),
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
                    _section('Payment & booking', Icons.receipt_long_outlined, [
                      _row('Receipt number', receipt), _row('Booking stage', stage), _row('Amount paid', _money(_num(payment['amountPaid'] ?? payment['amountpaid']))),
                      _row('Balance', _money(_num(payment['balance']))), _row('Deposit', _money(_num(payment['finalDeposit'] ?? payment['finaldeposite'] ?? payment['grandTotalDeposit']))),
                      _row('Pickup', _date(payment['pickupDate'] ?? payment['startDate'])), _row('Return', _date(payment['returnDate'] ?? payment['endDate'])),
                    ]),
                    const SizedBox(height: 14),
                    _section('Payment transactions', Icons.history, [
                      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('products').doc(TenantConfig.branchCode).collection('payments').doc(receipt).collection('transactions').orderBy('createdAt', descending: true).get(),
                        builder: (context, tx) {
                          if (tx.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                          if (tx.hasError) return Text('Could not load transactions: ${tx.error}', style: const TextStyle(color: _muted));
                          if (!tx.hasData || tx.data!.docs.isEmpty) return const Text('No transactions recorded for this receipt.', style: TextStyle(color: _muted));
                          return Column(children: tx.data!.docs.map((doc) { final d = doc.data(); return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFE9F2EC), child: Icon(Icons.payments_outlined, color: Color(0xFF397A60))), title: Text(_str(d, ['type', 'paymentNumber'], 'Payment'), style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)), subtitle: Text('${_str(d, ['mode', 'paymentMode'], '—')}  •  ${_date(d['createdAt'])}', style: const TextStyle(color: _muted, fontSize: 11)), trailing: Text(_money(_num(d['amount'])), style: const TextStyle(fontWeight: FontWeight.w800, color: _ink))); }).toList());
                        },
                      ),
                    ]),
                  ]),
                );
              },
            ),
    );
  }

  Widget _hero(String receipt, String stage, String name, String phone) => Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF332821), Color(0xFF66503A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _ink.withOpacity(.14), blurRadius: 18, offset: const Offset(0, 7))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('PARTNER BOOKING', style: TextStyle(color: Color(0xFFE4CFA8), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(receipt, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 13), Row(children: [const Icon(Icons.person_outline, color: Colors.white70, size: 17), const SizedBox(width: 7), Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(30)), child: Text(stage, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))]), const SizedBox(height: 5), Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12))]));
  Widget _section(String title, IconData icon, List<Widget> children) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line), boxShadow: [BoxShadow(color: _ink.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 35, height: 35, decoration: BoxDecoration(color: const Color(0xFFF4EBDD), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: _gold, size: 19)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)))]), const SizedBox(height: 15), ...children]));
  Widget _metric(String label, String value, {bool strong = false, Color? valueColor}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: strong ? _ink : _muted, fontSize: 12, fontWeight: strong ? FontWeight.w800 : FontWeight.w500))), Text(value, style: TextStyle(color: valueColor ?? _ink, fontSize: strong ? 16 : 13, fontWeight: FontWeight.w900))]));
  Widget _splitCard(String title, String percent, double amount, Color color) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.22))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(percent, style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(_money(amount), style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900))]));
  Widget _productLine(Map<String, dynamic> row) { final p = row['product'] as Map<String, dynamic>; final name = _str(p, ['productName', 'name', 'dressName', 'title'], 'Product'); final code = _str(p, ['productCode', 'code', 'sku'], '—'); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 3), Text('Code: $code  •  Qty: ${row['qty']}', style: const TextStyle(color: _muted, fontSize: 11)), const SizedBox(height: 10), _metric('Base rent', _money(row['base'] as double)), _metric('Discount', '− ${_money(row['discount'] as double)}', valueColor: const Color(0xFFB66B52)), _metric('Net rent', _money(row['net'] as double), strong: true), if (row['isPartner'] == true) ...[const Divider(height: 18), _metric('Partner share · 30%', _money(row['partner'] as double), valueColor: const Color(0xFF397A60)), _metric('DOR share · 70%', _money(row['dor'] as double), valueColor: _gold)] else const Padding(padding: EdgeInsets.only(top: 8), child: Text('Not part of this partner revenue split', style: TextStyle(color: _muted, fontSize: 11, fontStyle: FontStyle.italic)))])); }
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800)))]));
  Widget _message(String title, String body) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.receipt_long_outlined, size: 40, color: _gold), const SizedBox(height: 12), Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: _muted))])));
  String _date(dynamic value) { DateTime? d; if (value is Timestamp) d = value.toDate(); else if (value is DateTime) d = value; else if (value is String) d = DateTime.tryParse(value); if (d == null) return '—'; return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'; }
}
