import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/reservation/reservation_screen.dart';
import 'screens/profile/profile_screen.dart'; // contains ProfileScreen now
import 'screens/profile/edit_profile_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MainApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Log and continue in debug/tests so widget tests don't fail, but surface the issue.
    debugPrint('Firebase initialization failed: $e');
    assert(() {
      debugPrint('Firebase init skipped in debug/testing environment.');
      return true;
    }());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fixedLightShadTheme = ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadSlateColorScheme.light(),
    );

    return ShadApp.custom(
      theme: fixedLightShadTheme,
      darkTheme: fixedLightShadTheme,
      themeMode: ThemeMode.light,
      appBuilder: (context) => MaterialApp(
        title: 'RISA',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/login',
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) {
            final rawArgs = ModalRoute.of(context)?.settings.arguments;
            final args = rawArgs is Map ? rawArgs : const <String, dynamic>{};
            return MainScreen(
              initialEmail: args['email']?.toString(),
              initialName: args['name']?.toString(),
              initialRole: args['role']?.toString(),
              initialUserType: args['userType']?.toString(),
              initialAvatarPath: args['avatarPath']?.toString(),
            );
          },
          '/forgotPassword': (context) => const ForgotPasswordScreen(),
          '/editProfile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialName;
  final String? initialRole;
  final String? initialUserType;
  final String? initialAvatarPath;
  final int? initialIndex;
  final bool showTimelinePreview;

  const MainScreen({
    super.key,
    this.initialEmail,
    this.initialName,
    this.initialRole,
    this.initialUserType,
    this.initialAvatarPath,
    this.initialIndex,
    this.showTimelinePreview = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _tabs;

  void _openTimeline() {
    _onTap(0);
  }

  void _openManagerTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialEmail: widget.initialEmail,
          initialName: widget.initialName,
          initialRole: widget.initialRole,
          initialUserType: widget.initialUserType,
          initialAvatarPath: widget.initialAvatarPath,
          initialIndex: 0,
          showTimelinePreview: true,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final normalizedRole = (widget.initialRole ?? '').toLowerCase();
    final isManager =
        normalizedRole == 'admin' ||
        normalizedRole == 'librarian' ||
        normalizedRole == 'over all admin' ||
        normalizedRole == 'super admin';
    _currentIndex = widget.initialIndex ?? 0;

    _tabs = [
      if (isManager && !widget.showTimelinePreview)
        DashboardScreen(
          role: widget.initialRole ?? 'Librarian',
          currentEmail: widget.initialEmail,
          currentName: widget.initialName,
          onLogoPressed: _openManagerTimeline,
          onProfilePressed: () => _onTap(4),
        )
      else
        HomeScreen(
          userEmail: widget.initialEmail,
          userName: widget.initialName,
          userRole: widget.initialRole,
          onProfilePressed: () => _onTap(4),
          onLogoPressed: _openTimeline,
        ),
      ChatbotScreen(onProfilePressed: () => _onTap(4)),
      NotificationsScreen(
        userRole: widget.initialRole ?? '',
        userEmail: widget.initialEmail ?? '',
        userType: widget.initialUserType,
        onLogoPressed: _openTimeline,
        onGoToReservations: () => _onTap(3),
        onGoToAnnouncements: isManager
            ? (widget.showTimelinePreview
                  ? _openTimeline
                  : _openManagerTimeline)
            : _openTimeline,
        onProfilePressed: () => _onTap(4),
      ),
      ReservationsScreen(
        userRole: widget.initialRole ?? '',
        userName: widget.initialName,
        userEmail: widget.initialEmail,
        userType: widget.initialUserType,
        onLogoPressed: _openTimeline,
        onProfilePressed: () => _onTap(4),
      ),
      ProfileScreen(
        initialEmail: widget.initialEmail,
        initialName: widget.initialName,
        initialRole: widget.initialRole,
        initialUserType: widget.initialUserType,
        initialAvatarPath: widget.initialAvatarPath,
      ),
    ];
  }

  void _onTap(int index) {
    if (widget.showTimelinePreview && index == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex < 4 ? _currentIndex : 0,
        onTap: _onTap,
      ),
    );
  }
}
