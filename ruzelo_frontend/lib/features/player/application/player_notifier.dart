import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../../../core/audio/audio_visualizer_controller.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/dynamic_theme_controller.dart';

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String streamUrl;
  final String coverArtUrl;
  final Duration duration;
  final String genre;
  final double bpm;
  final double energy;
  final String format;

  const TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.streamUrl,
    required this.coverArtUrl,
    required this.duration,
    this.genre = 'Bollywood',
    this.bpm = 110.0,
    this.energy = 0.8,
    this.format = 'aac',
  });

  factory TrackItem.fromJson(Map<String, dynamic> json) {
    final durSec = json['duration_seconds'] is int
        ? json['duration_seconds'] as int
        : (json['duration_seconds'] is double ? (json['duration_seconds'] as double).toInt() : 210);

    return TrackItem(
      id: json['id']?.toString() ?? 'track_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Unknown Song',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? 'Single',
      streamUrl: json['stream_url']?.toString() ?? 'http://127.0.0.1:8000/api/v1/streaming/track_in_1',
      coverArtUrl: json['cover_art_url']?.toString() ?? 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800',
      duration: Duration(seconds: durSec),
      genre: json['genre']?.toString() ?? 'Bollywood',
      bpm: (json['bpm'] as num?)?.toDouble() ?? 118.0,
      energy: (json['energy'] as num?)?.toDouble() ?? 0.85,
      format: json['format']?.toString() ?? 'aac',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'stream_url': streamUrl,
      'cover_art_url': coverArtUrl,
      'duration_seconds': duration.inSeconds,
      'genre': genre,
      'bpm': bpm,
      'energy': energy,
      'format': format,
    };
  }
}

