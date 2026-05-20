import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/meditations/domain/meditation.dart';
import 'package:mindfulness/features/meditations/providers/meditation_providers.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

class MeditationsScreen extends ConsumerWidget {
  const MeditationsScreen({super.key});

  List<String> _categories(List<Meditation> items) {
    final s = items.map((e) => e.category).toSet();
    final list = s.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<Meditation> _filtered(List<Meditation> items, String? category) {
    if (category == null) return items;
    return items.where((e) => e.category == category).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meditationsCatalogProvider);
    final selected = ref.watch(meditationCategoryFilterProvider);
    final user = ref.read(authServiceProvider).currentUser;

    return Scaffold(
      body: MindfulBackground(
        bottomPadding: 124,
        child: async.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No meditations yet. Add documents to the meditations collection (see firebase/seed/meditations.json).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            final cats = _categories(items);
            final rows = _filtered(items, selected);
            final featured = rows.isNotEmpty ? rows.first : items.first;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                TopBlurBar(
                  title: 'Mindfulness',
                  trailing: UserAvatarBadge(
                    email: user?.email,
                    onTap: () => context.push('/account'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Meditations',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your inner peace.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      MindfulPill(
                        label: 'All',
                        selected: selected == null,
                        onTap: () => ref
                            .read(meditationCategoryFilterProvider.notifier)
                            .setFilter(null),
                      ),
                      const SizedBox(width: 10),
                      for (final c in cats) ...[
                        MindfulPill(
                          label: c,
                          selected: selected == c,
                          onTap: () => ref
                              .read(meditationCategoryFilterProvider.notifier)
                              .setFilter(c),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _FeaturedMeditationCard(
                  meditation: featured,
                  onTap: () => context.push('/meditation/${featured.id}'),
                ),
                const SizedBox(height: 18),
                for (final meditation in rows) ...[
                  _MeditationListCard(
                    meditation: meditation,
                    onTap: () => context.push('/meditation/${meditation.id}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load meditations.\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedMeditationCard extends StatelessWidget {
  const _FeaturedMeditationCard({
    required this.meditation,
    required this.onTap,
  });

  final Meditation meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        height: 272,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accentMint.withValues(alpha: 0.6),
              AppColors.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -12,
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              left: -28,
              top: 20,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryYellow.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.surface.withValues(alpha: 0.72),
                      AppColors.surface.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Text(
                      'Featured',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    meditation.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meditation.durationLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        meditation.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeditationListCard extends StatelessWidget {
  const _MeditationListCard({required this.meditation, required this.onTap});

  final Meditation meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryYellow.withValues(alpha: 0.22),
                  AppColors.accentCoral.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.textBrand,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meditation.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meditation.durationLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  meditation.category,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
              boxShadow: AppColors.elevatedGlow(context),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.textBrand,
            ),
          ),
        ],
      ),
    );
  }
}
