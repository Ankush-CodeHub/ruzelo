import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_visualizer_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/dynamic_theme_controller.dart';
import '../../../core/theme/ruzelo_atmosphere_background.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../application/player_notifier.dart';
import 'particle_burst_layer.dart';

/// Signature full-screen player with 3D parallax tilt, audio wave visualizer, rotating vinyl disc, and particle bursts
class SignaturePlayerScreen extends ConsumerStatefulWidget {
  const SignaturePlayerScreen({super.key});

  @override
  ConsumerState<SignaturePlayerScreen> createState() => _SignaturePlayerScreenState();
}

class _SignaturePlayerScreenState extends ConsumerState<SignaturePlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  final GlobalKey<ParticleBurstLayerState> _particleKey = GlobalKey<ParticleBurstLayerState>();
  bool _isFavorited = false;

  // Parallax & 3D tilt tracking
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );

    if (ref.read(playerNotifierProvider).isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final visualizer = ref.watch(audioVisualizerControllerProvider);
    final track = playerState.currentTrack;

    if (playerState.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!playerState.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    if (track == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No Track Selected')),
      );
    }

    final duration = playerState.duration;
    final position = playerState.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return ParticleBurstLayer(
      burstKey: _particleKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RuzeloAtmosphereBackground(
          blurAmount: 14.0,
          child: SafeArea(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _tiltX = (_tiltX - details.delta.dy * 0.003).clamp(-0.25, 0.25);
                  _tiltY = (_tiltY + details.delta.dx * 0.003).clamp(-0.25, 0.25);
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _tiltX = 0.0;
                  _tiltY = 0.0;
                });
              },
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                  ),
                                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PLAYING ON RUZELO',
                                  style: AppTypography.badgeLabel.copyWith(color: const Color(0xFF10B981), fontSize: 9),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  track.album,
                                  style: AppTypography.titleSmall.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.blur_on_rounded, color: AppColors.primaryNeon, size: 28),
                          onPressed: () => _showAtmosphereSelector(context),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 3D Parallax & Rotating Vinyl Artwork
                  Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_tiltX)
                        ..rotateY(_tiltY),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Audio-reactive outer aura
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 270 + (playerState.audioEnergy * 35),
                            height: 270 + (playerState.audioEnergy * 35),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withValues(alpha: 0.3 + playerState.audioEnergy * 0.4),
                                  blurRadius: 60 + (playerState.audioEnergy * 40),
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),

                          // Vinyl Record Base
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * pi,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D0E15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 36,
                                    offset: Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
                                    ),
                                  ),
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
                                    ),
                                  ),
                                  ClipOval(
                                    child: Image.network(
                                      track.coverArtUrl,
                                      width: 135,
                                      height: 135,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.background,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Live Audio Wave Visualizer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(visualizer.bands.length, (idx) {
                          final bandHeight = (visualizer.bands[idx] * 28.0).clamp(4.0, 30.0);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 80),
                            width: 3.5,
                            height: bandHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryNeon, AppColors.secondaryNeon],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Track Metadata & Format Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      track.title,
                                      style: AppTypography.heroDisplay.copyWith(fontSize: 24),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryNeon.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.secondaryNeon.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      track.format.toUpperCase(),
                                      style: AppTypography.badgeLabel.copyWith(
                                        fontSize: 9,
                                        color: AppColors.secondaryNeon,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artist,
                                style: AppTypography.artistSubtitle.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTapDown: (details) {
                            HapticFeedback.mediumImpact();
                            setState(() => _isFavorited = !_isFavorited);
                            _particleKey.currentState?.spawnBurst(
                              details.globalPosition,
                              colors: const [
                                AppColors.accentNeon,
                                AppColors.primaryNeon,
                                Colors.white,
                              ],
                              count: 32,
                            );
                          },
                          child: RuzeloGlassCard(
                            borderRadius: 30,
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorited ? AppColors.accentNeon : AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Scrub Bar with Haptic Feedback
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primaryNeon,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              final targetMs = (val * duration.inMilliseconds).toInt();
                              ref.read(playerNotifierProvider.notifier).seek(Duration(milliseconds: targetMs));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: AppTypography.timeStamp),
                              Text(_formatDuration(duration), style: AppTypography.timeStamp),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Glass Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: playerState.isShuffle ? AppColors.primaryNeon : AppColors.textTertiary,
                            size: 24,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerNotifierProvider.notifier).toggleShuffle();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerNotifierProvider.notifier).previousTrack();
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref.read(playerNotifierProvider.notifier).togglePlayPause();
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withValues(alpha: 0.5),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerNotifierProvider.notifier).nextTrack();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.repeat_rounded,
                            color: playerState.isRepeat ? AppColors.primaryNeon : AppColors.textTertiary,
                            size: 24,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerNotifierProvider.notifier).toggleRepeat();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAtmosphereSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RuzeloGlassCard(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          fillColor: const Color(0xF00D0F1A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atmosphere Presets', style: AppTypography.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Select ambient mesh shaders dynamically tuned to audio acoustic vectors.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AtmospherePalette.allPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, idx) {
                    final p = AtmospherePalette.allPresets[idx];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(dynamicThemeControllerProvider.notifier).setPalette(p);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [p.primary, p.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: AppTypography.badgeLabel.copyWith(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
