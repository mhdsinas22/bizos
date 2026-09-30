import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/attachments/presentation/widgets/attachment_picker.dart';
import 'package:bizos/features/attachments/presentation/widgets/full_screen_image_viewer.dart';

class AttachmentPreview extends StatelessWidget {
  final File file;
  final String fileName;
  final VoidCallback onRemove;
  final Function(File newFile, String newFileName) onReplace;

  const AttachmentPreview({
    super.key,
    required this.file,
    required this.fileName,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Image Thumbnail
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                    imageFile: file,
                    title: fileName,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // File Name & Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Receipt Attached',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons: Replace & Remove
          IconButton(
            tooltip: 'Replace image',
            icon: const Icon(Icons.sync_alt, size: 20),
            onPressed: () {
              // Trigger replace selection
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AttachmentPicker(
                    onImagePicked: (newFile, newName) {
                      Navigator.pop(sheetContext);
                      onReplace(newFile, newName);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Remove image',
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
