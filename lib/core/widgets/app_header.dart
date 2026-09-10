import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onLogout;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF32107A), Color(0xFF09153F)]
              : const [Color(0xFFE9E4FF), Color(0xFFDCE8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logoblanc.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFFC8D0FF)
                          : const Color(0xFF3F4D85),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).state = isDark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              },
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                foregroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF172554),
              ),
              icon: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            if (onLogout != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Log out',
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
