import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'app_sidebar.dart';

class BottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final int unreadNotifications;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.unreadNotifications = 0,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  static const List<NavItem> _items = [
    NavItem(label: 'Panel', icon: Icons.dashboard_outlined, route: '/', index: 0),
    NavItem(label: 'Proyectos', icon: Icons.folder_outlined, route: '/projects', index: 1),
    NavItem(label: 'Tareas', icon: Icons.checklist_rtl, route: '/tasks', index: 2),
    NavItem(label: 'Chat', icon: Icons.chat_bubble_outline, route: '/chat', index: 4),
    NavItem(label: 'Perfil', icon: Icons.person_outline, route: '/profile', index: 8),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) => _buildItem(item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(NavItem item) {
    final isSelected = widget.selectedIndex == item.index;
    final showBadge = item.label == 'Notif' && widget.unreadNotifications > 0;

    return GestureDetector(
      onTap: () => widget.onNavigate(item.index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              if (showBadge)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.unreadNotifications}',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
