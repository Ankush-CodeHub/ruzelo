import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruzelo_frontend/features/player/application/player_notifier.dart';

final testPlayerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref, enableAudioEngine: false);
});

void main() {
  group('PlayerNotifier Unit Tests', () {
    late ProviderContainer container;

    const testTrack = TrackItem(
      id: 'live_1635014240',
      title: 'Kesariya',
      artist: 'Arijit Singh',
      album: 'Brahmastra',
      streamUrl: 'http://127.0.0.1:8000/api/v1/streaming/proxy?url=test',
      coverArtUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800',
      duration: Duration(minutes: 4, seconds: 28),
      genre: 'Bollywood',
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('selectTrack updates current track, duration, and starts playback', () async {
      final notifier = container.read(testPlayerNotifierProvider.notifier);

      await notifier.selectTrack(testTrack);
      final state = container.read(testPlayerNotifierProvider);

      expect(state.currentTrack!.id, equals(testTrack.id));
      expect(state.currentTrack!.title, equals('Kesariya'));
      expect(state.currentTrack!.artist, equals('Arijit Singh'));
      expect(state.duration, equals(testTrack.duration));
      expect(state.position, equals(Duration.zero));
      expect(state.isPlaying, isTrue);
    });

    test('togglePlayPause transitions isPlaying state correctly', () async {
      final notifier = container.read(testPlayerNotifierProvider.notifier);

      await notifier.selectTrack(testTrack);
      expect(container.read(testPlayerNotifierProvider).isPlaying, isTrue);

      await notifier.togglePlayPause();
      expect(container.read(testPlayerNotifierProvider).isPlaying, isFalse);

      await notifier.togglePlayPause();
      expect(container.read(testPlayerNotifierProvider).isPlaying, isTrue);
    });

    test('seek updates track position within bounds', () async {
      final notifier = container.read(testPlayerNotifierProvider.notifier);
      const seekTarget = Duration(minutes: 1, seconds: 30);

      await notifier.seek(seekTarget);
      expect(container.read(testPlayerNotifierProvider).position, equals(seekTarget));
    });

    test('toggleShuffle and toggleRepeat toggle state flags', () {
      final notifier = container.read(testPlayerNotifierProvider.notifier);

      notifier.toggleShuffle();
      expect(container.read(testPlayerNotifierProvider).isShuffle, isTrue);

      notifier.toggleRepeat();
      expect(container.read(testPlayerNotifierProvider).isRepeat, isTrue);
    });

    test('setVolume clamps between 0.0 and 1.0', () async {
      final notifier = container.read(testPlayerNotifierProvider.notifier);

      await notifier.setVolume(0.65);
      expect(container.read(testPlayerNotifierProvider).volume, equals(0.65));

      await notifier.setVolume(1.5);
      expect(container.read(testPlayerNotifierProvider).volume, equals(1.0));

      await notifier.setVolume(-0.2);
      expect(container.read(testPlayerNotifierProvider).volume, equals(0.0));
    });
  });
}
