import 'dart:async';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<_FirebaseServices> _servicesFuture = _initializeApp();

  Future<_FirebaseServices> _initializeApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    final fcmService = FcmService();
    final remoteConfigService = RemoteConfigService();

    unawaited(_initializeFirebaseServices(
      fcmService: fcmService,
      remoteConfigService: remoteConfigService,
    ));

    return _FirebaseServices(
      fcmService: fcmService,
      remoteConfigService: remoteConfigService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FirebaseServices>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return JournalTrendApp(
            fcmService: snapshot.data!.fcmService,
            remoteConfigService: snapshot.data!.remoteConfigService,
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Firebase initialization failed:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class _FirebaseServices {
  final FcmService fcmService;
  final RemoteConfigService remoteConfigService;

  const _FirebaseServices({
    required this.fcmService,
    required this.remoteConfigService,
  });
}

Future<void> _initializeFirebaseServices({
  required FcmService fcmService,
  required RemoteConfigService remoteConfigService,
}) async {
  try {
    await remoteConfigService.initialize();
    await fcmService.initialize();
  } catch (e) {
    debugPrint('Firebase services initialization failed: $e');
  }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          initialData: AuthService().currentUser,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const MainShellScreen();
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}