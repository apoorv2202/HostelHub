// ─────────────────────────────────────────────
//  main.dart — App entry point & provider setup
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/main_scaffold.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HostelHubApp());
}

class HostelHubApp extends StatelessWidget {
  const HostelHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global app state (auth, requests, orders)
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // Shopping cart state
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Hostel Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            // Route to main app or login based on auth state
            home: appProvider.isLoggedIn
                ? const MainScaffold()
                : const PhoneLoginScreen(),
          );
        },
      ),
    );
  }
}
