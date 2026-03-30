import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/task/presentation/screens/task_list_screen.dart';

void main() {
  runApp(const ProviderScope(child: TaskManagerApp()));
}

class TaskManagerApp extends ConsumerWidget {
  const TaskManagerApp({super.key});

  static const _primary = Color(0xFF2E6CF6);
  static const _secondary = Color(0xFF18B28C);
  static const _lightBackground = Color(0xFFF6F8FC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightText = Color(0xFF1E2430);
  static const _lightSubtle = Color(0xFF6B7382);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final baseText = ThemeData.light().textTheme;
    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: _lightText,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: _lightText,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: _lightText,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: _lightText,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        color: _lightText,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14,
        color: _lightSubtle,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    const radius12 = BorderRadius.all(Radius.circular(12));
    const radius16 = BorderRadius.all(Radius.circular(16));

    return MaterialApp(
      title: 'Task Manager App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          secondary: _secondary,
          surface: _lightSurface,
          error: const Color(0xFFE15252),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _lightBackground,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: radius16),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: radius12,
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius12,
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: radius12,
            borderSide: BorderSide(color: _primary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          primary: _primary,
          secondary: _secondary,
          surface: const Color(0xFF171D27),
          error: const Color(0xFFE15252),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F131A),
        useMaterial3: true,
      ),
      home: authState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => const LoginScreen(),
        data: (session) =>
            session == null ? const LoginScreen() : const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      TaskListScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.checklist_rtl), label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
