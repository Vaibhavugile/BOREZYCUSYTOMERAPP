import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'tenant_config.dart';
import 'user_helper.dart';

class FCMService {
  static const String _tag = '[FCM-DIAGNOSTIC]';
  static const int _maxVisibleLogs = 100;

  /// The OTP screen listens to this notifier to show diagnostic logs
  /// inside the app, including in TestFlight release builds.
  static final ValueNotifier<List<String>> diagnosticLogs =
      ValueNotifier<List<String>>(<String>[]);

  static bool _refreshListenerRegistered = false;

  static void clearDiagnosticLogs() {
    diagnosticLogs.value = <String>[];
    _log('Diagnostic log cleared by user.');
  }

  static void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '$timestamp $message';

    debugPrint('$_tag $line');

    final updated = List<String>.from(diagnosticLogs.value)..add(line);
    if (updated.length > _maxVisibleLogs) {
      updated.removeRange(0, updated.length - _maxVisibleLogs);
    }
    diagnosticLogs.value = updated;
  }

  static void _logError(
    String step,
    Object error,
    StackTrace stackTrace,
  ) {
    _log('FAILED STEP: $step');
    _log('ERROR TYPE: ${error.runtimeType}');
    _log('ERROR: $error');

    if (error is FirebaseException) {
      _log('FIREBASE PLUGIN: ${error.plugin}');
      _log('FIREBASE ERROR CODE: ${error.code}');
      _log('FIREBASE ERROR MESSAGE: ${error.message ?? "(none)"}');
    }

    // Show stack frames as visible logs, useful when no Xcode console exists.
    for (final line in stackTrace.toString().split('\n').take(12)) {
      if (line.trim().isNotEmpty) _log('STACK: $line');
    }
  }

  /// Initializes notifications and saves the FCM token.
  ///
  /// Failures are captured and displayed, rather than thrown into the OTP
  /// flow. This is diagnostic handling; it does not itself fix APNs signing.
  static Future<void> setupFCM() async {
    var step = 'Starting FCM setup';

    _log('========================================');
    _log('FCM SETUP STARTED');
    _log('Platform: ${Platform.operatingSystem}');
    _log('Debug mode: $kDebugMode');

    try {
      step = 'Checking Firebase initialization';
      _log('STEP: $step');
      _log('Firebase apps: ${Firebase.apps.map((app) => app.name).join(', ')}');

      final messaging = FirebaseMessaging.instance;

      step = 'Requesting notification permission';
      _log('STEP: $step');

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _log('Permission status: ${settings.authorizationStatus}');
      _log('Alert setting: ${settings.alert}');
      _log('Badge setting: ${settings.badge}');
      _log('Sound setting: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('Notifications are denied by the user. FCM setup stopped.');
        return;
      }

      if (Platform.isIOS) {
        step = 'Waiting for the iOS APNs token';
        _log('STEP: $step');

        String? apnsToken;

        for (var attempt = 1; attempt <= 30; attempt++) {
          try {
            apnsToken = await messaging.getAPNSToken();

            if (apnsToken != null && apnsToken.isNotEmpty) {
              _log('APNs token RECEIVED on attempt $attempt/30.');
              _log('APNs token length: ${apnsToken.length}; value hidden.');
              break;
            }

            _log('APNs token is NULL (attempt $attempt/30).');
          } catch (error, stackTrace) {
            _logError('Reading APNs token, attempt $attempt/30', error, stackTrace);
          }

          if (attempt < 30) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          _log('APNs token NOT received after 30 seconds.');
          _log('Check signed app aps-environment entitlement, Apple capability,');
          _log('provisioning profile, and device APNs registration.');
          _log('Skipping FCM token request because APNs is unavailable.');
          return;
        }
      } else {
        _log('Non-iOS platform: APNs check skipped.');
      }

      step = 'Requesting FCM token';
      _log('STEP: $step');

      final fcmToken = await messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        _log('Firebase returned a NULL or empty FCM token.');
        return;
      }

      _log('FCM token RECEIVED. Length: ${fcmToken.length}; value hidden.');

      step = 'Reading customer phone';
      _log('STEP: $step');

      final phone = await UserHelper.getPhone();

      if (phone == null || phone.trim().isEmpty) {
        _log('No customer phone found; token cannot be saved.');
        return;
      }

      step = 'Reading tenant branch configuration';
      _log('STEP: $step');

      final branch = TenantConfig.branchCode;

      if (branch.trim().isEmpty) {
        _log('Branch code is empty; token cannot be saved.');
        return;
      }

      _log('Branch code: $branch');

      step = 'Saving FCM token to customer profile';
      _log('STEP: $step');

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(branch)
          .collection('users')
          .doc(phone)
          .set(
        {
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
        },
        SetOptions(merge: true),
      );

      _log('FCM token saved to Firestore successfully.');

      step = 'Subscribing to branch notification topic';
      _log('STEP: $step');

      final topic = 'branch_$branch';
      await messaging.subscribeToTopic(topic);
      _log('Subscribed to topic: $topic');

      if (!_refreshListenerRegistered) {
        step = 'Registering FCM token refresh listener';
        _log('STEP: $step');

        _refreshListenerRegistered = true;

        messaging.onTokenRefresh.listen(
          (newToken) async {
            try {
              _log('FCM token refresh event received.');
              _log('New token length: ${newToken.length}; value hidden.');

              final refreshedPhone = await UserHelper.getPhone();
              if (refreshedPhone == null || refreshedPhone.trim().isEmpty) {
                _log('Cannot save refreshed token: customer phone missing.');
                return;
              }

              final refreshedBranch = TenantConfig.branchCode;

              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(refreshedBranch)
                  .collection('users')
                  .doc(refreshedPhone)
                  .set(
                {
                  'fcmToken': newToken,
                  'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                  'platform': Platform.operatingSystem,
                },
                SetOptions(merge: true),
              );

              _log('Refreshed FCM token saved successfully.');
            } catch (error, stackTrace) {
              _logError('Saving refreshed FCM token', error, stackTrace);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _logError('FCM token refresh stream', error, stackTrace);
          },
        );
      }

      _log('FCM SETUP COMPLETED SUCCESSFULLY');
      _log('========================================');
    } catch (error, stackTrace) {
      _logError(step, error, stackTrace);
      _log('FCM setup failed; login should continue.');
    }
  }
}
