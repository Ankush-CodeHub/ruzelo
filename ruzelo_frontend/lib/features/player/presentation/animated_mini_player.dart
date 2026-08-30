import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../application/player_notifier.dart';
import 'signature_player_screen.dart';

/// Glassmorphic Mini-Player with full playback controls:
/// Previous, Play/Pause, Next, Favorite toggle, interactive progress scrubbing, and drag-to-expand.
class AnimatedMiniPlayer extends ConsumerStatefulWidget {
  const AnimatedMiniPlayer({super.key});

  @override
  ConsumerState<AnimatedMiniPlayer> createState() => _AnimatedMiniPlayerState();
}

class _AnimatedMiniPlayerState extends ConsumerState<AnimatedMiniPlayer> {
  bool _isFavorited = false;

  void _openFullPlayer(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const SignaturePlayerScreen(),
        transitionsBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    final track = playerState.currentTrack;

    if (track == null) return const SizedBox.shrink();

    final duration = playerState.duration;
    final position = playerState.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! < -8) {
            _openFullPlayer(context);
          }
        },
        child: Hero(
          tag: 'ruzelo_player_pill',
          child: Material(
            type: MaterialType.transparency,
            child: RuzeloGlassCard(
              borderRadius: 22,
              padding: EdgeInsets.zero,
              fillColor: AppColors.glassDarkFill,
              borderWidth: 1.2,
              onTap: () => _openFullPlayer(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Interactive Top Progress Bar & Scrubber
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null && duration.inMilliseconds > 0) {
                        final localX = details.localPosition.dx;
                        final width = box.size.width;
                        final tapProgress = (localX / width).clamp(0.0, 1.0);
                        final newPos = Duration(milliseconds: (duration.inMilliseconds * tapProgress).round());
                        playerNotifier.seek(newPos);
                      }
                    },
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ),

                  // Mini Player Controls Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Album Art with rounded corners
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
                        const SizedBox(width: 10),

                        // Track title & artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // 1. Favorite Action Button
                        IconButton(
                          iconSize: 20,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorited ? const Color(0xFFEC4899) : Colors.white60,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFavorited = !_isFavorited);
                          },
                        ),
                        const SizedBox(width: 4),

                        // 2. Previous Track Action Button
                        IconButton(
                          iconSize: 22,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            playerNotifier.previousTrack();
                          },
                        ),
                        const SizedBox(width: 4),

                        // 3. Play / Pause Action Button with glowing circle
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            playerNotifier.togglePlayPause();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // 4. Next Track Action Button
                        IconButton(
                          iconSize: 22,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            playerNotifier.nextTrack();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
