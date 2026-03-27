import 'package:flutter_riverpod/flutter_riverpod.dart';

/// After a focus session is written, the timer publishes the new Firestore doc id;
/// [TimerScreen] listens and opens the mood check-in sheet with that [sessionId].
final class PendingFocusSessionMood extends Notifier<String?> {
  @override
  String? build() => null;

  void offer(String sessionDocId) => state = sessionDocId;

  void clear() => state = null;
}

final pendingFocusSessionMoodProvider =
    NotifierProvider<PendingFocusSessionMood, String?>(
      PendingFocusSessionMood.new,
    );
