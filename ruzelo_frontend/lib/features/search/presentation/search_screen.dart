import 'dart:async';
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

/// Clean Spotify-style search experience.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  bool _isLoading = false;
  List<TrackItem> _liveResults = [];

  final List<Map<String, dynamic>> _genreCategories = [
    {
      'title': 'Bollywood Romance',
      'query': 'Bollywood Love Hits',
      'colors': [Color(0xFFE11D48), Color(0xFFF43F5E)],
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Punjabi & Bhangra',
      'query': 'Diljit Dosanjh Punjabi Hits',
      'colors': [Color(0xFFF97316), Color(0xFFFB923C)],
      'icon': Icons.celebration_rounded,
    },
    {
      'title': 'Desi Hip-Hop',
      'query': 'DIVINE Seedhe Maut Hip Hop',
      'colors': [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      'icon': Icons.mic_external_on_rounded,
    },
    {
      'title': 'Global Top Hits',
      'query': 'Global Pop Hits 2026',
      'colors': [Color(0xFF2563EB), Color(0xFF3B82F6)],
      'icon': Icons.language_rounded,
    },
    {
      'title': 'South Cinema',
      'query': 'Anirudh Ravichander Hits',
      'colors': [Color(0xFFD97706), Color(0xFFF59E0B)],
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'title': 'Indie & Lo-Fi',
      'query': 'Prateek Kuhad Acoustic Lo-Fi',
      'colors': [Color(0xFF059669), Color(0xFF10B981)],
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Sufi Soul',
      'query': 'A.R. Rahman Sufi Qawwali',
      'colors': [Color(0xFF0D9488), Color(0xFF14B8A6)],
      'icon': Icons.spa_rounded,
    },
    {
      'title': 'EDM & Dance',
      'query': 'EDM Dance Party Hits',
      'colors': [Color(0xFFDB2777), Color(0xFFEC4899)],
      'icon': Icons.music_note_rounded,
    },
  ];

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
        _liveResults = [];
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchRealSongs(query.trim());
    });
  }

  Future<void> _fetchRealSongs(String query) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('http://127.0.0.1:8000/api/v1/tracks/live-search?q=${Uri.encodeComponent(query)}&limit=25');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tracks = data.map((item) => TrackItem.fromJson(item as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _liveResults = tracks;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    final displayedTracks = _liveResults;
    final bool hasSearch = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RuzeloAtmosphereBackground(
        blurAmount: 20.0,
        child: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              // Search Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search', style: AppTypography.heroDisplay.copyWith(fontSize: 28)),
                      const SizedBox(height: 14),

                      // Glass Search Input Bar
                      RuzeloGlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        fillColor: AppColors.glassFill,
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                style: AppTypography.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'What do you want to listen to?',
                                  hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 14, color: Colors.white38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              )
                            else if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Section
              if (!hasSearch) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Text('Browse all', style: AppTypography.titleSmall),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext ctx, int index) {
                        final cat = _genreCategories[index];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final query = cat['query'] as String;
                            _searchController.text = query;
                            _onSearchChanged(query);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: cat['colors'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (cat['colors'] as List<Color>)[0].withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(cat['icon'] as IconData, color: Colors.white, size: 22),
                                Text(
                                  cat['title'] as String,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _genreCategories.length,
                    ),
                  ),
                ),
              ],

              // Search Results Section
              if (hasSearch) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      'Top Results (${displayedTracks.length})',
                      style: AppTypography.titleSmall,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext ctx, int index) {
                      final track = displayedTracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
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
                    childCount: displayedTracks.length,
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
