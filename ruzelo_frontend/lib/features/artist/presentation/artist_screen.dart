import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/ruzelo_atmosphere_background.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../../player/application/player_notifier.dart';

class ArtistScreen extends ConsumerWidget {
  final String artistName;
  final String bannerUrl;
  final String bio;
  final int monthlyListeners;
  final List<TrackItem>? tracks;

  const ArtistScreen({
    super.key,
    this.artistName = 'Arijit Singh',
    this.bannerUrl = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200',
    this.bio = 'Iconic voice of contemporary Indian music.',
    this.monthlyListeners = 34200000,
    this.tracks,
  });

  String _formatListeners(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M Monthly Listeners';
    }
    return '${(count / 1000).toStringAsFixed(0)}K Monthly Listeners';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RuzeloAtmosphereBackground(
        blurAmount: 18.0,
        child: CustomScrollView(
          slivers: [
            // Sticky Collapsing Header with Artist Backdrop
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
                  artistName,
                  style: AppTypography.titleLarge.copyWith(fontSize: 20),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.5),
                            AppColors.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Artist Meta & Play All Header
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
                            color: AppColors.primaryNeon.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('VERIFIED ARTIST', style: AppTypography.badgeLabel.copyWith(color: AppColors.primaryNeon)),
                        ),
                        const SizedBox(width: 10),
                        Text(_formatListeners(monthlyListeners), style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: AppTypography.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),

                    // Follow & Play All Row
                    Row(
                      children: [
                        Expanded(
                          child: RuzeloGlassCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            fillColor: AppColors.glassFill,
                            onTap: () {
                              HapticFeedback.selectionClick();
                            },
                            child: Center(
                              child: Text('FOLLOWING', style: AppTypography.badgeLabel),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        if ((tracks ?? const []).isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              playerNotifier.selectTrack((tracks ?? const []).first);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryNeon.withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('Popular Releases', style: AppTypography.titleSmall),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Top Tracks List with Dismissible Swipe Gestures
            if ((tracks ?? const []).isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = (tracks ?? const [])[index];
                  return Dismissible(
                    key: Key('artist_track_${track.id}_$index'),
                    background: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      color: AppColors.primaryNeon.withValues(alpha: 0.3),
                      child: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      color: AppColors.accentNeon.withValues(alpha: 0.3),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      HapticFeedback.lightImpact();
                    },
                    child: Padding(
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
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(track.title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                                  Text('${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')} • ${track.genre}', style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: 4,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
