import 'package:flutter/material.dart';
import 'package:satr/core/constants/app_constants.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final primaryColor = destructive ? colors.error : colors.onSurface;
    final secondaryColor = destructive
        ? colors.error.withValues(alpha: 0.8)
        : colors.onSurfaceVariant;

    Widget content = InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kSettingsTileMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: primaryColor,
                    size: 20,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title.toLowerCase(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!.toLowerCase(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                IconTheme(
                  data: IconThemeData(
                    color: secondaryColor,
                    size: 20,
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!enabled) {
      content = Opacity(
        opacity: 0.4,
        child: IgnorePointer(
          child: content,
        ),
      );
    }

    return content;
  }
}
