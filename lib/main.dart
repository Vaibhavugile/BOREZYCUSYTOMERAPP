import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/tenant_config.dart';
import 'package:provider/provider.dart';
import 'wishlist/wishlist_provider.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   await TenantConfig.load();

  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WishlistProvider()),
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