import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';
import 'package:mindfulness/features/progress/presentation/progress_screen.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/warm_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.read(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMoodCheckInSheet(context, ref),
        icon: const Icon(Icons.mood_outlined),
        label: const Text('Log mood'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentSessionsProvider);
          ref.invalidate(recentMoodsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            WarmCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '—',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const ProgressOverviewContent(),
          ],
        ),
      ),
    );
  }
}
