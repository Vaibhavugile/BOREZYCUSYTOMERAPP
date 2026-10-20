import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DressHistoryDetailScreen extends StatefulWidget {
  const DressHistoryDetailScreen({
    super.key,
    required this.branchCode,
    required this.recordId,
    required this.record,
  });

  final String branchCode;
  final String recordId;
  final Map<String, dynamic> record;

  @override
  State<DressHistoryDetailScreen> createState() => _DressHistoryDetailScreenState();
}

class _DressHistoryDetailScreenState extends State<DressHistoryDetailScreen> {
  static const Color _background = Color(0xFFF7F3ED);
  static const Color _ink = Color(0xFF251C17);
  static const Color _gold = Color(0xFFB9965A);
  static const Color _muted = Color(0xFF81766D);
  static const Color _line = Color(0xFFE7DED2);
  static const Color _softGold = Color(0xFFF3E8D8);

  String get _status => (widget.record['status'] ?? 'submitted').toString();
  bool get _connected => widget.record['_recordType'] == 'connected';
  String get _productId => (widget.record['productId'] ??
      widget.record['connectedProductId'] ??
      (_connected ? widget.record['_recordId'] : '') ??
      '').toString();

  String _text(dynamic value, [String fallback = 'Not provided']) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _money(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return 'Not confirmed yet';
    if (value is num) return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
    final text = value.toString().trim();
    return text.startsWith('₹') ? text : '₹$text';
  }

