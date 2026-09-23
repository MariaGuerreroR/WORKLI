import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/bottom_navigation.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
    this.actions,
  });

  static final _notificationService = NotificationService();

  void _navigate(BuildContext context, int index) {
    final routes = [
      AppRoutes.dashboard,
      AppRoutes.projects,
      AppRoutes.tasks,
      AppRoutes.documents,
      AppRoutes.chat,
      AppRoutes.notifications,
      AppRoutes.reports,
      AppRoutes.analytics,
      AppRoutes.profile,
    ];
    if (index < routes.length && index != currentIndex) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final unread = _notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                selectedIndex: currentIndex,
                onNavigate: (i) {
                  Navigator.pop(context);
                  _navigate(context, i);
                },
                unreadNotifications: unread,
              ),
            ),
      body: isDesktop
          ? Row(
              children: [
                AppSidebar(
                  selectedIndex: currentIndex,
                  onNavigate: (i) => _navigate(context, i),
                  unreadNotifications: unread,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigation(
              selectedIndex: currentIndex,
              onNavigate: (i) => _navigate(context, i),
              unreadNotifications: unread,
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}
