import 'package:cloud_firestore/cloud_firestore.dart';

final class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.moodBefore,
    required this.moodAfter,
    this.note,
    required this.createdAt,
  });

  factory MoodEntry.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final created = ts is Timestamp
        ? ts.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: false);
    return MoodEntry(
      id: id,
      userId: data['userId'] as String? ?? '',
      sessionId: data['sessionId'] as String?,
      moodBefore: ((data['moodBefore'] as num?)?.toInt() ?? 3).clamp(1, 5),
      moodAfter: ((data['moodAfter'] as num?)?.toInt() ?? 3).clamp(1, 5),
      note: data['note'] as String?,
      createdAt: created,
    );
  }

  final String id;
  final String userId;
  final String? sessionId;
  /// 1 (low) — 5 (great)
  final int moodBefore;
  final int moodAfter;
  final String? note;
  final DateTime createdAt;
}
