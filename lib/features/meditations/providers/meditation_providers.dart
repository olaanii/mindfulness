import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/meditations/data/meditation_repository.dart';
import 'package:mindfulness/features/meditations/domain/meditation.dart';

final meditationsCatalogProvider = StreamProvider<List<Meditation>>((ref) {
  return ref.watch(meditationRepositoryProvider).watchCatalog();
});

/// `null` = All categories.
final class MeditationCategoryFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? category) => state = category;
}

final meditationCategoryFilterProvider =
    NotifierProvider<MeditationCategoryFilter, String?>(
      MeditationCategoryFilter.new,
    );
