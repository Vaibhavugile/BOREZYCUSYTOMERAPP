import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/tenant_config.dart';
import 'package:provider/provider.dart';
import 'wishlist/wishlist_provider.dart';
import 'providers/home_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔥 INIT BACKGROUND HANDLER
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  await TenantConfig.load();

  runApp(
    MultiProvider(
      providers: [

        /// 🔥 HOME DATA
        ChangeNotifierProvider(
          create: (_) => HomeProvider(),
        ),

        /// 🔥 WISHLIST
        ChangeNotifierProvider(
          create: (_) => WishlistProvider(),
        ),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const LoginScreen(),

    );

  }

}