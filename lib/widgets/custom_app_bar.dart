
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Zepto-like top bar with title and an optional profile/action icon.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final Widget? action;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onProfileTap,
    this.action,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      titleSpacing: 16,
      title: Text(title, style: AppTextStyles.h2),
      actions: [
        if (action != null) Padding(padding: const EdgeInsets.only(right: 8), child: action),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.person, color: AppColors.text, size: 22),
          ),
        ),
      ],
    );
  }
}
