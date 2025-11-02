import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: FocusApp()));
}

class FocusApp extends ConsumerWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
        return MaterialApp.router(
          title: '專注番茄',
          theme: lightColorScheme != null 
              ? ThemeData(
                  useMaterial3: true,
                  colorScheme: lightColorScheme.harmonized(),
                  fontFamily: 'Roboto',
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                    },
                  ),
                )
              : AppTheme(Theme.of(context).textTheme).light().copyWith(
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                    },
                  ),
                ),
          darkTheme: darkColorScheme != null
              ? ThemeData(
                  useMaterial3: true,
                  colorScheme: darkColorScheme.harmonized(),
                  fontFamily: 'Roboto',
                  brightness: Brightness.dark,
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                    },
                  ),
                )
              : AppTheme(Theme.of(context).textTheme).dark().copyWith(
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                    },
                  ),
                ), 
          themeMode: themeMode,
          routerConfig: _router,
          locale: const Locale('zh', 'TW'),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/timer',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/timer',
          builder: (context, state) => const TimerScreen(),
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
