import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/meditations/domain/meditation.dart';
import 'package:mindfulness/features/meditations/providers/meditation_providers.dart';
import 'package:mindfulness/widgets/warm_card.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Meditations')),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No meditations yet. Add documents to the meditations '
                  'collection (see firebase/seed/meditations.json).',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selected == null,
                      onSelected: (_) => ref
                          .read(meditationCategoryFilterProvider.notifier)
                          .setFilter(null),
                    ),
                    const SizedBox(width: 8),
                    for (final c in cats) ...[
                      FilterChip(
                        label: Text(c),
                        selected: selected == c,
                        onSelected: (_) => ref
                            .read(meditationCategoryFilterProvider.notifier)
                            .setFilter(c),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = rows[i];
                    return WarmCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onTap: () => context.push('/meditation/${m.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.spa_outlined),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${m.durationLabel} · ${m.category}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.accentCoral,
                            size: 36,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
    );
  }
}
