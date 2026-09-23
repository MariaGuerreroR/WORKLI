import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  bool _showUnreadOnly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _notificationService.refresh();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Notificaciones',
        currentIndex: 5,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notificationService.connectionFailed) {
      return AppScaffold(
        title: 'Notificaciones',
        currentIndex: 5,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final all = _notificationService.getAllNotifications();
    final unread = _notificationService.getUnreadNotifications();
    final display = _showUnreadOnly ? unread : all;

    return AppScaffold(
      title: 'Notificaciones',
      currentIndex: 5,
      actions: [
        if (unread.isNotEmpty)
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              setState(() {});
            },
            child: const Text(
              'Marcar todas',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final count = constraints.maxWidth > 700 ? 3 : 1;
                final spacing = AppDimens.spaceMd;
                final w = (constraints.maxWidth - spacing * (count - 1)) / count;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Total',
                        value: '${all.length}',
                        icon: Icons.notifications,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Sin Leer',
                        value: '${unread.length}',
                        icon: Icons.mark_email_unread,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Leídas',
                        value: '${all.length - unread.length}',
                        icon: Icons.mark_email_read,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: AppDimens.spaceXl),
              Row(
                children: [
                  _buildFilterChip('Todas', false),
                  const SizedBox(width: AppDimens.spaceSm),
                  _buildFilterChip('Sin leer (${unread.length})', true),
                ],
              ),
              const SizedBox(height: AppDimens.spaceLg),
              if (display.isEmpty)
                const EmptyState(
                  icon: Icons.notifications_off,
                  title: 'Sin notificaciones',
                  message: 'No tienes notificaciones en esta categoría.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: display.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
                  itemBuilder: (_, i) {
                    final n = display[i];
                    return NotificationCard(
                      notification: n,
                      onTap: () async {
                        await _notificationService.markAsRead(n.id);
                        setState(() {});
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isUnreadFilter) {
    final isSelected = _showUnreadOnly == isUnreadFilter;
    return GestureDetector(
      onTap: () => setState(() => _showUnreadOnly = isUnreadFilter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
