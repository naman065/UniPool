import 'package:flutter/material.dart';
import 'package:unipool/models/user_model.dart';
import 'package:unipool/theme/app_theme.dart';

class MemberProfileTile extends StatelessWidget {
  const MemberProfileTile({
    super.key,
    required this.user,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  final UserModel user;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: compact ? 22 : 26,
      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Text(
              _initials(user.displayName),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 15 : 17,
              ),
            )
          : null,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.ratingSummary,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailingBelow =
            trailing != null && constraints.maxWidth < 430;
        if (stackTrailingBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(child: details),
                ],
              ),
              const SizedBox(height: 12),
              trailing!,
            ],
          );
        }

        return Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(child: details),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        );
      },
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: content,
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'S';
    }
    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }
}
