import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';
import 'package:mindfulness/features/progress/presentation/progress_screen.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.read(authServiceProvider).currentUser;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final fabBottomOffset = bottomInset + 96;
    final scrollBottomPadding = fabBottomOffset + 72;

    Future<void> refresh() async {
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(recentMoodsProvider);
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomOffset),
        child: FloatingActionButton.extended(
          onPressed: () => showMoodCheckInSheet(context, ref),
          icon: const Icon(Icons.mood_rounded),
          label: const Text('Log mood'),
        ),
      ),
      body: MindfulBackground(
        bottomPadding: scrollBottomPadding,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 12, 20, scrollBottomPadding),
            children: [
              TopBlurBar(
                title: 'Mindfulness',
                trailing: UserAvatarBadge(
                  email: user?.email,
                  onTap: () => context.push('/account'),
                ),
              ),
              const SizedBox(height: 28),
              const ProgressOverviewContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.read(authServiceProvider).currentUser;
    final streak =
        ref.watch(progressSnapshotProvider).asData?.value.streakDays ?? 0;
    final displayName = _displayName(user?.email);

    return Scaffold(
      body: MindfulBackground(
        bottomPadding: 32,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TopBlurBar(
              title: 'Mindfulness',
              leading: IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Back',
              ),
              trailing: UserAvatarBadge(email: user?.email),
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your account and preferences',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF7E7CF), Color(0xFFF1D0A0)],
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: AppColors.elevatedGlow(context),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          displayName.isNotEmpty ? displayName[0] : 'M',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppColors.textBrand,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 4,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.textBrand,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? '—',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _AccountBadge(
                        icon: Icons.local_fire_department_rounded,
                        label: '${streak <= 0 ? 0 : streak} Day Streak',
                        background: const Color(0x1A9A442D),
                        foreground: const Color(0xFF9A442D),
                        border: const Color(0x339A442D),
                      ),
                      const _AccountBadge(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Premium',
                        background: Color(0x1A006876),
                        foreground: Color(0xFF006876),
                        border: Color(0x33006876),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _AccountListRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Subscription\nPlan',
                    trailingLabel: 'Premium',
                  ),
                  _AccountDivider(),
                  _AccountListRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification Settings',
                  ),
                  _AccountDivider(),
                  _AccountListRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy & Security',
                  ),
                  _AccountDivider(),
                  _AccountListRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.surfaceMuted,
                foregroundColor: const Color(0xFFBA1A1A),
                elevation: 0,
              ),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Signed in with email/password'),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayName(String? email) {
  if (email == null || email.trim().isEmpty) return 'Mindful user';
  final handle = email.split('@').first.trim();
  if (handle.isEmpty) return 'Mindful user';
  return handle[0].toUpperCase() + handle.substring(1);
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountListRow extends StatelessWidget {
  const _AccountListRow({
    required this.icon,
    required this.label,
    this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textBrand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailingLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x14FC9174),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailingLabel!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF9A442D),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: AppColors.outlineMuted.withValues(alpha: 0.2),
    );
  }
}
