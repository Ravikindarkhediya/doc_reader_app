import 'package:flutter/material.dart';
import '../../controller/theme_controller.dart';
import '../../data/model/document_model.dart';

class DocCard extends StatelessWidget {
  final DocumentModel doc;
  final bool isHorizontal;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const DocCard({
    super.key,
    required this.doc,
    required this.isHorizontal,
    required this.onTap,
    required this.onLike,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    if (isHorizontal) return _buildHorizontal(c);
    return _buildVertical(c);
  }

  Widget _buildHorizontal(AppColorExtension c) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _extIcon(doc.extension, c),
                _likeBtn(c),
              ],
            ),
            const Spacer(),
            Text(
              doc.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doc.readTimeEstimate,
              style: TextStyle(fontSize: 11, color: c.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVertical(AppColorExtension c) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child:Row(
          children: [
            _extIcon(doc.extension, c),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Wrap(
                    spacing: 4,
                    children: [
                      Text(
                        doc.extension.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "• ${doc.readTimeEstimate}",
                        style: TextStyle(fontSize: 11, color: c.textLight),
                      ),
                      if (doc.isBookmarked)
                        Icon(Icons.bookmark_rounded, size: 12, color: c.primary),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _likeBtn(c),
                const SizedBox(width: 4),
                _menuBtn(c),
              ],
            ),
          ],
        )
      ),
    );
  }

  Widget _extIcon(String ext, AppColorExtension c) {
    Color iconColor;
    IconData icon;

    switch (ext) {
      case 'pdf':
        iconColor = const Color(0xFFE53E3E);
        icon = Icons.picture_as_pdf_rounded;
        break;
      case 'docx':
      case 'doc':
        iconColor = const Color(0xFF2B6CB0);
        icon = Icons.description_rounded;
        break;
      case 'txt':
        iconColor = const Color(0xFF38A169);
        icon = Icons.text_snippet_rounded;
        break;
      default:
        iconColor = c.primary;
        icon = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _likeBtn(AppColorExtension c) {
    return GestureDetector(
      onTap: onLike,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          key: ValueKey(doc.isLiked),
          doc.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: doc.isLiked ? Colors.red : c.textLight,
          size: 20,
        ),
      ),
    );
  }

  Widget _menuBtn(AppColorExtension c) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: c.textLight, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) {
        if (val == 'rename') onRename();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename', child: Row(
          children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text("Rename")],
        )),
        const PopupMenuItem(value: 'delete', child: Row(
          children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))],
        )),
      ],
    );
  }
}
