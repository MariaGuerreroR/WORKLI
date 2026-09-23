import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final String? assigneeName;
  final String? projectTitle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<TaskStatus>? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.assigneeName,
    this.projectTitle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChanged,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.error;
      case TaskPriority.high:
        return AppColors.accent;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.textMuted;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.todo:
        return AppColors.textMuted;
      case TaskStatus.inProgress:
        return AppColors.info;
      case TaskStatus.review:
        return AppColors.warning;
      case TaskStatus.done:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            border: Border.all(
              color: task.isOverdue ? AppColors.error.withOpacity(0.3) : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              GestureDetector(
                onTap: onStatusChanged != null ? () => _cycleStatus() : null,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.status == TaskStatus.done ? _statusColor : Colors.transparent,
                    border: Border.all(
                      color: task.status == TaskStatus.done ? _statusColor : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: task.status == TaskStatus.done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        decoration: task.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimens.spaceSm),
                    Wrap(
                      spacing: AppDimens.spaceSm,
                      runSpacing: 4,
                      children: [
                        _buildChip(task.status.label, _statusColor),
                        _buildChip(task.priority.label, _priorityColor),
                        if (projectTitle != null)
                          _buildChip(Helpers.truncate(projectTitle!, 20), AppColors.textMuted),
                      ],
                    ),
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.spaceSm),
                      Row(
                        children: [
                          Text(
                            '${task.completedSubtasks}/${task.subtasks.length} subtareas',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: AppDimens.spaceSm),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: task.subtaskProgress,
                                minHeight: 3,
                                backgroundColor: AppColors.border,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimens.spaceSm),
                    Row(
                      children: [
                        if (assigneeName != null) ...[
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(
                              Helpers.initialsFromName(assigneeName!),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            assigneeName!,
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                        const Spacer(),
                        if (task.dueDate != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: task.isOverdue ? AppColors.error : AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            Helpers.daysUntil(task.dueDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                              color: task.isOverdue ? AppColors.error : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _cycleStatus() {
    if (onStatusChanged == null) return;
    final order = TaskStatus.values;
    final nextIndex = (order.indexOf(task.status) + 1) % order.length;
    onStatusChanged!(order[nextIndex]);
  }
}
