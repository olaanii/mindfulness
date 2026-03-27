import 'package:cloud_firestore/cloud_firestore.dart';

/// One document from `sessions/{id}` — see AGENTS.md.
final class SessionLog {
  const SessionLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationSeconds,
    required this.createdAt,
    this.meditationId,
  });

  factory SessionLog.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final created = ts is Timestamp
        ? ts.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: false);
    return SessionLog(
      id: id,
      userId: data['userId'] as String? ?? '',
      type: (data['type'] as String? ?? 'focus').trim().toLowerCase(),
      durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
      meditationId: data['meditationId'] as String?,
      createdAt: created,
    );
  }

  final String id;
  final String userId;
  /// `focus`, `meditation`, or `breathing`
  final String type;
  final int durationSeconds;
  final DateTime createdAt;
  final String? meditationId;
}
