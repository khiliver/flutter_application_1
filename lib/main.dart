import 'package:flutter/material.dart';
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

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      appBuilder: (context) => MaterialApp(
        title: 'RISA',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, String>?;
            return MainScreen(
              initialEmail: args?['email'],
              initialName: args?['name'],
              initialRole: args?['role'],
              initialUserType: args?['userType'],
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

  const MainScreen({
    super.key,
    this.initialEmail,
    this.initialName,
    this.initialRole,
    this.initialUserType,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    final normalizedRole = (widget.initialRole ?? '').toLowerCase();
    final isManager =
        normalizedRole == 'admin' ||
        normalizedRole == 'librarian' ||
        normalizedRole == 'super admin';

    _tabs = [
      if (isManager)
        DashboardScreen(role: widget.initialRole ?? 'Librarian')
      else
        const HomeScreen(),
      const ChatbotScreen(),
      NotificationsScreen(
        userRole: widget.initialRole ?? '',
        userEmail: widget.initialEmail ?? '',
        onGoToReservations: () => _onTap(3),
      ),
      ReservationsScreen(
        userRole: widget.initialRole ?? '',
        userName: widget.initialName,
        userEmail: widget.initialEmail,
      ),
      ProfileScreen(
        initialEmail: widget.initialEmail,
        initialName: widget.initialName,
        initialRole: widget.initialRole,
        initialUserType: widget.initialUserType,
      ),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
