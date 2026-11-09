import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Data carried by a payment-owner notification.
@immutable
class ReviewNotificationIntent {
  const ReviewNotificationIntent({
    required this.branchCode,
    this.paymentId = '',
    this.receiptNumber = '',
  });

  final String branchCode;
  final String paymentId;
  final String receiptNumber;

  bool get hasBooking =>
      paymentId.trim().isNotEmpty || receiptNumber.trim().isNotEmpty;

  String get identity => '$branchCode|$paymentId|$receiptNumber';

  static ReviewNotificationIntent? fromMessage(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString();

    if (type != 'branch_return_review' &&
        type != 'branch_payment' &&
        type != 'branch_payment_test') {
      return null;
    }

    final branchCode = (data['branchCode'] ?? '').toString().trim();
    if (branchCode.isEmpty) return null;

    return ReviewNotificationIntent(
      branchCode: branchCode,
      paymentId: (data['paymentId'] ?? '').toString().trim(),
      receiptNumber: (data['receiptNumber'] ?? '').toString().trim(),
    );
  }
}

/// Holds notification navigation until MainScreen is ready.
class ReviewNotificationNavigation {
  ReviewNotificationNavigation._();

  static final ValueNotifier<ReviewNotificationIntent?> pending =
      ValueNotifier<ReviewNotificationIntent?>(null);

  static void open(ReviewNotificationIntent intent) {
    pending.value = intent;
  }
}
