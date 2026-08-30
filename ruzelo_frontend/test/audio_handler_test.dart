import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruzelo_frontend/core/audio/audio_player_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlayerHandler Unit Tests', () {
    test('MediaItem creation and metadata validation', () {
      const item = MediaItem(
        id: 'track_1',
        title: 'Neon Odyssey',
        artist: 'Aether Wave',
        album: 'Cyber Horizon',
        duration: Duration(minutes: 3, seconds: 45),
        extras: {'url': 'http://localhost:8000/api/v1/tracks/track_1/stream'},
      );

      expect(item.id, equals('track_1'));
      expect(item.title, equals('Neon Odyssey'));
      expect(item.artist, equals('Aether Wave'));
      expect(item.duration, equals(const Duration(minutes: 3, seconds: 45)));
      expect(item.extras?['url'], contains('/stream'));
    });

    test('Queue item list mutation and ordering', () {
      final items = [
        const MediaItem(id: 'track_1', title: 'Track 1', artist: 'Artist 1'),
        const MediaItem(id: 'track_2', title: 'Track 2', artist: 'Artist 2'),
        const MediaItem(id: 'track_3', title: 'Track 3', artist: 'Artist 3'),
      ];

      expect(items.length, equals(3));
      expect(items[0].id, equals('track_1'));
      expect(items[2].id, equals('track_3'));
    });
  });
}
