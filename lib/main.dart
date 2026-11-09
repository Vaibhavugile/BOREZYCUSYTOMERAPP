import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/tenant_config.dart';
import 'services/review_notification_navigation.dart';
import 'wishlist/wishlist_provider.dart';
import 'providers/home_provider.dart';
import 'services/user_helper.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Firebase background notification handler. Navigation must happen in the
/// foreground isolate, not from this background callback.
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message: ${message.messageId}');
}

/// Handles notification payloads that belong to the in-app Reviews tab.
void _handleNotificationTap(RemoteMessage message) {
  final intent = ReviewNotificationIntent.fromMessage(message);
  if (intent == null) {
    debugPrint('Ignoring unsupported notification: ${message.data}');
    return;
  }
  ReviewNotificationNavigation.open(intent);
}

/// App entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // Register listeners before runApp so a fast notification tap is not missed.
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  // If Android/iOS launched the app from a terminated state by tapping a
  // notification, preserve its route until MainScreen is mounted.
  final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }

  // Foreground FCM messages are not automatically displayed by the OS.
  // Show an in-app prompt; tapping its action opens the Reviews tab.
  FirebaseMessaging.onMessage.listen((message) {
    final intent = ReviewNotificationIntent.fromMessage(message);
    if (intent == null) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) {
      ReviewNotificationNavigation.open(intent);
      return;
    }

    final title = message.notification?.title ?? 'Payment received';
    final body = message.notification?.body ??
        'Your booking is ready for a review.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ReviewNotificationNavigation.open(intent);
            },
            child: const Text('Open Reviews'),
          ),
        ],
      ),
    );
  });

  await TenantConfig.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Main application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const StartupScreen(),
    );
  }
}

/// Checks the saved login and initializes homepage data before MainScreen.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final Future<bool> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  Future<bool> _initializeApp() async {
    try {
      debugPrint('STARTUP: Checking saved login...');
      final phone = await UserHelper.getPhone();

      if (phone == null || phone.trim().isEmpty) {
        debugPrint('STARTUP: No saved login found.');
        return false;
      }

      debugPrint('STARTUP: Logged-in user found: $phone');

      final homeProvider = Provider.of<HomeProvider>(
        context,
        listen: false,
      );

      debugPrint('STARTUP: Loading homepage data...');
      await homeProvider.loadHomeData();
      debugPrint('STARTUP: Homepage data loaded successfully.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('STARTUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF8F5),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB68A52),
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
