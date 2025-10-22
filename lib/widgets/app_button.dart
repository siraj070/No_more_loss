
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

enum AppButtonType { primary, outline, tonal, icon }

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool fullWidth;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsets padding;
  final double radius;

  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.fullWidth = true,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        if (label != null) Flexible(child: Text(label!, style: AppTextStyles.button)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );

    switch (type) {
      case AppButtonType.primary:
        return _PrimaryButton(
          onPressed: onPressed,
          fullWidth: fullWidth,
          radius: radius,
          padding: padding,
          child: child,
        );
      case AppButtonType.outline:
        return _OutlineButton(
          onPressed: onPressed,
          fullWidth: fullWidth,
          radius: radius,
          padding: padding,
          child: child,
        );
      case AppButtonType.tonal:
        return _TonalButton(
          onPressed: onPressed,
          fullWidth: fullWidth,
          radius: radius,
          padding: padding,
          child: child,
        );
      case AppButtonType.icon:
        return _IconButtonShell(
          onPressed: onPressed,
          radius: radius,
          padding: padding,
          child: child,
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsets padding;
  final double radius;

  const _PrimaryButton({
    required this.child,
    required this.onPressed,
    required this.fullWidth,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppDecorations.softShadow,
      ),
      child: Center(child: child),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsets padding;
  final double radius;

  const _OutlineButton({
    required this.child,
    required this.onPressed,
    required this.fullWidth,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.primary, width: 1.4),
      ),
      child: Center(child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.primary),
        child: child,
      )),
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }
}

class _TonalButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsets padding;
  final double radius;

  const _TonalButton({
    required this.child,
    required this.onPressed,
    required this.fullWidth,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
        child: child,
      )),
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }
}

class _IconButtonShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final double radius;

  const _IconButtonShell({
    required this.child,
    required this.onPressed,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow,
      ),
      child: Center(child: child),
    );
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: button,
      ),
    );
  }
}
