import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/ruzelo_atmosphere_background.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../../player/application/player_notifier.dart';
import '../../playlist/domain/mood_playlists_data.dart';
import '../../playlist/presentation/playlist_screen.dart';

/// Clean Spotify "Your Library" screen backed by live music streaming networks.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filterChips = ['Playlists', 'Liked Songs', 'Artists'];
  List<MoodPlaylist> _livePlaylists = [];
  List<TrackItem> _recentTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLibraryContent();
  }

  Future<void> _fetchLibraryContent() async {
    setState(() => _isLoading = true);
    try {
      final pFuture = http.get(Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-playlists')).timeout(const Duration(seconds: 8));
      final tFuture = http.get(Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-latest?limit=10')).timeout(const Duration(seconds: 8));

      final results = await Future.wait([pFuture, tFuture]);
      final pResp = results[0];
      final tResp = results[1];

      if (pResp.statusCode == 200) {
        final List<dynamic> pData = jsonDecode(pResp.body);
        final playlists = pData.map((i) => MoodPlaylist.fromJson(i as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() => _livePlaylists = playlists);
        }
      }

      if (tResp.statusCode == 200) {
        final List<dynamic> tData = jsonDecode(tResp.body);
        final tracks = tData.map((i) => TrackItem.fromJson(i as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() => _recentTracks = tracks);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RuzeloAtmosphereBackground(
        blurAmount: 20.0,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Library Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                ),
                                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Your Library', style: AppTypography.heroDisplay.copyWith(fontSize: 26)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips Row
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterChips.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isSelected = _selectedFilterIndex == idx;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedFilterIndex = idx);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  _filterChips[idx],
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Pinned Liked Songs Card
                      RuzeloGlassCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(14),
                        fillColor: AppColors.glassFill,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistScreen(
                                title: 'Liked Songs',
                                description: 'Your favorite tracks in one place.',
                                tracks: _recentTracks,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4C1D95), Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Liked Songs', style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('Playlist • ${_recentTracks.length} songs', style: AppTypography.bodySmall.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.push_pin_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      Text('Playlists & Saved', style: AppTypography.titleSmall),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Saved Curated Playlists List
              if (_livePlaylists.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final playlist = _livePlaylists[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                        child: RuzeloGlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          fillColor: AppColors.glassFill,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistScreen(
                                  title: playlist.title,
                                  description: playlist.description,
                                  coverUrl: playlist.coverUrl,
                                  atmosphereTag: playlist.genreBadge,
                                  tracks: playlist.tracks,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  playlist.coverUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.white12,
                                    child: const Icon(Icons.queue_music_rounded, color: Colors.white54),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(playlist.title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                                    Text('Playlist • ${playlist.genreBadge}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _livePlaylists.length,
                  ),
                ),

              // Recently Played Header & List
              if (_recentTracks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Text('Recently Played', style: AppTypography.titleSmall),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _recentTracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                        child: RuzeloGlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          fillColor: AppColors.glassFill,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            playerNotifier.selectTrack(track);
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  track.coverArtUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.white12,
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(track.title, style: AppTypography.titleSmall.copyWith(fontSize: 14), maxLines: 1),
                                    Text('${track.artist} • ${track.album}', style: AppTypography.bodySmall.copyWith(fontSize: 11), maxLines: 1),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 28),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  playerNotifier.selectTrack(track);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _recentTracks.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
