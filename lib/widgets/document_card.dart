import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final String? uploaderName;
  final String? projectTitle;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.uploaderName,
    this.projectTitle,
    this.onTap,
  });

  Color get _typeColor {
    switch (document.type) {
      case DocumentType.paper:
        return AppColors.error;
      case DocumentType.dataset:
        return AppColors.info;
      case DocumentType.presentation:
        return AppColors.secondary;
      case DocumentType.report:
        return AppColors.primary;
      case DocumentType.protocol:
        return AppColors.success;
      case DocumentType.other:
        return AppColors.textMuted;
    }
  }

  IconData get _typeIcon {
    switch (document.type) {
      case DocumentType.paper:
        return Icons.article_outlined;
      case DocumentType.dataset:
        return Icons.dataset_outlined;
      case DocumentType.presentation:
        return Icons.slideshow_outlined;
      case DocumentType.report:
        return Icons.assessment_outlined;
      case DocumentType.protocol:
        return Icons.menu_book_outlined;
      case DocumentType.other:
        return Icons.description_outlined;
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
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 24),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            document.type.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          document.sizeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (document.version != null)
                          Text(
                            'v${document.version}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          uploaderName ?? 'Desconocido',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppDimens.spaceSm),
                        Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          Helpers.timeAgo(document.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
