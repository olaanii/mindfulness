/// Firestore `meditations/{id}` — see AGENTS.md.
final class Meditation {
  const Meditation({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.category,
    required this.audioUrl,
  });

  factory Meditation.fromDoc(String id, Map<String, dynamic> data) {
    return Meditation(
      id: id,
      title: data['title'] as String? ?? 'Untitled',
      durationSec: (data['duration'] as num?)?.toInt() ?? 0,
      category: (data['category'] as String? ?? 'general').trim().isEmpty
          ? 'general'
          : (data['category'] as String).trim(),
      audioUrl: data['audioUrl'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final int durationSec;
  final String category;
  final String audioUrl;

  String get durationLabel {
    if (durationSec <= 0) return '—';
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    if (m > 0 && s == 0) return '$m min';
    if (m > 0) return '$m min $s s';
    return '$s s';
  }
}
