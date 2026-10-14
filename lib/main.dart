import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent local storage for token & session
  final sharedPreferences = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(sharedPreferences);

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const JMDLogisticsApp(),
    ),
  );
}

class JMDLogisticsApp extends StatelessWidget {
  const JMDLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
