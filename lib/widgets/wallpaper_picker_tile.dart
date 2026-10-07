import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_import_service.dart';

class WallpaperPickerTile extends StatelessWidget {
  final String? currentWallpaperPath;
  final double currentOffsetY;
  final ValueChanged<String?> onPicked;
  final ValueChanged<double> onOffsetChanged;
  final String? previewTitle;
  final String label;

  const WallpaperPickerTile({
    super.key,
    this.currentWallpaperPath,
    this.currentOffsetY = 0.0,
    required this.onPicked,
    required this.onOffsetChanged,
    this.previewTitle,
    this.label = 'Custom Banner Wallpaper',
  });

  Future<void> _pickWallpaper(BuildContext context) async {
    final String? savedPath = await MediaImportService.pickAndSaveImage();
    if (savedPath != null) {
      onPicked(savedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasWallpaper = currentWallpaperPath != null &&
        currentWallpaperPath!.isNotEmpty &&
        File(currentWallpaperPath!).existsSync();

    if (!hasWallpaper) {
      // Empty state: Upload placeholder tile
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickWallpaper(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058BE).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Color(0xFF0058BE),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap to pick background banner image',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final File file = File(currentWallpaperPath!);
    final double clampedOffsetY = currentOffsetY.clamp(-1.0, 1.0);

    // Selected state: Live Photo Overlay with Bottom Crop Toolbar
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upper Preview Area with Overlays
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Live Cropped Image
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                    alignment: Alignment(0.0, clampedOffsetY),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[850],
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.white54, size: 32),
                      ),
                    ),
                  ),

                  // 2. Subtle Vignette Gradient for readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Top Action Bar: Preview Badge + Change + Remove
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white24, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'BANNER PREVIEW',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Change Button
                        InkWell(
                          onTap: () => _pickWallpaper(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white24, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_outlined,
                                    size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Remove Button
                        InkWell(
                          onTap: () => onPicked(null),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white24, width: 0.8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Center / Bottom Mockup Task Title
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Text(
                      previewTitle != null && previewTitle!.trim().isNotEmpty
                          ? previewTitle!.trim()
                          : 'Task Banner Preview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 8,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Integrated Bottom Crop Toolbar Overlay
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFF0F172A),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Crop Label & Quick Position Presets
                  Row(
                    children: [
                      const Icon(
                        Icons.crop_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Vertical Crop Alignment',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      // Preset buttons: Top, Center, Bottom
                      _buildPresetChip('Top', -1.0, clampedOffsetY),
                      const SizedBox(width: 5),
                      _buildPresetChip('Center', 0.0, clampedOffsetY),
                      const SizedBox(width: 5),
                      _buildPresetChip('Bottom', 1.0, clampedOffsetY),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Row 2: Live Alignment Slider
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      activeTrackColor: const Color(0xFF0058BE),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF0058BE).withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: clampedOffsetY,
                      min: -1.0,
                      max: 1.0,
                      onChanged: onOffsetChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String title, double targetValue, double currentValue) {
    final bool isSelected = (currentValue - targetValue).abs() < 0.15;

    return GestureDetector(
      onTap: () => onOffsetChanged(targetValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0058BE)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0058BE)
                : Colors.white12,
            width: 0.8,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
