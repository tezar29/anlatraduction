import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/translate_screen.dart';
import 'services/translation_service.dart';
import 'services/backend_service.dart';
import 'services/voice_service.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TranslationApp());
}

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        translationService: ApiTranslationService(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api.anla.mybestsejour.com',
          ),
          accessToken: const String.fromEnvironment('ACCESS_TOKEN'),
        ),
        voiceService: VoiceService(),
        backend: BackendService(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api.anla.mybestsejour.com',
          ),
          accessToken: const String.fromEnvironment('ACCESS_TOKEN'),
        ),
      )
        ..loadHistory()
        ..loadThemePreference(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Traducteur',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final destination = state.isAuthenticated ? const RootNav() : const LoginScreen();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : KeyedSubtree(key: const ValueKey('content'), child: destination),
    );
  }
}

/// Coquille de navigation principale : bascule entre Traducteur,
/// Historique et Réglages via une barre de navigation en bas.
class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const _screens = [
    TranslateScreen(),
    HistoryScreen(),
    ConversationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: Icon(Icons.translate_rounded),
            label: 'Traduire',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Face-à-face',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}