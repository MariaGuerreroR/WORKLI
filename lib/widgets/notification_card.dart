import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.taskAssigned:
        return AppColors.info;
      case NotificationType.deadlineReminder:
        return AppColors.warning;
      case NotificationType.documentShared:
        return AppColors.primary;
      case NotificationType.messageReceived:
        return AppColors.secondary;
      case NotificationType.projectUpdate:
        return AppColors.success;
      case NotificationType.mention:
        return AppColors.accent;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.taskAssigned:
        return Icons.assignment_outlined;
      case NotificationType.deadlineReminder:
        return Icons.schedule_outlined;
      case NotificationType.documentShared:
        return Icons.file_present_outlined;
      case NotificationType.messageReceived:
        return Icons.chat_bubble_outline;
      case NotificationType.projectUpdate:
        return Icons.update;
      case NotificationType.mention:
        return Icons.alternate_email;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? AppColors.surface : _typeColor.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification.type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _typeColor,
                          ),
                        ),
                        const Spacer(),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Helpers.timeAgo(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
