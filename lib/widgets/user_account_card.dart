import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/dialogs/confirmation_dialog.dart';

/// M3 card shown at the top of Settings: sign-in prompt or user info + sync status.
class UserAccountCard extends ConsumerWidget {
  const UserAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (auth.isSignedIn) {
      return _SignedInCard(auth: auth, theme: theme, l10n: l10n);
    }
    return _SignedOutCard(auth: auth, theme: theme, l10n: l10n);
  }

  /// Format a DateTime into a relative time string.
  static String formatRelativeTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }
}

class _SignedOutCard extends ConsumerStatefulWidget {
  final AuthState auth;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _SignedOutCard({
    required this.auth,
    required this.theme,
    required this.l10n,
  });

  @override
  ConsumerState<_SignedOutCard> createState() => _SignedOutCardState();
}

class _SignedOutCardState extends ConsumerState<_SignedOutCard> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn(Future<void> Function() signIn) async {
    setState(() => _isSigningIn = true);
    await signIn();
    if (mounted) setState(() => _isSigningIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;
    final auth = ref.watch(authProvider);

    return Card.filled(
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.account_circle,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.signInToEnableSync,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.signInFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSigningIn
                  ? null
                  : () => _handleSignIn(
                      ref.read(authProvider.notifier).signInWithGoogle,
                    ),
              icon: _isSigningIn
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : const _GoogleIcon(),
              label: Text(l10n.signInWithGoogle),
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends ConsumerWidget {
  final AuthState auth;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _SignedInCard({
    required this.auth,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card.filled(
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.userName ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (auth.userEmail != null)
                    Text(
                      auth.userEmail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildSyncStatus(),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _confirmSignOut(context, ref),
              child: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (auth.userPhotoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(auth.userPhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        (auth.userName ?? '?').characters.first,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final IconData icon;
    final String text;
    final Color? color;

    if (auth.isSyncing) {
      icon = Icons.cloud_sync;
      text = l10n.syncing;
      color = theme.colorScheme.onSurfaceVariant;
    } else if (auth.errorMessage != null) {
      icon = Icons.cloud_off;
      text = l10n.syncError;
      color = theme.colorScheme.error;
    } else if (auth.lastSyncTime != null) {
      icon = Icons.cloud_done;
      text = l10n.lastSynced(
        UserAccountCard.formatRelativeTime(auth.lastSyncTime!, l10n),
      );
      color = theme.colorScheme.onSurfaceVariant;
    } else {
      icon = Icons.cloud_off;
      text = l10n.syncError;
      color = theme.colorScheme.onSurfaceVariant;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.signOutConfirmTitle,
      content: l10n.signOutConfirmMessage,
      confirmText: l10n.signOut,
      cancelText: l10n.cancel,
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

/// Google 官方 G Logo，使用 SVG 路徑繪製。
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}
