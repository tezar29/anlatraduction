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
        ),
        voiceService: VoiceService(),
        backend: BackendService(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api.anla.mybestsejour.com',
          ),
          accessToken: const String.fromEnvironment('ACCESS_TOKEN'),
        ),
      ),
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

  Future<void> _selectTab(int index) async {
    if (index == _index) return;
    final state = context.read<AppState>();
    // IndexedStack conserve les écrans montés : dispose() n'est donc pas
    // appelé lors du passage d'un onglet à l'autre. Il faut couper
    // explicitement micro et TTS avant de changer de mode.
    await state.stopAllAudio();
    if (!mounted) return;
    state.setConversationScreenActive(index == 2);
    setState(() => _index = index);
  }

  static const _screens = [
    TranslateScreen(),
    HistoryScreen(),
    ConversationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _index, 
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.translate_outlined,
                  activeIcon: Icons.translate_rounded,
                  label: 'Traduire',
                  active: _index == 0,
                  onTap: () => _selectTab(0),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Historique',
                  active: _index == 1,
                  onTap: () => _selectTab(1),
                ),
                _NavItem(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people_rounded,
                  label: 'Face-à-face',
                  active: _index == 2,
                  onTap: () => _selectTab(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Réglages',
                  active: _index == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1D3480),
                      Color(0xFF2E4CA0),
                    ],
                  )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D3480).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active ? Colors.white : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active ? Colors.white : colors.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
