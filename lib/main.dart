// ─────────────────────────────────────────────
//  main.dart — App entry point & provider setup
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/verification_states_screens.dart';
import 'screens/admin_dashboard.dart';
import 'screens/canteen_dashboard.dart';
import 'screens/cleaning_dashboard.dart';
import 'screens/maintenance_dashboard.dart';
import 'screens/main_scaffold.dart';
import 'models/user.dart';
import 'models/user_model.dart';
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
          Widget homeScreen;

          if (appProvider.isLoggedIn && appProvider.user != null) {
            final status = appProvider.user!.verificationStatus;
            
            if (status == VerificationStatus.pending) {
              homeScreen = PendingVerificationScreen(user: appProvider.user!);
            } else if (status == VerificationStatus.rejected) {
              homeScreen = RejectedVerificationScreen(user: appProvider.user!);
            } else {
              switch (appProvider.user!.role) {
                case UserRole.student:
                  homeScreen = const MainScaffold();
                  break;
                case UserRole.warden:
                  homeScreen = AdminDashboardScreen(user: appProvider.user!);
                  break;
                case UserRole.cleaning:
                  homeScreen = CleaningDashboardScreen(user: appProvider.user!);
                  break;
                case UserRole.canteen:
                  homeScreen = CanteenDashboardScreen(user: appProvider.user!);
                  break;
                case UserRole.maintenance:
                  homeScreen = MaintenanceDashboardScreen(user: appProvider.user!);
                  break;
              }
            }
          } else {
            homeScreen = const RoleSelectionScreen();
          }

          return MaterialApp(
            title: 'Hostel Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: homeScreen,
          );
        },
      ),
    );
  }
}
