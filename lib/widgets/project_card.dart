import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final int memberCount;
  final int taskCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    this.memberCount = 0,
    this.taskCount = 0,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _statusColor {
    switch (project.status) {
      case ProjectStatus.active:
        return AppColors.success;
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.primary;
      case ProjectStatus.cancelled:
        return AppColors.error;
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
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: Text(
                      project.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (project.area != null)
                    Flexible(
                      child: Text(
                        project.area!,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(width: AppDimens.spaceSm),
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
                ],
              ),
              const SizedBox(height: AppDimens.spaceMd),
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.spaceSm),
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.spaceLg),
              Row(
                children: [
                  Text(
                    'Progreso',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progress / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSm),
                  Text(
                    '${project.progress}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceLg),
              Row(
                children: [
                  _buildInfoChip(Icons.people_outline, '$memberCount miembros'),
                  const SizedBox(width: AppDimens.spaceMd),
                  _buildInfoChip(Icons.task_alt, '$taskCount tareas'),
                  const Spacer(),
                  Text(
                    Helpers.formatCurrency(project.budget),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (project.tags.isNotEmpty) ...[
                const SizedBox(height: AppDimens.spaceMd),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.tags.take(3).map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}
