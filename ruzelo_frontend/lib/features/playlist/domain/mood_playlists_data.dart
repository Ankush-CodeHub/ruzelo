import '../../player/application/player_notifier.dart';

class MoodPlaylist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String genreBadge;
  final String moodBadge;
  final int trackCount;
  final List<TrackItem> tracks;

  const MoodPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.genreBadge,
    required this.moodBadge,
    this.trackCount = 0,
    required this.tracks,
  });

  factory MoodPlaylist.fromJson(Map<String, dynamic> json) {
    final rawTracks = (json['tracks'] as List<dynamic>?) ?? [];
    final trackList = rawTracks
        .map((t) => TrackItem.fromJson(t as Map<String, dynamic>))
        .toList();

    final badge = json['genre_badge']?.toString() ?? json['mood_badge']?.toString() ?? 'Curated';

    return MoodPlaylist(
      id: json['id']?.toString() ?? 'pl_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Featured Playlist',
      description: json['description']?.toString() ?? 'Curated live tracks for this vibe.',
      coverUrl: json['cover_url']?.toString() ?? 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800',
      genreBadge: badge,
      moodBadge: badge,
      trackCount: (json['track_count'] as num?)?.toInt() ?? trackList.length,
      tracks: trackList,
    );
  }
}
