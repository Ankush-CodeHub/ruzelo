import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Background audio handler coordinating just_audio with system media controls
class RuzeloAudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<MediaItem> _playlist = [];
  int _currentIndex = 0;

  AudioPlayer get player => _player;

  RuzeloAudioPlayerHandler() {
    _initAudioStreams();
  }

  void _initAudioStreams() {
    // Propagate player playback state to AudioService
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _currentIndex,
        ),
      );
    });

    // Auto-advance track on complete
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> setQueue(List<MediaItem> items, {int initialIndex = 0}) async {
    _playlist.clear();
    _playlist.addAll(items);
    queue.add(_playlist);
    _currentIndex = initialIndex.clamp(0, _playlist.isEmpty ? 0 : _playlist.length - 1);
    if (_playlist.isNotEmpty) {
      await _loadCurrentTrack();
    }
  }

  Future<void> _loadCurrentTrack() async {
    if (_playlist.isEmpty) return;
    final item = _playlist[_currentIndex];
    mediaItem.add(item);
    try {
      final uri = item.extras?['url'] ?? item.id;
      await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    } catch (e) {
      // Fallback or log error
    }
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await _loadCurrentTrack();
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _loadCurrentTrack();
      await play();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await _loadCurrentTrack();
      await play();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
