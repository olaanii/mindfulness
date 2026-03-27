import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/meditations/domain/meditation.dart';

final meditationRepositoryProvider = Provider<MeditationRepository>(
  (ref) => MeditationRepository(),
);

final class MeditationRepository {
  MeditationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Meditation>> watchCatalog() {
    return _db.collection('meditations').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Meditation.fromDoc(d.id, d.data()))
          .toList(growable: false);
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return list;
    });
  }

  Future<Meditation?> getById(String id) async {
    final doc = await _db.collection('meditations').doc(id).get();
    if (!doc.exists) return null;
    return Meditation.fromDoc(doc.id, doc.data()!);
  }
}
