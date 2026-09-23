import 'package:flutter/material.dart';

import '../screens/auth/auth_screen.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_screen.dart';
import 'routes.dart';
import 'theme.dart';

class WorkliApp extends StatelessWidget {
  const WorkliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _AuthGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<bool> _session = AuthService.instance.restoreSession();
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (_authenticated || snapshot.data == true) return const DashboardScreen();
        return AuthScreen(onAuthenticated: () => setState(() => _authenticated = true));
      },
    );
  }
}
