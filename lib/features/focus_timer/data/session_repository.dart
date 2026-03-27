import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/models/session_log.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(),
);

final class SessionRepository {
  SessionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// [durationSeconds] total focus work completed (see AGENTS.md).
  /// Returns the new `sessions/{id}` document id (for mood `sessionId`).
  Future<String> logFocusSession({
    required String userId,
    required int durationSeconds,
  }) async {
    final doc = await _db.collection('sessions').add({
      'userId': userId,
      'type': 'focus',
      'duration': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> logMeditationSession({
    required String userId,
    required int durationSeconds,
    required String meditationId,
  }) async {
    final doc = await _db.collection('sessions').add({
      'userId': userId,
      'type': 'meditation',
      'duration': durationSeconds,
      'meditationId': meditationId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> logBreathingSession({
    required String userId,
    required int durationSeconds,
  }) async {
    final doc = await _db.collection('sessions').add({
      'userId': userId,
      'type': 'breathing',
      'duration': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<SessionLog>> watchSessions({
    required String userId,
    int limit = 500,
  }) {
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SessionLog.fromDoc(d.id, d.data()))
              .toList(),
        );
  }
}