class PlayerState {
  final TrackItem? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final bool isShuffle;
  final bool isRepeat;
  final double audioEnergy;
  final List<TrackItem> playlist;
  final int currentIndex;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.isShuffle = false,
    this.isRepeat = false,
    this.audioEnergy = 0.5,
    this.playlist = const [],
    this.currentIndex = 0,
  });

  PlayerState copyWith({
    TrackItem? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    bool? isShuffle,
    bool? isRepeat,
    double? audioEnergy,
    List<TrackItem>? playlist,
    int? currentIndex,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      audioEnergy: audioEnergy ?? this.audioEnergy,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  final bool enableAudioEngine;
  AudioPlayer? _audioPlayer;
  Timer? _simulatedEnergyTimer;
  Timer? _positionTimer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  PlayerNotifier(
    this._ref, {
    this.enableAudioEngine = true,
    AudioPlayer? player,
  }) : super(const PlayerState()) {
    if (enableAudioEngine) {
      try {
        _audioPlayer = player ?? AudioPlayer();
        _initAudioListeners();
      } catch (e) {
        debugPrint('AudioPlayer init error: $e');
      }
    }
    _startAudioEnergySimulation();
    _startPositionTracker();
    _fetchLiveInitialCatalog();
  }

  Future<void> _fetchLiveInitialCatalog() async {
    TrackItem? lastPlayed;
    try {
      final lastPlayedResp = await http
          .get(Uri.parse(ApiConfig.lastPlayed))
          .timeout(const Duration(seconds: 4));
      if (lastPlayedResp.statusCode == 200 &&
          lastPlayedResp.body.isNotEmpty &&
          lastPlayedResp.body != 'null') {
        final Map<String, dynamic> lastPlayedJson = jsonDecode(lastPlayedResp.body);
        if (lastPlayedJson.isNotEmpty) {
          lastPlayed = TrackItem.fromJson(lastPlayedJson);
        }
      }
    } catch (_) {}

    try {
      final resp = await http
          .get(Uri.parse('${ApiConfig.liveLatest}?limit=25'))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        final tracks = data.map((i) => TrackItem.fromJson(i as Map<String, dynamic>)).toList();
        final initialTrack = lastPlayed ?? (tracks.isNotEmpty ? tracks.first : null);
        final combinedPlaylist = lastPlayed != null
            ? [lastPlayed, ...tracks.where((t) => t.id != lastPlayed!.id)]
            : tracks;

        if (initialTrack != null && state.currentTrack == null) {
          state = state.copyWith(
            currentTrack: initialTrack,
            playlist: combinedPlaylist,
            duration: initialTrack.duration,
          );
        }
      }
    } catch (_) {}
  }

  void _initAudioListeners() {
    if (_audioPlayer == null) return;
    try {
      _playerStateSubscription = _audioPlayer!.playerStateStream.listen(
        (playerState) {
          final isPlaying = playerState.playing;
          final isBuffering = playerState.processingState == ProcessingState.buffering ||
              playerState.processingState == ProcessingState.loading;

          state = state.copyWith(
            isPlaying: isPlaying,
            isBuffering: isBuffering,
          );

          _ref.read(audioVisualizerControllerProvider.notifier).setActive(isPlaying);

          if (playerState.processingState == ProcessingState.completed) {
            nextTrack();
          }
        },
        onError: (_) {},
      );

      _positionSubscription = _audioPlayer!.positionStream.listen(
        (pos) {
          state = state.copyWith(position: pos);
        },
        onError: (_) {},
      );

      _durationSubscription = _audioPlayer!.durationStream.listen(
        (dur) {
          if (dur != null && dur != Duration.zero) {
            state = state.copyWith(duration: dur);
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _startPositionTracker() {
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPlaying && _audioPlayer == null) {
        final nextSec = state.position.inSeconds + 1;
        if (nextSec >= state.duration.inSeconds) {
          nextTrack();
        } else {
          state = state.copyWith(position: Duration(seconds: nextSec));
        }
      }
    });
  }

  void _startAudioEnergySimulation() {
    final rand = Random();
    _simulatedEnergyTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (state.isPlaying) {
        final base = state.currentTrack?.energy ?? 0.7;
        final fluctuation = (rand.nextDouble() - 0.5) * 0.35;
        state = state.copyWith(audioEnergy: (base + fluctuation).clamp(0.1, 1.0));
      } else {
        state = state.copyWith(audioEnergy: 0.05);
      }
    });
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    state = state.copyWith(isPlaying: true);
    _ref.read(audioVisualizerControllerProvider.notifier).setActive(true);

    if (_audioPlayer != null && state.currentTrack != null) {
      try {
        if (_audioPlayer!.audioSource == null) {
          await _audioPlayer!.setUrl(state.currentTrack!.streamUrl);
        }
        await _audioPlayer!.play();
      } catch (e) {
        debugPrint('Audio playback warning: $e');
      }
    }
  }

  Future<void> pause() async {
    state = state.copyWith(isPlaying: false);
    _ref.read(audioVisualizerControllerProvider.notifier).setActive(false);

    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.pause();
      } catch (_) {}
    }
  }

  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.seek(position);
      } catch (_) {}
    }
  }

  Future<void> selectTrack(TrackItem track) async {
    final index = state.playlist.indexWhere((t) => t.id == track.id);
    state = state.copyWith(
      currentTrack: track,
      currentIndex: index >= 0 ? index : 0,
      duration: track.duration,
      position: Duration.zero,
      isPlaying: true,
    );

    _ref.read(audioVisualizerControllerProvider.notifier).setActive(true);
    _ref.read(dynamicThemeControllerProvider.notifier).updateFromGenre(track.genre);

    // Persist last played track to backend so it reloads on app startup
    try {
      http.post(
        Uri.parse(ApiConfig.lastPlayed),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(track.toJson()),
      );
    } catch (_) {}

    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.setUrl(track.streamUrl);
        await _audioPlayer!.play();
      } catch (e) {
        debugPrint('Could not set stream URL (${track.streamUrl}): $e');
      }
    }

    // Resolve full 3-6 minute master audio in background
    _resolveFullSongInBackground(track);
  }

  Future<void> _resolveFullSongInBackground(TrackItem track) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.resolveFull}?title=${Uri.encodeComponent(track.title)}&artist=${Uri.encodeComponent(track.artist)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final fullUrl = data['stream_url'] as String?;
        final durSec = data['duration_seconds'] as int? ?? track.duration.inSeconds;
        if (fullUrl != null && fullUrl.isNotEmpty && state.currentTrack?.id == track.id) {
          final fullTrack = TrackItem(
            id: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
            streamUrl: fullUrl,
            coverArtUrl: (data['cover_art_url'] as String?) ?? track.coverArtUrl,
            duration: Duration(seconds: durSec),
            genre: track.genre,
            bpm: track.bpm,
            energy: track.energy,
            format: 'full_aac',
          );
          state = state.copyWith(currentTrack: fullTrack, duration: Duration(seconds: durSec));
          if (_audioPlayer != null && state.isPlaying) {
            final currentPos = state.position;
            await _audioPlayer!.setUrl(fullUrl);
            if (currentPos > Duration.zero) {
              await _audioPlayer!.seek(currentPos);
            }
            await _audioPlayer!.play();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> nextTrack() async {
    if (state.playlist.isEmpty) return;
    final nextIdx = (state.currentIndex + 1) % state.playlist.length;
    await selectTrack(state.playlist[nextIdx]);
  }

  Future<void> previousTrack() async {
    if (state.playlist.isEmpty) return;
    final prevIdx = (state.currentIndex - 1 + state.playlist.length) % state.playlist.length;
    await selectTrack(state.playlist[prevIdx]);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
    if (_audioPlayer != null) {
      try {
        _audioPlayer!.setShuffleModeEnabled(state.isShuffle);
      } catch (_) {}
    }
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
    if (_audioPlayer != null) {
      try {
        _audioPlayer!.setLoopMode(state.isRepeat ? LoopMode.one : LoopMode.off);
      } catch (_) {}
    }
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.setVolume(clamped);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _simulatedEnergyTimer?.cancel();
    if (_audioPlayer != null) {
      try {
        _audioPlayer!.dispose();
      } catch (_) {}
    }
    super.dispose();
  }
}

final playerNotifierProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
