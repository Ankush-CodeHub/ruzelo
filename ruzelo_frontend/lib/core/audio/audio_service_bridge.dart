import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_player_handler.dart';

/// Global reference to the initialized AudioHandler
late final RuzeloAudioPlayerHandler globalAudioHandler;

/// High-level bridge facilitating UI-to-audio-engine synchronization
class AudioServiceBridge {
  final RuzeloAudioPlayerHandler _handler;

  AudioServiceBridge(this._handler);

  Stream<PlaybackState> get playbackStateStream => _handler.playbackState;
  Stream<MediaItem?> get currentMediaItemStream => _handler.mediaItem;
  Stream<List<MediaItem>> get queueStream => _handler.queue;

  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;
  Stream<Duration> get bufferedPositionStream => _handler.player.bufferedPositionStream;
  Stream<double> get volumeStream => _handler.player.volumeStream;

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  Future<void> setVolume(double volume) => _handler.player.setVolume(volume);

  Future<void> playTrack({
    required String id,
    required String title,
    required String artist,
    required String streamUrl,
    String? album,
    String? artUri,
    Duration? duration,
    Map<String, dynamic>? extras,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album ?? 'Single',
      artUri: artUri != null ? Uri.parse(artUri) : null,
      duration: duration,
      extras: {
        'url': streamUrl,
        ...?extras,
      },
    );

    await _handler.setQueue([item], initialIndex: 0);
    await _handler.play();
  }

  Future<void> loadPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    await _handler.setQueue(items, initialIndex: initialIndex);
  }
}

final audioServiceBridgeProvider = Provider<AudioServiceBridge>((ref) {
  return AudioServiceBridge(globalAudioHandler);
});
