import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/abstinence/abstinence_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/notebook/notebook_screen.dart';
import 'screens/partners/find_partners_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/api_client.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'utils/debug_log.dart';
import 'widgets/common_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    AppLog.e(
      'FlutterError',
      scope: 'main',
      error: details.exceptionAsString(),
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.e('uncaught', scope: 'main', error: error, stackTrace: stack);
    return true;
  };

  AppLog.i(
    'app start',
    scope: 'main',
    data: {
      'mode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
      'baseUrl': ApiClient.baseUrl,
    },
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DaziApp());
}

class DaziApp extends StatelessWidget {
  const DaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'runner2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (_) => const BootstrapScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      AppLog.d('bootstrap loading', scope: 'nav');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (!state.loggedIn) {
      if (state.needsProfile) {
        AppLog.i('route -> profile setup', scope: 'nav');
        return const ProfileSetupScreen();
      }
      AppLog.i('route -> login', scope: 'nav');
      return const LoginScreen();
    }
    AppLog.i(
      'route -> home',
      scope: 'nav',
      data: {
        'vip': state.isVip,
        'gender': state.myGender.name,
        'sessions': state.sessions.length,
        'notes': state.notes.length,
        'abstinenceStarted': state.abstinence.started,
      },
    );
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    FindPartnersScreen(),
    NotebookScreen(),
    AbstinenceScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) {
          AppLog.d('tab -> $i', scope: 'nav');
          setState(() => _index = i);
        },
      ),
    );
  }
}
