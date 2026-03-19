import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../data/models/attachment.dart';

/// Thumbnail widget for an attachment with optional delete overlay.
class AttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final double size;

  const AttachmentThumbnail({
    super.key,
    required this.attachment,
    this.onTap,
    this.onDelete,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final thumbFile = attachment.thumbnailPath != null
        ? File(attachment.thumbnailPath!)
        : null;
    final hasThumb = thumbFile != null && thumbFile.existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasThumb
                ? Image.file(
                    thumbFile,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  )
                : const Icon(
                    Icons.image,
                    color: AppColors.textTertiary,
                    size: 32,
                  ),
          ),
          if (onDelete != null)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
