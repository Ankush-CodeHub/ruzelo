import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/dynamic_theme_controller.dart';
import '../../../core/theme/ruzelo_atmosphere_background.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../../player/application/player_notifier.dart';
import '../../playlist/domain/mood_playlists_data.dart';
import '../../playlist/presentation/playlist_screen.dart';

/// 100% Real Live Music discovery feed with Integrated Header Search.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<TrackItem> _searchResults = [];

  List<TrackItem> _latestSongs = [];
  List<MoodPlaylist> _genrePlaylists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSearchResults(query.trim());
    });
  }

  Future<void> _fetchSearchResults(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-search?q=${Uri.encodeComponent(query)}&limit=25');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tracks = data.map((item) => TrackItem.fromJson(item as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _searchResults = tracks;
            _isSearching = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchLiveCatalog() async {
    setState(() => _isLoading = true);
    try {
      final latestFuture = http
          .get(Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-latest?limit=25'))
          .timeout(const Duration(seconds: 8));

      final playlistsFuture = http
          .get(Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-playlists'))
          .timeout(const Duration(seconds: 8));

      final results = await Future.wait([latestFuture, playlistsFuture]);
      final latestResp = results[0];
      final playlistsResp = results[1];

      if (latestResp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(latestResp.body);
        final fetched = data
            .map((item) => TrackItem.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() => _latestSongs = fetched);
        }
      }

      if (playlistsResp.statusCode == 200) {
        final List<dynamic> pData = jsonDecode(playlistsResp.body);
        final fetchedPlaylists = pData
            .map((item) => MoodPlaylist.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() => _genrePlaylists = fetchedPlaylists);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dynamicThemeControllerProvider);
    final playerState = ref.watch(playerNotifierProvider);
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    final spotlightTrack = playerState.currentTrack ?? (_latestSongs.isNotEmpty ? _latestSongs.first : null);
    final isLastPlayed = playerState.currentTrack != null;
    final bool hasSearchQuery = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RuzeloAtmosphereBackground(
        blurAmount: 20.0,
        child: CustomScrollView(
          slivers: [
            // Glass App Bar with Integrated Header Search
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.background.withValues(alpha: 0.85),
              elevation: 0,
              toolbarHeight: 70,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                        ),
                        child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ruzelo',
                    style: AppTypography.titleLarge.copyWith(
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Integrated Header Search Input
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.white60, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search songs, artists...',
                                hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 12, color: Colors.white38),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_isSearching)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                            )
                          else if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  onPressed: _fetchLiveCatalog,
                ),
                const SizedBox(width: 4),
              ],
            ),

            // When searching: Display Live Search Results
            if (hasSearchQuery) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search Results (${_searchResults.length})',
                        style: AppTypography.titleSmall,
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Text('Clear', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_searchResults.isEmpty && !_isSearching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text('No songs found matching your search', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext ctx, int index) {
                      final track = _searchResults[index];
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
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
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
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 30),
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
                    childCount: _searchResults.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],

            // When NOT searching: Display standard discovery feed
            if (!hasSearchQuery) ...[
              if (_isLoading && _latestSongs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.5),
                        SizedBox(height: 16),
                        Text('Fetching live real music...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Featured Hero Spotlight Track
                        if (spotlightTrack != null) ...[
                          Text(isLastPlayed ? 'Jump Back In' : 'Today’s Top Pick', style: AppTypography.titleSmall),
                          const SizedBox(height: 12),
                          RuzeloGlassCard(
                            borderRadius: 22,
                            padding: const EdgeInsets.all(16),
                            fillColor: AppColors.glassFill,
                            onTap: () {
                              playerNotifier.selectTrack(spotlightTrack);
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    spotlightTrack.coverArtUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isLastPlayed ? 'LAST PLAYED • RESUME' : '100% FULL SONG',
                                          style: AppTypography.badgeLabel.copyWith(
                                            color: const Color(0xFF10B981),
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        spotlightTrack.title,
                                        style: AppTypography.titleMedium.copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        spotlightTrack.artist,
                                        style: AppTypography.artistSubtitle.copyWith(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    playerState.isPlaying && playerState.currentTrack?.id == spotlightTrack.id
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Playlists Section (Genre & Mood Curation)
                        if (_genrePlaylists.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Playlists', style: AppTypography.titleSmall),
                              Text('Curated for You', style: AppTypography.bodySmall.copyWith(color: const Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 195,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _genrePlaylists.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, idx) {
                                final playlist = _genrePlaylists[idx];
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
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
                                  child: Container(
                                    width: 152,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: AppColors.glassFill,
                                      border: Border.all(color: AppColors.glassBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                          child: Image.network(
                                            playlist.coverUrl,
                                            height: 110,
                                            width: 152,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 110,
                                              width: 152,
                                              color: const Color(0xFF1E1B4B),
                                              child: const Icon(Icons.queue_music_rounded, color: Colors.white54),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                playlist.title,
                                                style: AppTypography.titleSmall.copyWith(fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  playlist.genreBadge.toUpperCase(),
                                                  style: AppTypography.bodySmall.copyWith(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF10B981),
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Latest Songs Section (Real Live Releases)
                        if (_latestSongs.isNotEmpty) ...[
                          Row(
                            children: [
                              Text('Latest Songs', style: AppTypography.titleSmall),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FRESH RELEASES',
                                  style: AppTypography.badgeLabel.copyWith(
                                    color: const Color(0xFFF59E0B),
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _latestSongs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final track = _latestSongs[idx];
                              return RuzeloGlassCard(
                                borderRadius: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                fillColor: AppColors.glassFill,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  playerNotifier.selectTrack(track);
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '${idx + 1}'.padLeft(2, '0'),
                                      style: AppTypography.timeStamp.copyWith(
                                        color: AppColors.textTertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        track.coverArtUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
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
                                          Text(
                                            track.title,
                                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${track.artist} • ${track.album}',
                                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 30),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        playerNotifier.selectTrack(track);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
