import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase/firebase_options.dart';
import 'firebase/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/journals_viewmodel.dart';
import 'viewmodels/keywords_viewmodel.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';

import 'firebase/fcm_service.dart';
import 'firebase/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final fcmService = FcmService();
  final remoteConfigService = RemoteConfigService();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Initialize Services
    await remoteConfigService.initialize();
    await fcmService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(JournalTrendApp(
    fcmService: fcmService,
    remoteConfigService: remoteConfigService,
  ));
}

class JournalTrendApp extends StatelessWidget {
  final FcmService fcmService;
  final RemoteConfigService remoteConfigService;

  const JournalTrendApp({
    super.key,
    required this.fcmService,
    required this.remoteConfigService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => KeywordsViewModel(),
        ),
        ChangeNotifierProvider.value(
          value: fcmService,
        ),
        Provider.value(
          value: remoteConfigService,
        ),
      ],
      child: MaterialApp(
        title: 'Lab03 - PhuNG',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasData) {
              return const MainShellScreen();
            }
            return const LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
