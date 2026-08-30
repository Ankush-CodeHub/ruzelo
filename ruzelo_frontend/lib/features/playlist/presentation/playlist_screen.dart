import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/ruzelo_atmosphere_background.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../../player/application/player_notifier.dart';

class PlaylistScreen extends ConsumerWidget {
  final String title;
  final String description;
  final String coverUrl;
  final String atmosphereTag;
  final List<TrackItem>? tracks;

  const PlaylistScreen({
    super.key,
    this.title = 'Spotify Mood Playlist',
    this.description = 'Curated full-length tracks for every moment and emotion.',
    this.coverUrl = 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800',
    this.atmosphereTag = 'Spotify Mood',
    this.tracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    final playlistTracks = tracks ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RuzeloAtmosphereBackground(
        blurAmount: 16.0,
        child: CustomScrollView(
          slivers: [
            // Collapsing Glass Playlist Header
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              backgroundColor: AppColors.background.withValues(alpha: 0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E1B4B),
                        child: const Icon(Icons.music_note, color: Colors.white30, size: 64),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.6),
                            AppColors.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metadata & Controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            atmosphereTag.toUpperCase(),
                            style: AppTypography.badgeLabel.copyWith(color: const Color(0xFF10B981), fontSize: 9),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${playlistTracks.length} Full Tracks • Made For You', style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: AppTypography.bodyMedium),
                    const SizedBox(height: 18),

                    // Play All & Shuffle Row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            if (playlistTracks.isNotEmpty) {
                              playerNotifier.selectTrack(playlistTracks.first);
                            }
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded, color: Color(0xFF10B981), size: 26),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            playerNotifier.toggleShuffle();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 26),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tracks', style: AppTypography.titleSmall),
                        Text('100% Full Length', style: AppTypography.bodySmall.copyWith(color: const Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Track List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = playlistTracks[index];
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
                          Text(
                            '${index + 1}'.padLeft(2, '0'),
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
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 46,
                                height: 46,
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
                                Text(track.artist, style: AppTypography.bodySmall, maxLines: 1),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            ),
                            child: Text('FULL SONG', style: AppTypography.badgeLabel.copyWith(fontSize: 8, color: const Color(0xFF10B981))),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: playlistTracks.length,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
}
