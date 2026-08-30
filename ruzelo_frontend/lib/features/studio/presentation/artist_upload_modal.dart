import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/ruzelo_glass_card.dart';
import '../../player/application/player_notifier.dart';

/// Modal dialog simulating live Master Audio Ingestion & DSP Analysis in Ruzelo
class ArtistUploadModal extends StatefulWidget {
  const ArtistUploadModal({super.key});

  @override
  State<ArtistUploadModal> createState() => _ArtistUploadModalState();
}

class _ArtistUploadModalState extends State<ArtistUploadModal> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController(text: 'Raag Yaman Nocturne');
  final TextEditingController _artistController = TextEditingController(text: 'Arijit Singh');
  final TextEditingController _albumController = TextEditingController(text: 'Saffron Horizon 2026');
  String _selectedGenre = 'Bollywood Romance';

  bool _isIngesting = false;
  bool _isDone = false;
  double _ingestProgress = 0.0;
  Map<String, dynamic>? _dspMetrics;

  final List<String> _genres = [
    'Bollywood Romance',
    'Punjabi Pop & Bhangra',
    'Sufi & Qawwali Mystic',
    'South Indian Cinema',
    'Desi Indie & Lo-Fi',
    'Indian Classical & Sitar',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  void _startLiveDSPAnalysis(WidgetRef ref) async {
    setState(() {
      _isIngesting = true;
      _ingestProgress = 0.0;
      _isDone = false;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (mounted) {
        setState(() {
          _ingestProgress = i / 10.0;
        });
      }
    }

    final rand = Random();
    final bpm = [105.0, 110.0, 118.0, 124.0, 128.0][rand.nextInt(5)];
    final lufs = -14.0 + (rand.nextDouble() - 0.5) * 1.5;
    final energy = 0.70 + rand.nextDouble() * 0.25;

    final newTrack = TrackItem(
      id: 'track_in_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty ? 'Untitled Track' : _titleController.text.trim(),
      artist: _artistController.text.trim().isEmpty ? 'Independent Artist' : _artistController.text.trim(),
      album: _albumController.text.trim().isEmpty ? 'Ruzelo Singles' : _albumController.text.trim(),
      streamUrl: 'http://127.0.0.1:8000/api/v1/streaming/track_in_1',
      coverArtUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800',
      duration: const Duration(minutes: 3, seconds: 48),
      genre: _selectedGenre,
      bpm: bpm,
      energy: energy,
      format: 'flac',
    );

    if (mounted) {
      setState(() {
        _dspMetrics = {
          'isrc': 'IN-RZL-26-0${rand.nextInt(89999) + 10000}',
          'lufs': '${lufs.toStringAsFixed(1)} LUFS (EBU R128 Normalized)',
          'bpm': '$bpm BPM',
          'energy': '${(energy * 100).toInt()}%',
          'format': 'FLAC • 24-bit / 44.1kHz Lossless',
        };
        _isIngesting = false;
        _isDone = true;
      });

      // Instantly queue & play in PlayerNotifier
      ref.read(playerNotifierProvider.notifier).selectTrack(newTrack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                            ),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Artist Ingestion Gateway', style: AppTypography.titleMedium),
                            Text('Automated DSP Analysis & Release Radar', style: AppTypography.artistSubtitle.copyWith(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Form Fields
                Text('Song Title', style: AppTypography.badgeLabel.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                Text('Artist Name', style: AppTypography.badgeLabel.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _artistController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                Text('Indian Genre', style: AppTypography.badgeLabel.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGenre,
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: AppTypography.bodyMedium,
                      isExpanded: true,
                      items: _genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGenre = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Live DSP Progress / Results Card
                if (_isIngesting) ...[
                  RuzeloGlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Running DSP Audio Analysis...', style: AppTypography.titleSmall.copyWith(fontSize: 12)),
                            Text('${(_ingestProgress * 100).toInt()}%', style: AppTypography.badgeLabel.copyWith(color: const Color(0xFFF59E0B))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _ingestProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (_isDone && _dspMetrics != null) ...[
                  RuzeloGlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    fillColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            Text('Master Ingested & Published Live!', style: AppTypography.titleSmall.copyWith(color: const Color(0xFF10B981), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('ISRC: ${_dspMetrics!['isrc']}', style: AppTypography.timeStamp.copyWith(color: Colors.white70)),
                        Text('Loudness: ${_dspMetrics!['lufs']}', style: AppTypography.timeStamp.copyWith(color: Colors.white70)),
                        Text('Detected Tempo: ${_dspMetrics!['bpm']}', style: AppTypography.timeStamp.copyWith(color: Colors.white70)),
                        Text('Acoustic Energy: ${_dspMetrics!['energy']}', style: AppTypography.timeStamp.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Upload Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isIngesting ? null : () => _startLiveDSPAnalysis(ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: Text(
                      _isDone ? 'Upload Another Master Track' : 'Analyze & Publish Master (FLAC)',
                      style: AppTypography.buttonLabel.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
