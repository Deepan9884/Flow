import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_import_service.dart';

class WallpaperPickerTile extends StatelessWidget {
  final String? currentWallpaperPath;
  final ValueChanged<String> onPicked;
  final String label;

  const WallpaperPickerTile({
    super.key,
    this.currentWallpaperPath,
    required this.onPicked,
    this.label = "Custom Wallpaper",
  });

  Future<void> _pickWallpaper(BuildContext context) async {
    final String? savedPath = await MediaImportService.pickAndSaveImage();
    if (savedPath != null) {
      onPicked(savedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWallpaper = currentWallpaperPath != null && currentWallpaperPath!.isNotEmpty;
    final File? file = hasWallpaper ? File(currentWallpaperPath!) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _pickWallpaper(context),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail preview container
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasWallpaper && file != null && file.existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded, color: Colors.grey, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasWallpaper ? "Tap to change image" : "Tap to pick background image",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
