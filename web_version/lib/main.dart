import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './core/role_guard.dart';
import './core/theme_provider.dart';
import './services/booking_realtime_service.dart';
import './services/connectivity_service.dart';
import './services/notification_service.dart';
import './services/quotation_realtime_service.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize ConnectivityService
  await ConnectivityService.instance.initialize();

  // Initialize NotificationService
  await NotificationService.instance.initialize();

  // Initialize ThemeProvider
  await ThemeProvider.instance.initialize();

  // Start quotation real-time listener (fires after auth is available)
  SupabaseService.instance.authStateChanges.listen((authState) {
    if (authState.event == AuthChangeEvent.signedIn) {
      QuotationRealtimeService.instance.startListening();
      BookingRealtimeService.instance.startListening();
    } else if (authState.event == AuthChangeEvent.signedOut) {
      QuotationRealtimeService.instance.stopListening();
      BookingRealtimeService.instance.stopListening();
      // Clear cached role on sign-out to prevent stale role access
      clearCachedRole();
    }
  });

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  if (kIsWeb) {
    runApp(MyApp());
  } else {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    runApp(MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeProvider.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'LocalConnect',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeProvider.instance.themeMode,
          navigatorKey: NotificationService.navigatorKey,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            double textScale = 1.0;
            if (kIsWeb && mediaQuery.size.width > 600) {
              textScale = 420.0 / mediaQuery.size.width;
              if (textScale < 0.25) textScale = 0.25;
            }
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}