  String _date(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate().toLocal();
    if (value is DateTime) date = value.toLocal();
    if (date == null) return 'Date not available';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _modelLabel(dynamic value) {
    switch ((value ?? '').toString().toLowerCase()) {
      case 'revenue_share': return 'Revenue Share';
      case 'credit_note': return 'Credit Note';
      default: return _connected ? 'Connected partnership' : 'Not selected yet';
    }
  }

  Future<List<Map<String, dynamic>>> _loadActivity() async {
    if (widget.branchCode.isEmpty || _productId.isEmpty) return [];
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('products').doc(widget.branchCode)
          .collection('products').doc(_productId)
          .collection('partnershipActivity').get(),
      db.collection('products').doc(widget.branchCode)
          .collection('products').doc(_productId)
          .collection('creditNotes').get(),
    ]);
    final entries = <Map<String, dynamic>>[];
    for (final doc in results[0].docs) {
      entries.add({...doc.data(), '_logId': doc.id, '_logKind': 'partnership'});
    }
    for (final doc in results[1].docs) {
      final data = doc.data();
      final type = (data['entryType'] ?? data['type'] ?? '').toString().toLowerCase();
      if (type == 'credit_addition' || type == 'add' || type == 'credit_added' || type == 'credit') {
        entries.add({...data, '_logId': doc.id, '_logKind': 'credit'});
      }
    }
    entries.sort((a, b) {
      int millis(dynamic value) {
        if (value is Timestamp) return value.millisecondsSinceEpoch;
        if (value is DateTime) return value.millisecondsSinceEpoch;
        return 0;
      }
      return millis(b['createdAt'] ?? b['timestamp'] ?? b['performedAt'])
          .compareTo(millis(a['createdAt'] ?? a['timestamp'] ?? a['performedAt']));
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.record;
    final name = _text(data['dressName'] ?? data['productName'] ?? data['name'], 'Untitled dress');
    final imageValue = data['imageUrls'] ?? data['images'];
    final images = imageValue is List
        ? imageValue.whereType<String>().where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    final singleImage = data['imageUrl'];
    if (images.isEmpty && singleImage is String && singleImage.trim().isNotEmpty) images.add(singleImage);
    final status = _status.replaceAll('_', ' ').toUpperCase();

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
            Text('D O R', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 2),
            Text('DRESS DETAILS', style: TextStyle(fontSize: 8, color: _muted, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF211914), Color(0xFF493629), Color(0xFF785B3E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: _ink.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: SizedBox(
                      height: 240, width: double.infinity,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (_, index) => Image.network(
                          images[index], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 38)),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150, width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      color: Color(0xFF493629),
                    ),
                    child: const Icon(Icons.checkroom_rounded, color: Color(0xFFE8CEA1), size: 56),
                  ),
                Padding(
                  padding: const EdgeInsets.all(21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
                        child: Text(_connected ? 'CONNECTED DRESS' : 'DRESS SUBMISSION', style: const TextStyle(color: Color(0xFFE8CEA1), fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('${_text(data['category'], 'Dress')}  ·  ${_text(data['size'], 'Size not set')}', style: TextStyle(color: Colors.white.withOpacity(.76), fontSize: 12)),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _heroTag(status),
                        _heroTag(_modelLabel(data['preferredModel'] ?? (data['_isCreditNotePartner'] == true ? 'credit_note' : null))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Product information',
            subtitle: 'The dress details saved for this record',
            icon: Icons.inventory_2_outlined,
            children: [
              _detailRow('Dress name', name),
              _detailRow('Dress / product code', _text(data['productCode'] ?? data['code'] ?? data['productId'] ?? widget.recordId)),
              _detailRow('Category', _text(data['category'])),
              _detailRow('Size', _text(data['size'] ?? data['dressSize'])),
              _detailRow('Condition', _text(data['condition'])),
              _detailRow('Brand', _text(data['brandName'])),
              _detailRow('Submitted / connected', _date(data['createdAt'])),
              if (_text(data['description'], '').isNotEmpty) _detailRow('Description', _text(data['description'])),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Partnership & commercial terms',
            subtitle: 'Current terms and approved amounts',
            icon: Icons.handshake_outlined,
            children: [
              _detailRow('Active arrangement', _modelLabel(data['partnershipType'] ?? data['preferredModel'] ?? (data['_isCreditNotePartner'] == true ? 'credit_note' : null))),
              _detailRow('Partnership status', _text(data['partnershipStatus'] ?? data['status'], 'Not confirmed')),
              _detailRow('Rental price', _money(data['rent'] ?? data['rentalPrice'] ?? data['price'] ?? data['approvedRentalPrice'])),
              _detailRow('Security deposit', _money(data['deposit'])),
              _detailRow('Commission', data['partnerCommissionPercentage'] == null ? 'Not confirmed' : '${data['partnerCommissionPercentage']}%'),
              _detailRow('Owner revenue share', data['ownerSharePercent'] == null ? 'Not confirmed yet' : '${data['ownerSharePercent']}%'),
              _detailRow('Dor revenue share', data['dorSharePercent'] == null ? 'Not confirmed yet' : '${data['dorSharePercent']}%'),
              _detailRow('Approved credit note', _money(data['approvedCreditAmount'])),
              _detailRow('Credit added for this dress', _money(data['_creditNoteTotal'] ?? data['lastCreditNoteAmount'])),
              _detailRow('Credit-note entries', '${data['_creditNoteCount'] ?? data['creditNoteCount'] ?? 0}'),
              _detailRow('Offer accepted', data['offerAccepted'] == true ? 'Yes' : 'Not yet'),
            ],
          ),
          const SizedBox(height: 14),
          if (_text(data['adminNotes'], '').isNotEmpty)
            _sectionCard(
              title: 'Note from Dor',
              subtitle: 'Additional information from the team',
              icon: Icons.sticky_note_2_outlined,
              children: [Text(_text(data['adminNotes']), style: const TextStyle(color: _muted, height: 1.65, fontSize: 13))],
            ),
          if (!_connected) ...[
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Request progress',
              subtitle: 'Your submission status',
              icon: Icons.timeline_rounded,
              children: [
                _progressRow('Request submitted', 'Your dress details were sent to Dor.', true),
                _progressRow('Review by Dor', 'The team checks the dress and its details.', ['under_review','offer_sent','approved','rejected','completed'].contains(data['status']),),
                _progressRow('Terms and decision', data['status'] == 'rejected' ? 'This submission was not approved.' : 'Dor confirms approval and applicable terms.', ['offer_sent','approved','rejected','completed'].contains(data['status'])),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Activity & transaction log',
            subtitle: 'Recorded partnership changes and dress-specific credit entries',
            icon: Icons.history_rounded,
            children: [
              if (_productId.isEmpty)
                const Text('Activity logs become available when this submission is connected to a product.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6))
              else
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadActivity(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(color: _gold)));
                    }
                    if (snapshot.hasError) {
                      return const Text('Unable to load activity history. Check your connection and Firestore permissions.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6));
                    }
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return const Text('No saved activity entries were found for this dress yet. Older actions are not backfilled automatically.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6));
                    }
                    return Column(children: [
                      for (var i = 0; i < logs.length; i++) ...[
                        _activityItem(logs[i]),
                        if (i != logs.length - 1) const Divider(height: 22, color: _line),
                      ],
                    ]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to dress history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink, side: const BorderSide(color: _line),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
  );

  Widget _sectionCard({required String title, required String subtitle, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: _line), boxShadow: [BoxShadow(color: _ink.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: _softGold, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: _gold, size: 20)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10, height: 1.4)),
          ])),
        ]),
        const SizedBox(height: 15),
        ...children,
      ]),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))),
      const SizedBox(width: 12),
      Expanded(flex: 5, child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _progressRow(String title, String subtitle, bool complete) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: complete ? _gold : _line, size: 21),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ])),
    ]),
  );

  Widget _activityItem(Map<String, dynamic> log) {
    final kind = log['_logKind'] == 'credit' ? 'Credit added' : _actionLabel(log['action']);
    final created = log['createdAt'] ?? log['timestamp'] ?? log['performedAt'];
    final previousType = log['previousType'];
    final newType = log['newType'];
    final previousValue = log['previousValue'];
    final newValue = log['newValue'];
    String valueSummary(dynamic value) {
      if (value is Map) {
        return value.entries.map((e) => '${e.key.toString().replaceAll(RegExp(r'([A-Z])'), r' $1')}: ${e.value}').join(' · ');
      }
      return value == null ? '' : value.toString();
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 35, height: 35, decoration: BoxDecoration(color: _softGold, borderRadius: BorderRadius.circular(12)), child: Icon(log['_logKind'] == 'credit' ? Icons.account_balance_wallet_outlined : Icons.edit_note_rounded, color: _gold, size: 18)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(kind, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(_date(created), style: const TextStyle(color: _muted, fontSize: 10)),
        if (previousType != null || newType != null) ...[
          const SizedBox(height: 7),
          Text('${previousType ?? '—'}  →  ${newType ?? '—'}', style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
        if (valueSummary(previousValue).isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('Previous: ${valueSummary(previousValue)}', style: const TextStyle(color: _muted, fontSize: 10, height: 1.5)),
        ],
        if (valueSummary(newValue).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('New: ${valueSummary(newValue)}', style: const TextStyle(color: _muted, fontSize: 10, height: 1.5)),
        ],
        if (log['amount'] != null) ...[
          const SizedBox(height: 5),
          Text('Amount: ${_money(log['amount'])}', style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
        if (_text(log['reason'] ?? log['note'], '').isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('Reason: ${_text(log['reason'] ?? log['note'])}', style: const TextStyle(color: _muted, fontSize: 11, height: 1.5)),
        ],
        if (_text(log['performedBy'] ?? log['createdBy'], '').isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('By ${_text(log['performedBy'] ?? log['createdBy'])}', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ])),
    ]);
  }

  String _actionLabel(dynamic action) {
    final value = (action ?? 'Partnership updated').toString().replaceAll('_', ' ').trim();
    if (value.isEmpty) return 'Partnership updated';
    return value[0].toUpperCase() + value.substring(1);
  }
}
