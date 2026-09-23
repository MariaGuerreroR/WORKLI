import 'package:flutter/material.dart';

import '../utils/constants.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final int index;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.index,
  });
}

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final int unreadNotifications;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.unreadNotifications = 0,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isCollapsed = false;

  static const List<NavItem> _items = [
    NavItem(label: AppStrings.dashboard, icon: Icons.dashboard_outlined, route: '/', index: 0),
    NavItem(label: AppStrings.projects, icon: Icons.folder_outlined, route: '/projects', index: 1),
    NavItem(label: AppStrings.tasks, icon: Icons.checklist_rtl_outlined, route: '/tasks', index: 2),
    NavItem(label: AppStrings.documents, icon: Icons.description_outlined, route: '/documents', index: 3),
    NavItem(label: AppStrings.chat, icon: Icons.chat_bubble_outline, route: '/chat', index: 4),
    NavItem(label: AppStrings.notifications, icon: Icons.notifications_none, route: '/notifications', index: 5),
    NavItem(label: AppStrings.reports, icon: Icons.assessment_outlined, route: '/reports', index: 6),
    NavItem(label: AppStrings.analytics, icon: Icons.insights_outlined, route: '/analytics', index: 7),
    NavItem(label: AppStrings.profile, icon: Icons.person_outline, route: '/profile', index: 8),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _isCollapsed ? AppDimens.sidebarCollapsedWidth : AppDimens.sidebarWidth;

    return AnimatedContainer(
      duration: AppAnimations.normal,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSm),
              itemCount: _items.length,
              itemBuilder: (_, i) => _buildNavItem(_items[i]),
            ),
          ),
          _buildCollapseToggle(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMd,
        vertical: AppDimens.spaceLg,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: const Icon(Icons.science, color: Colors.white, size: 20),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: AppDimens.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Investigación',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isSelected = widget.selectedIndex == item.index;
    final showBadge = item.index == 5 && widget.unreadNotifications > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavigate(item.index),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceSm,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceMd,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: AppDimens.spaceMd),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.unreadNotifications}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseToggle() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spaceSm),
      child: IconButton(
        onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
        icon: Icon(
          _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
