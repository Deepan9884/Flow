import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../features/tasks/models/task.dart';
import '../features/categories/models/category.dart';
import 'tilt_banner.dart';

/// Resolves a human-readable category label for a task's first category id.
/// Falls back to the raw id when the category no longer exists.
String? resolveCategoryLabel(List<Category> categories, Task task) {
  if (task.categoryIds.isEmpty) return null;
  final id = task.categoryIds.first;
  for (final c in categories) {
    if (c.uuid == id) return c.name;
  }
  return id;
}

class TaskBannerCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final String? categoryLabel;

  const TaskBannerCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDelete,
    this.categoryLabel,
  });

  @override
  State<TaskBannerCard> createState() => _TaskBannerCardState();
}

class _TaskBannerCardState extends State<TaskBannerCard> {
  static AudioPlayer? _sharedPlayer;
  static StreamSubscription<PlayerState>? _playerSub;
  bool _isPlaying = false;

  @override
  void dispose() {
    // If this specific card is playing when disposed, stop it.
    // No setState here: the state object is being torn down.
    if (_isPlaying && _sharedPlayer != null) {
      _sharedPlayer!.stop();
      _isPlaying = false;
    }
    super.dispose();
  }

  Future<void> _togglePlayPreview() async {
    final path = widget.task.soundPath;
    if (path == null || path.isEmpty) return;

    try {
      if (_sharedPlayer != null) {
        await _sharedPlayer!.stop();
      } else {
        _sharedPlayer = AudioPlayer();
      }

      if (_isPlaying) {
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      setState(() {
        _isPlaying = true;
      });

      await _playerSub?.cancel();
      _playerSub = _sharedPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });

      await _sharedPlayer!.setFilePath(path);
      await _sharedPlayer!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWallpaper = widget.task.wallpaperPath != null && widget.task.wallpaperPath!.isNotEmpty;
    final File? wallpaperFile = hasWallpaper ? File(widget.task.wallpaperPath!) : null;

    final double alignmentY = widget.task.wallpaperOffsetY.clamp(-1.0, 1.0);

    final Widget background = Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: !hasWallpaper
            ? const LinearGradient(
                colors: [Color(0xFF0058BE), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: hasWallpaper && wallpaperFile != null && wallpaperFile.existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                wallpaperFile,
                fit: BoxFit.cover,
                alignment: Alignment(0.0, alignmentY),
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback container in case the image fails to render
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0058BE), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );

    final Widget foreground = Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4.0,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.task.soundPath != null && widget.task.soundPath!.isNotEmpty)
                GestureDetector(
                  onTap: _togglePlayPreview,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_mute,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (widget.onToggle != null)
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.task.dueDate != null)
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      widget.task.dueDate!.toLocal().toString().substring(0, 16),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              if (widget.task.categoryIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Text(
                    (widget.categoryLabel ?? widget.task.categoryIds.first).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return TiltBanner(
      onTap: widget.onTap,
      background: background,
      foreground: foreground,
    );
  }
}
