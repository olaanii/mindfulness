import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/mood/domain/mood_entry.dart';

final moodRepositoryProvider = Provider<MoodRepository>(
  (ref) => MoodRepository(),
);

final class MoodRepository {
  MoodRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> addEntry({
    required String userId,
    int moodBefore = 3,
    int moodAfter = 3,
    String? sessionId,
    String? note,
  }) {
    final map = <String, dynamic>{
      'userId': userId,
      'moodBefore': moodBefore.clamp(1, 5),
      'moodAfter': moodAfter.clamp(1, 5),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (sessionId != null && sessionId.isNotEmpty) {
      map['sessionId'] = sessionId;
    }
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      map['note'] = trimmed;
    }
    return _db.collection('mood_entries').add(map);
  }

  Stream<List<MoodEntry>> watchRecent({
    required String userId,
    int limit = 56,
  }) {
    return _db
        .collection('mood_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MoodEntry.fromDoc(d.id, d.data())).toList(),
        );
  }
}
